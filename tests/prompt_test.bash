#!/usr/bin/env bash

prompt_test::defaults() {
    MODERN_BASH_PROMPT_ENABLED=0
    MODERN_BASH_PROMPT_ORIGINAL_PS1_SET=0
    MODERN_BASH_PROMPT_ORIGINAL_PS1_WAS_SET=0
    MODERN_BASH_PROMPT_ORIGINAL_COMMAND_SET=0
    MODERN_BASH_PROMPT_COMMAND_WAS_ARRAY=0
    MODERN_BASH_PROMPT_ORIGINAL_COMMAND=''
    MODERN_BASH_PROMPT_ORIGINAL_COMMANDS=()
    MODERN_BASH_PROMPT_INSTALLED_COMMAND=''
    MODERN_BASH_PROMPT_INSTALLED_COMMANDS=()
    MODERN_BASH_PROMPT_ACTIVE_PS1=''
    MODERN_BASH_COLOR=never
    MODERN_BASH_UNICODE=never
    MODERN_BASH_PROMPT_GIT=1
    MODERN_BASH_PROMPT_STATUS=nonzero
    MODERN_BASH_PROMPT_MULTILINE=1
    PS1=original
    unset PROMPT_COMMAND
}

test_prompt_renders_status_cwd_and_branch() {
    prompt_test::defaults
    modern_bash::prompt::_git_branch() {
        printf 'main'
    }
    modern_bash::prompt::enable || return
    modern_bash::prompt::render 7 || return
    test::assert_eq '[7] ' "${MODERN_BASH_PROMPT_STATUS_SEGMENT}" || return
    test::assert_eq ' (main)' "${MODERN_BASH_PROMPT_GIT_SEGMENT}" || return
    test::assert_contains "${PS1}" '${MODERN_BASH_PROMPT_CWD}' || return
    test::assert_contains "${PS1}" '${MODERN_BASH_PROMPT_GIT_SEGMENT}' || return
    test::assert_not_contains "${PS1}" main || return
    test::assert_contains "${PS1}" '\n> '
}

test_prompt_hides_success_status_by_default() {
    prompt_test::defaults
    MODERN_BASH_PROMPT_GIT=0
    modern_bash::prompt::enable || return
    modern_bash::prompt::render 0 || return
    test::assert_eq '' "${MODERN_BASH_PROMPT_STATUS_SEGMENT}"
}

test_prompt_can_show_success_status() {
    prompt_test::defaults
    MODERN_BASH_PROMPT_GIT=0
    MODERN_BASH_PROMPT_STATUS=always
    modern_bash::prompt::enable || return
    modern_bash::prompt::render 0 || return
    test::assert_eq '[0] ' "${MODERN_BASH_PROMPT_STATUS_SEGMENT}"
}

test_prompt_rejects_injected_status_without_execution() {
    local sentinel=${TEST_TMPDIR}/prompt-status-injection-ran
    local hostile="probe[\$(touch\${IFS}${sentinel})]"
    local status=0

    prompt_test::defaults
    MODERN_BASH_PROMPT_GIT=0
    modern_bash::prompt::render "${hostile}" || status=$?
    test::assert_eq 2 "${status}" || return
    test::assert_contains "${MODERN_BASH_PROMPT_ERROR}" 'decimal exit status' || return
    test::assert_eq original "${PS1}" || return
    if [[ -e ${sentinel} ]]; then
        printf '    prompt status validation executed injected shell code\n' >&2
        return 1
    fi
}

test_prompt_preserves_legacy_hook_status() {
    prompt_test::defaults
    MODERN_BASH_PROMPT_GIT=0
    PROMPT_COMMAND='legacy_status=$?; legacy_count=$((${legacy_count:-0} + 1))'
    modern_bash::prompt::enable || return
    false
    eval "${PROMPT_COMMAND}"
    test::assert_eq 1 "${MODERN_BASH_PROMPT_LAST_STATUS}" || return
    test::assert_eq 1 "${legacy_status}" || return
    test::assert_eq 1 "${legacy_count}"
}

test_prompt_owns_ps1_after_legacy_hook() {
    prompt_test::defaults
    MODERN_BASH_PROMPT_GIT=0
    PROMPT_COMMAND='legacy_status=$?; PS1=legacy'
    modern_bash::prompt::enable || return
    false
    eval "${PROMPT_COMMAND}"
    test::assert_eq 1 "${legacy_status}" || return
    test::assert_contains "${PS1}" '${MODERN_BASH_PROMPT_CWD}' || return
    test::assert_not_contains "${PS1}" legacy
}

