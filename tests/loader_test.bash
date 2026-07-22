#!/usr/bin/env bash

test_loader_preserves_caller_state() {
    local script

    script='
        set -o nounset
        before_options=$-
        before_ifs=$IFS
        before_pwd=$PWD
        trap "printf trap-fired >/dev/null" USR1
        before_trap=$(trap -p USR1)
        alias modern_bash_probe="printf alias-fired"
        before_alias=$(alias modern_bash_probe)
        builtin source "$1/src/modern-bash.bash" || exit
        [[ $- == "$before_options" ]] || exit 10
        [[ $IFS == "$before_ifs" ]] || exit 11
        [[ $PWD == "$before_pwd" ]] || exit 12
        [[ $(trap -p USR1) == "$before_trap" ]] || exit 13
        [[ $(alias modern_bash_probe) == "$before_alias" ]] || exit 14
    '
    test::capture "${BASH}" -c "${script}" modern-bash-test "${PROJECT_ROOT}"
    test::assert_eq 0 "${TEST_STATUS}" || return
    test::assert_eq '' "${TEST_STDOUT}" || return
    test::assert_eq '' "${TEST_STDERR}"
}

test_loader_is_idempotent() {
    MODERN_BASH_OUTPUT_FD=1
    # shellcheck source=src/modern-bash.bash
    builtin source "${PROJECT_ROOT}/src/modern-bash.bash" || return
    test::assert_eq 1 "${MODERN_BASH_OUTPUT_FD}"
}

test_loader_fails_closed_when_a_module_is_missing() {
    local copied_root=${TEST_TMPDIR}/incomplete-runtime
    local script=''

    mkdir -p "${copied_root}" || return
    cp -R "${PROJECT_ROOT}/src" "${copied_root}/src" || return
    rm -f "${copied_root}/src/lib/theme.bash" || return
    script='
        status=0
        builtin source "$1/src/modern-bash.bash" || status=$?
        printf "status=%s loaded=%s" "$status" "${MODERN_BASH_LOADED:-0}"
    '
    test::capture "${BASH}" -c "${script}" modern-bash-test "${copied_root}"
    test::assert_eq 0 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDOUT}" 'status=1 loaded=0'
}

test_loader_fails_closed_when_a_module_is_truncated() {
    local copied_root=${TEST_TMPDIR}/truncated-runtime
    local partial_file=${TEST_TMPDIR}/capabilities.partial
    local script=''

    mkdir -p "${copied_root}" || return
    cp -R "${PROJECT_ROOT}/src" "${copied_root}/src" || return
    # Keep every API function and remove only the final completion marker. This
    # proves that function presence alone cannot make a partial module valid.
    command sed '$d' \
        "${copied_root}/src/lib/capabilities.bash" >"${partial_file}" || return
    command mv "${partial_file}" "${copied_root}/src/lib/capabilities.bash" || return
    script='
        status=0
        builtin source "$1/src/modern-bash.bash" || status=$?
        printf "status=%s loaded=%s marker=%s color_name=%s" \
            "$status" "${MODERN_BASH_LOADED:-0}" \
            "${MODERN_BASH_CAPABILITIES_LOAD_STATE[0]-}" \
            "$(declare -F modern_bash::capabilities::color_name)"
    '
    test::capture "${BASH}" -c "${script}" modern-bash-test "${copied_root}"
    test::assert_eq 0 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDOUT}" \
        'status=1 loaded=0 marker= color_name=modern_bash::capabilities::color_name'
}

test_loader_uses_the_source_builtin() {
    local script=''

    script='
        source() { return 0; }
        export -f source
        builtin source "$1/src/modern-bash.bash" || exit
        printf "loaded=%s api=%s" "$MODERN_BASH_LOADED" \
            "$(declare -F modern_bash::bootstrap::shutdown)"
    '
    test::capture "${BASH}" -c "${script}" modern-bash-test "${PROJECT_ROOT}"
    test::assert_eq 0 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDOUT}" 'loaded=1 api=modern_bash::bootstrap::shutdown'
}

test_cli_ignores_poisoned_internal_guards() {
    test::capture env \
        MODERN_BASH_LOADED=1 \
        MODERN_BASH_RUNTIME_LOAD_STATE=complete \
        MODERN_BASH_CAPABILITIES_LOADED=1 \
        MODERN_BASH_THEME_LOADED=1 \
        MODERN_BASH_OUTPUT_LOADED=1 \
        MODERN_BASH_CONFIG_LOADER_LOADED=1 \
        MODERN_BASH_PROMPT_LOADED=1 \
        MODERN_BASH_BOOTSTRAP_LOADED=1 \
        MODERN_BASH_DOCTOR_LOADED=1 \
        MODERN_BASH_DOCTOR_LOAD_STATE=complete \
        MODERN_BASH_INITIALIZED=1 \
        'BASH_FUNC_modern_bash::bootstrap::initialize%%=() { :; }' \
        'BASH_FUNC_modern_bash::doctor::run%%=() { :; }' \
        'BASH_FUNC_source%%=() { return 0; }' \
        "${BASH}" "${PROJECT_ROOT}/bin/modern-bash" --version
    test::assert_eq 0 "${TEST_STATUS}" || return
    test::assert_eq 'modern-bash 0.3.0' "${TEST_STDOUT}" || return
    test::assert_eq '' "${TEST_STDERR}"
}