test_prompt_composes_with_trailing_semicolon() {
    prompt_test::defaults
    MODERN_BASH_PROMPT_GIT=0
    PROMPT_COMMAND='legacy_status=$?;'
    modern_bash::prompt::enable || return
    false
    eval "${PROMPT_COMMAND}"
    test::assert_eq 1 "${legacy_status}" || return
    test::assert_eq 1 "${MODERN_BASH_PROMPT_LAST_STATUS}"
}

test_prompt_composes_with_legacy_comment() {
    prompt_test::defaults
    MODERN_BASH_PROMPT_GIT=0
    PROMPT_COMMAND='# legacy prompt comment'
    modern_bash::prompt::enable || return
    PS1=legacy
    false
    eval "${PROMPT_COMMAND}"
    test::assert_contains "${PS1}" '${MODERN_BASH_PROMPT_CWD}' || return
    test::assert_eq 1 "${MODERN_BASH_PROMPT_LAST_STATUS}"
}

test_prompt_composes_with_command_array() {
    if ! modern_bash::prompt::_supports_prompt_command_array; then
        return 0
    fi

    prompt_test::defaults
    MODERN_BASH_PROMPT_GIT=0
    PROMPT_COMMAND=('legacy_status=$?' 'legacy_count=$((${legacy_count:-0} + 1))')
    modern_bash::prompt::enable || return
    test::assert_eq 4 "${#PROMPT_COMMAND[@]}" || return
    test::assert_eq modern_bash::prompt::capture_status "${PROMPT_COMMAND[0]}" || return
    test::assert_contains "${PROMPT_COMMAND[1]}" 'legacy_status=$?' || return
    test::assert_contains "${PROMPT_COMMAND[1]}" 'modern_bash::prompt::_restore_status' || return
    test::assert_eq modern_bash::prompt::render_captured "${PROMPT_COMMAND[3]}"
}

test_prompt_hook_does_not_trigger_err_traps_for_saved_status() {
    local err_count=0

    prompt_test::defaults
    MODERN_BASH_PROMPT_GIT=0
    PROMPT_COMMAND='legacy_status=$?'
    modern_bash::prompt::enable || return
    trap 'err_count=$((err_count + 1))' ERR
    if (exit 7); then
        printf '    impossible success while preparing prompt status\n' >&2
        return 1
    else
        eval "${PROMPT_COMMAND}"
    fi
    trap - ERR
    test::assert_eq 0 "${err_count}" || return
    test::assert_eq 7 "${legacy_status}" || return
    test::assert_eq 7 "${MODERN_BASH_PROMPT_LAST_STATUS}"
}

test_prompt_disable_restores_unset_scalar_state() {
    prompt_test::defaults
    unset PS1 PROMPT_COMMAND
    MODERN_BASH_PROMPT_GIT=0
    modern_bash::prompt::enable || return
    modern_bash::prompt::disable || return
    if [[ ${PS1+x} == x || ${PROMPT_COMMAND+x} == x ]]; then
        printf '    disable did not restore unset prompt variables\n' >&2
        return 1
    fi
    test::assert_eq 0 "${MODERN_BASH_PROMPT_ENABLED}"
}

test_prompt_disable_restores_scalar_values() {
    prompt_test::defaults
    PS1='before prompt'
    PROMPT_COMMAND='before_hook=$?'
    modern_bash::prompt::enable || return
    modern_bash::prompt::render 9 || return
    modern_bash::prompt::disable || return
    test::assert_eq 'before prompt' "${PS1}" || return
    test::assert_eq 'before_hook=$?' "${PROMPT_COMMAND}"
}

test_prompt_disable_restores_command_array() {
    prompt_test::defaults
    PROMPT_COMMAND=('first=$?' 'second=1')
    modern_bash::prompt::enable || return
    modern_bash::prompt::disable || return
    test::assert_eq 2 "${#PROMPT_COMMAND[@]}" || return
    test::assert_eq 'first=$?' "${PROMPT_COMMAND[0]}" || return
    test::assert_eq 'second=1' "${PROMPT_COMMAND[1]}"
}

test_prompt_disable_restores_sparse_command_array() {
    local prompt_hook=''

    prompt_test::defaults
    PROMPT_COMMAND=()
    PROMPT_COMMAND[2]='first_status=$?; first_count=$((${first_count:-0} + 1))'
    PROMPT_COMMAND[7]='second_count=$((${second_count:-0} + 1))'
    modern_bash::prompt::enable || return
    if modern_bash::prompt::_supports_prompt_command_array; then
        test::assert_eq 4 "${#PROMPT_COMMAND[@]}" || return
        false
        for prompt_hook in "${PROMPT_COMMAND[@]}"; do
            eval "${prompt_hook}"
        done
        test::assert_eq 1 "${first_status}" || return
        test::assert_eq 1 "${first_count}" || return
        test::assert_eq 1 "${second_count}" || return
    fi
    modern_bash::prompt::disable || return
    test::assert_eq '2 7' "${!PROMPT_COMMAND[*]}" || return
    test::assert_eq 'first_status=$?; first_count=$((${first_count:-0} + 1))' \
        "${PROMPT_COMMAND[2]}" || return
    test::assert_eq 'second_count=$((${second_count:-0} + 1))' "${PROMPT_COMMAND[7]}"
}

test_prompt_disable_preserves_replacement_ps1() {
    prompt_test::defaults
    MODERN_BASH_PROMPT_GIT=0
    modern_bash::prompt::enable || return
    PS1='installed later'
    modern_bash::prompt::disable || return
    test::assert_eq 'installed later' "${PS1}"
}

test_prompt_disable_refuses_changed_hook() {
    local status=0

    prompt_test::defaults
    MODERN_BASH_PROMPT_GIT=0
    modern_bash::prompt::enable || return
    PROMPT_COMMAND='replacement_hook=1'
    modern_bash::prompt::disable || status=$?
    test::assert_eq 1 "${status}" || return
    test::assert_eq 1 "${MODERN_BASH_PROMPT_ENABLED}" || return
    test::assert_contains "${MODERN_BASH_PROMPT_ERROR}" 'refusing to overwrite'
}

test_prompt_rejects_readonly_targets_before_mutation() {
    local script

    script='
        builtin source "$1/src/modern-bash.bash" || exit
        MODERN_BASH_COLOR=never
        MODERN_BASH_UNICODE=never
        MODERN_BASH_PROMPT_GIT=0
        MODERN_BASH_PROMPT_STATUS=nonzero
        MODERN_BASH_PROMPT_MULTILINE=1
        readonly PS1=locked
        PROMPT_COMMAND=original_hook
        status=0
        modern_bash::prompt::enable || status=$?
        printf "status=%s ps1=%s hook=%s error=%s" \
            "$status" "$PS1" "$PROMPT_COMMAND" "$MODERN_BASH_PROMPT_ERROR"
    '
    test::capture "${BASH}" -c "${script}" modern-bash-test "${PROJECT_ROOT}"
    test::assert_eq 0 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDOUT}" 'status=1 ps1=locked hook=original_hook' || return
    test::assert_contains "${TEST_STDOUT}" 'PS1 has unsupported'
}

test_prompt_rejects_readonly_command_hook_before_mutation() {
    local script

    script='
        builtin source "$1/src/modern-bash.bash" || exit
        MODERN_BASH_COLOR=never
        MODERN_BASH_UNICODE=never
        MODERN_BASH_PROMPT_GIT=0
        MODERN_BASH_PROMPT_STATUS=nonzero
        MODERN_BASH_PROMPT_MULTILINE=1
        PS1=original
        readonly PROMPT_COMMAND=locked_hook
        status=0
        modern_bash::prompt::enable || status=$?
        printf "status=%s ps1=%s hook=%s error=%s" \
            "$status" "$PS1" "$PROMPT_COMMAND" "$MODERN_BASH_PROMPT_ERROR"
    '
    test::capture "${BASH}" -c "${script}" modern-bash-test "${PROJECT_ROOT}"
    test::assert_eq 0 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDOUT}" 'status=1 ps1=original hook=locked_hook' || return
    test::assert_contains "${TEST_STDOUT}" 'PROMPT_COMMAND has unsupported'
}