test_cli_rejects_poisoned_functions_when_doctor_is_truncated() {
    local copied_root=${TEST_TMPDIR}/truncated-doctor-runtime

    mkdir -p "${copied_root}/bin" || return
    cp -R "${PROJECT_ROOT}/src" "${copied_root}/src" || return
    cp "${PROJECT_ROOT}/bin/modern-bash" "${copied_root}/bin/modern-bash" || return
    : >"${copied_root}/src/commands/doctor.bash"

    test::capture env \
        MODERN_BASH_DOCTOR_LOADED=1 \
        MODERN_BASH_DOCTOR_LOAD_STATE=complete \
        'BASH_FUNC_modern_bash::doctor::run%%=() { printf "POISONED RUN\n"; }' \
        'BASH_FUNC_modern_bash::doctor::usage%%=() { printf "POISONED USAGE\n"; }' \
        "${BASH}" "${copied_root}/bin/modern-bash" doctor --plain
    test::assert_eq 1 "${TEST_STATUS}" || return
    test::assert_eq '' "${TEST_STDOUT}" || return
    test::assert_contains "${TEST_STDERR}" 'failed to load the doctor command' || return
    test::assert_not_contains "${TEST_STDERR}" POISONED
}

test_loader_tears_down_an_active_runtime_before_switching_roots() {
    local first_root=${TEST_TMPDIR}/runtime-switch-a
    local second_root=${TEST_TMPDIR}/runtime-switch-b
    local script=''

    mkdir -p "${first_root}" "${second_root}" || return
    cp -R "${PROJECT_ROOT}/src" "${first_root}/src" || return
    cp -R "${PROJECT_ROOT}/src" "${second_root}/src" || return
    script='
        PS1="before prompt"
        PROMPT_COMMAND="legacy_status=\$?"
        MODERN_BASH_CONFIG_FILE=""
        MODERN_BASH_COLOR=never
        MODERN_BASH_UNICODE=never
        MODERN_BASH_PROMPT_GIT=0
        builtin source "$1/src/modern-bash.bash" || exit 10
        modern_bash::bootstrap::initialize || exit 11
        builtin source "$2/src/modern-bash.bash" || exit 12
        modern_bash::bootstrap::initialize || exit 13
        modern_bash::bootstrap::shutdown || exit 14
        printf "source=%s\nenabled=%s initialized=%s\nps1=%s\nhook=%s\n" \
            "$MODERN_BASH_SOURCE_DIR" "$MODERN_BASH_PROMPT_ENABLED" \
            "$MODERN_BASH_INITIALIZED" "$PS1" "$PROMPT_COMMAND"
    '

    test::capture "${BASH}" -c "${script}" modern-bash-test \
        "${first_root}" "${second_root}"
    test::assert_eq 0 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDOUT}" "source=${second_root}/src" || return
    test::assert_contains "${TEST_STDOUT}" 'enabled=0 initialized=0' || return
    test::assert_contains "${TEST_STDOUT}" 'ps1=before prompt' || return
    test::assert_contains "${TEST_STDOUT}" 'hook=legacy_status=$?' || return
    test::assert_eq '' "${TEST_STDERR}"
}

test_loader_refuses_a_runtime_switch_when_the_old_hook_changed() {
    local first_root=${TEST_TMPDIR}/runtime-refusal-a
    local second_root=${TEST_TMPDIR}/runtime-refusal-b
    local script=''

    mkdir -p "${first_root}" "${second_root}" || return
    cp -R "${PROJECT_ROOT}/src" "${first_root}/src" || return
    cp -R "${PROJECT_ROOT}/src" "${second_root}/src" || return
    script='
        PS1="before prompt"
        PROMPT_COMMAND="legacy_status=\$?"
        MODERN_BASH_CONFIG_FILE=""
        MODERN_BASH_COLOR=never
        MODERN_BASH_UNICODE=never
        MODERN_BASH_PROMPT_GIT=0
        builtin source "$1/src/modern-bash.bash" || exit 10
        modern_bash::bootstrap::initialize || exit 11
        PROMPT_COMMAND="installed later"
        status=0
        builtin source "$2/src/modern-bash.bash" || status=$?
        printf "status=%s\nsource=%s\nenabled=%s initialized=%s\nps1=%s\nhook=%s\nerror=%s\n" \
            "$status" "$MODERN_BASH_SOURCE_DIR" "$MODERN_BASH_PROMPT_ENABLED" \
            "$MODERN_BASH_INITIALIZED" "$PS1" "$PROMPT_COMMAND" \
            "$MODERN_BASH_RUNTIME_ERROR"
    '

    test::capture "${BASH}" -c "${script}" modern-bash-test \
        "${first_root}" "${second_root}"
    test::assert_eq 0 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDOUT}" 'status=1' || return
    test::assert_contains "${TEST_STDOUT}" "source=${first_root}/src" || return
    test::assert_contains "${TEST_STDOUT}" 'enabled=1 initialized=1' || return
    test::assert_contains "${TEST_STDOUT}" 'hook=installed later' || return
    test::assert_contains "${TEST_STDOUT}" 'PROMPT_COMMAND changed after Modern Bash was enabled' || return
    test::assert_eq '' "${TEST_STDERR}"
}

test::run 'the loader preserves caller shell state' test_loader_preserves_caller_state
test::run 'the loader is idempotent' test_loader_is_idempotent
test::run 'the loader fails closed when a module is missing' test_loader_fails_closed_when_a_module_is_missing
test::run 'the loader fails closed when a module is truncated' test_loader_fails_closed_when_a_module_is_truncated
test::run 'the loader selects the source builtin explicitly' test_loader_uses_the_source_builtin
test::run 'the CLI ignores poisoned internal guards' test_cli_ignores_poisoned_internal_guards
test::run 'the CLI rejects poisoned functions from a truncated doctor module' test_cli_rejects_poisoned_functions_when_doctor_is_truncated
test::run 'switching runtime roots tears down the active prompt first' test_loader_tears_down_an_active_runtime_before_switching_roots
test::run 'runtime switching fails safely when the old hook changed' test_loader_refuses_a_runtime_switch_when_the_old_hook_changed