test_prompt_rejects_case_transforming_ps1() {
    local script

    if ((BASH_VERSINFO[0] < 4)); then
        return 0
    fi
    script='
        builtin source "$1/src/modern-bash.bash" || exit
        MODERN_BASH_COLOR=never
        MODERN_BASH_UNICODE=never
        MODERN_BASH_PROMPT_GIT=0
        MODERN_BASH_PROMPT_STATUS=nonzero
        MODERN_BASH_PROMPT_MULTILINE=1
        declare -l PS1=ORIGINAL
        status=0
        modern_bash::prompt::enable || status=$?
        printf "status=%s ps1=%s error=%s" \
            "$status" "$PS1" "$MODERN_BASH_PROMPT_ERROR"
    '
    test::capture "${BASH}" -c "${script}" modern-bash-test "${PROJECT_ROOT}"
    test::assert_eq 0 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDOUT}" 'status=1 ps1=original' || return
    test::assert_contains "${TEST_STDOUT}" 'case-transform'
}

prompt_test::write_fake_git() {
    local fake_bin=$1

    mkdir -p "${fake_bin}" || return
    {
        printf '%s\n' '#!/usr/bin/env bash'
        printf '%s\n' 'printf "%s:%s\\n" "${GIT_OPTIONAL_LOCKS:-unset}" "$1" >>"${MODERN_BASH_FAKE_GIT_LOG}"'
        printf '%s\n' 'case ${MODERN_BASH_FAKE_GIT_MODE}:$1 in'
        printf '%s\n' '    branch:symbolic-ref) printf "main\\n"; exit 0 ;;'
        printf '%s\n' '    detached:symbolic-ref) exit 1 ;;'
        printf '%s\n' '    detached:rev-parse) printf "a1b2c3d\\n"; exit 0 ;;'
        printf '%s\n' '    outside:symbolic-ref) exit 128 ;;'
        printf '%s\n' '    *) exit 99 ;;'
        printf '%s\n' 'esac'
    } >"${fake_bin}/git"
    chmod +x "${fake_bin}/git"
}

test_prompt_git_probe_minimizes_processes() {
    local fake_bin=${TEST_TMPDIR}/fake-git-bin
    local line=''
    local count=0
    local branch=''

    prompt_test::write_fake_git "${fake_bin}" || return
    MODERN_BASH_FAKE_GIT_LOG=${TEST_TMPDIR}/fake-git.log
    export MODERN_BASH_FAKE_GIT_LOG
    PATH=${fake_bin}:/usr/bin:/bin

    MODERN_BASH_FAKE_GIT_MODE=branch
    export MODERN_BASH_FAKE_GIT_MODE
    branch=$(modern_bash::prompt::_git_branch) || return
    test::assert_eq main "${branch}" || return
    while IFS= read -r line; do count=$((count + 1)); done <"${MODERN_BASH_FAKE_GIT_LOG}"
    test::assert_eq 1 "${count}" || return

    : >"${MODERN_BASH_FAKE_GIT_LOG}"
    count=0
    MODERN_BASH_FAKE_GIT_MODE=detached
    branch=$(modern_bash::prompt::_git_branch) || return
    test::assert_eq '@a1b2c3d' "${branch}" || return
    while IFS= read -r line; do count=$((count + 1)); done <"${MODERN_BASH_FAKE_GIT_LOG}"
    test::assert_eq 2 "${count}" || return

    : >"${MODERN_BASH_FAKE_GIT_LOG}"
    count=0
    MODERN_BASH_FAKE_GIT_MODE=outside
    branch=$(modern_bash::prompt::_git_branch) || return
    test::assert_eq '' "${branch}" || return
    while IFS= read -r line; do
        count=$((count + 1))
        test::assert_contains "${line}" '0:' || return
    done <"${MODERN_BASH_FAKE_GIT_LOG}"
    test::assert_eq 1 "${count}"
}

test_prompt_has_pre_51_array_fallback() {
    prompt_test::defaults
    MODERN_BASH_PROMPT_GIT=0
    PROMPT_COMMAND=('legacy_status=$?' 'ignored_on_old_bash=1')
    modern_bash::prompt::_supports_prompt_command_array() {
        return 1
    }
    modern_bash::prompt::enable || return
    test::assert_contains "${PROMPT_COMMAND[0]}" modern_bash::prompt::capture_status || return
    test::assert_contains "${PROMPT_COMMAND[0]}" 'legacy_status=$?' || return
    test::assert_contains "${PROMPT_COMMAND[0]}" modern_bash::prompt::render_captured
}

test_prompt_rejects_associative_prompt_command() {
    local status=0

    if ((BASH_VERSINFO[0] < 4)); then
        return 0
    fi
    prompt_test::defaults
    MODERN_BASH_PROMPT_GIT=0
    declare -A PROMPT_COMMAND=([hook]='legacy_status=$?')
    modern_bash::prompt::enable || status=$?
    test::assert_eq 1 "${status}" || return
    test::assert_contains "${MODERN_BASH_PROMPT_ERROR}" 'associative PROMPT_COMMAND' || return
    test::assert_eq original "${PS1}"
}

test_prompt_wraps_ansi_for_readline() {
    prompt_test::defaults
    FORCE_COLOR=1
    unset MODERN_BASH_COLOR NO_COLOR
    MODERN_BASH_PROMPT_GIT=0
    modern_bash::prompt::enable || return
    test::assert_contains "${PS1}" '\[' || return
    test::assert_contains "${PS1}" '\]'
}

test_prompt_preserves_output_capability_snapshot() {
    local saved_fd
    local saved_level
    local saved_theme_info

    prompt_test::defaults
    FORCE_COLOR=2
    unset MODERN_BASH_COLOR NO_COLOR
    modern_bash::output::configure 1 || return
    saved_fd=${MODERN_BASH_CAP_FD}
    saved_level=${MODERN_BASH_CAP_COLOR_LEVEL}
    saved_theme_info=${MODERN_BASH_THEME_INFO}
    modern_bash::prompt::enable || return
    test::assert_eq "${saved_fd}" "${MODERN_BASH_CAP_FD}" || return
    test::assert_eq "${saved_level}" "${MODERN_BASH_CAP_COLOR_LEVEL}" || return
    test::assert_eq "${saved_theme_info}" "${MODERN_BASH_THEME_INFO}"
}

test_prompt_requires_promptvars_without_changing_it() {
    local status=0

    prompt_test::defaults
    shopt -u promptvars
    modern_bash::prompt::enable || status=$?
    test::assert_eq 1 "${status}" || return
    test::assert_contains "${MODERN_BASH_PROMPT_ERROR}" promptvars || return
    if shopt -q promptvars; then
        printf '    prompt enable unexpectedly changed promptvars\n' >&2
        return 1
    fi
}

test_prompt_sanitizes_control_characters() {
    local sanitized

    sanitized=$(modern_bash::prompt::_sanitize $'one\ntwo\033three\rfour\tfive\afinal')
    test::assert_eq 'one?two?three?four?five?final' "${sanitized}"
}

test_prompt_keeps_dynamic_data_out_of_ps1() {
    local hostile='$(touch${IFS}/tmp/modern-bash-prompt-injection)'

    prompt_test::defaults
    modern_bash::prompt::_git_branch() {
        printf '%s' '$(touch${IFS}/tmp/modern-bash-prompt-injection)'
    }
    PWD=${hostile}
    modern_bash::prompt::enable || return
    modern_bash::prompt::render 0 || return
    test::assert_contains "${MODERN_BASH_PROMPT_CWD}" '${IFS}' || return
    test::assert_contains "${MODERN_BASH_PROMPT_GIT_SEGMENT}" '${IFS}' || return
    test::assert_not_contains "${PS1}" 'touch' || return
    test::assert_not_contains "${PS1}" '$('
}

prompt_test::interactive_file() {
    "${BASH}" --noprofile --norc -i -s <"$1"
}

test_prompt_command_array_executes_with_status_and_one_err_trap() {
    local input_file=${TEST_TMPDIR}/prompt-array-input.bash

    if ! modern_bash::prompt::_supports_prompt_command_array; then
        return 0
    fi
    {
        printf 'builtin source %q\n' "${PROJECT_ROOT}/src/modern-bash.bash"
        printf '%s\n' \
            'MODERN_BASH_COLOR=never' \
            'MODERN_BASH_UNICODE=never' \
            'MODERN_BASH_PROMPT_GIT=0' \
            'MODERN_BASH_PROMPT_STATUS=never' \
            'MODERN_BASH_PROMPT_MULTILINE=0' \
            "PROMPT_COMMAND=('legacy_status=\$?' 'legacy_count=\$((\${legacy_count:-0} + 1))')" \
            'modern_bash::prompt::enable' \
            "trap 'err_count=\$((\${err_count:-0} + 1))' ERR" \
            'false' \
            'printf "RESULT legacy=%s saved=%s err=%s count=%s\\n" "$legacy_status" "$MODERN_BASH_PROMPT_LAST_STATUS" "${err_count:-0}" "$legacy_count"' \
            'exit'
    } >"${input_file}"

    test::capture prompt_test::interactive_file "${input_file}"
    test::assert_eq 0 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDOUT}" 'RESULT legacy=1 saved=1 err=1'
}

test_prompt_expansion_does_not_execute_dynamic_data() {
    local sentinel=${TEST_TMPDIR}/prompt-injection-ran
    local input_file=${TEST_TMPDIR}/prompt-security-input.bash
    local hostile="\$(touch\${IFS}${sentinel})"
    local quoted_hostile

    printf -v quoted_hostile '%q' "${hostile}"
    {
        printf 'builtin source %q\n' "${PROJECT_ROOT}/src/modern-bash.bash"
        printf '%s\n' \
            'MODERN_BASH_COLOR=never' \
            'MODERN_BASH_UNICODE=never' \
            'MODERN_BASH_PROMPT_GIT=1' \
            'MODERN_BASH_PROMPT_STATUS=nonzero' \
            'MODERN_BASH_PROMPT_MULTILINE=1'
        printf 'modern_bash::prompt::_git_branch() { printf "%%s" %s; }\n' "${quoted_hostile}"
        printf 'PWD=%s\n' "${quoted_hostile}"
        printf '%s\n' 'modern_bash::prompt::enable' ':' 'exit'
    } >"${input_file}"

    test::capture prompt_test::interactive_file "${input_file}"
    test::assert_eq 0 "${TEST_STATUS}" || return
    if [[ -e ${sentinel} ]]; then
        printf '    prompt expansion executed hostile dynamic data\n' >&2
        return 1
    fi
}

test::run 'prompt renders failure status, cwd, and Git branch' test_prompt_renders_status_cwd_and_branch
test::run 'successful status is hidden by default' test_prompt_hides_success_status_by_default
test::run 'successful status can be shown explicitly' test_prompt_can_show_success_status
test::run 'prompt status validation rejects arithmetic injection' test_prompt_rejects_injected_status_without_execution
test::run 'legacy prompt hooks receive the original status once' test_prompt_preserves_legacy_hook_status
test::run 'Modern Bash owns PS1 after a legacy hook runs' test_prompt_owns_ps1_after_legacy_hook
test::run 'prompt composes with legacy trailing semicolons' test_prompt_composes_with_trailing_semicolon
test::run 'prompt composes with legacy comments' test_prompt_composes_with_legacy_comment
test::run 'prompt composes with Bash 5.1 command arrays' test_prompt_composes_with_command_array
test::run 'prompt status restoration does not trigger ERR traps' test_prompt_hook_does_not_trigger_err_traps_for_saved_status
test::run 'prompt has a pre-Bash-5.1 array fallback' test_prompt_has_pre_51_array_fallback
test::run 'associative prompt commands are rejected safely' test_prompt_rejects_associative_prompt_command
test::run 'ANSI prompt spans are wrapped for Readline' test_prompt_wraps_ansi_for_readline
test::run 'prompt detection preserves configured output state' test_prompt_preserves_output_capability_snapshot
test::run 'prompt requires promptvars without changing shell options' test_prompt_requires_promptvars_without_changing_it
test::run 'prompt data has terminal control characters sanitized' test_prompt_sanitizes_control_characters
test::run 'dynamic prompt data is never interpolated into PS1' test_prompt_keeps_dynamic_data_out_of_ps1
test::run 'interactive prompt expansion cannot execute dynamic data' test_prompt_expansion_does_not_execute_dynamic_data
test::run 'command arrays preserve status without duplicate ERR traps' test_prompt_command_array_executes_with_status_and_one_err_trap
test::run 'prompt disable restores unset scalar state' test_prompt_disable_restores_unset_scalar_state
test::run 'prompt disable restores scalar values' test_prompt_disable_restores_scalar_values
test::run 'prompt disable restores command arrays' test_prompt_disable_restores_command_array
test::run 'prompt disable preserves sparse command array indices' test_prompt_disable_restores_sparse_command_array
test::run 'prompt disable preserves a later PS1 replacement' test_prompt_disable_preserves_replacement_ps1
test::run 'prompt disable refuses to overwrite a changed hook' test_prompt_disable_refuses_changed_hook
test::run 'readonly prompt targets are rejected before mutation' test_prompt_rejects_readonly_targets_before_mutation
test::run 'readonly command hooks are rejected before mutation' test_prompt_rejects_readonly_command_hook_before_mutation
test::run 'case-transforming PS1 values are rejected before mutation' test_prompt_rejects_case_transforming_ps1
test::run 'Git probing minimizes child processes' test_prompt_git_probe_minimizes_processes
