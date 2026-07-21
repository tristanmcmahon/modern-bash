#!/usr/bin/env bash

bootstrap_test::defaults() {
    MODERN_BASH_CONFIG_FILE=''
    MODERN_BASH_CONFIG_LOADED=0
    MODERN_BASH_CONFIG_FOUND=0
    MODERN_BASH_INITIALIZED=0
    MODERN_BASH_INIT_ERROR=''
    MODERN_BASH_PROMPT_ENABLED=0
    MODERN_BASH_PROMPT_ORIGINAL_PS1_SET=0
    MODERN_BASH_COLOR=never
    MODERN_BASH_UNICODE=never
    MODERN_BASH_FEATURES=prompt
    MODERN_BASH_PROMPT_GIT=0
    MODERN_BASH_PROMPT_STATUS=nonzero
    MODERN_BASH_PROMPT_MULTILINE=1
}

test_init_is_noop_outside_interactive_shell() {
    local config_file=${TEST_TMPDIR}/must-not-load.bash
    local sentinel=${TEST_TMPDIR}/noninteractive-config-loaded

    printf 'printf %q >%q\n' 'config leaked' "${sentinel}" >"${config_file}"
    test::capture env MODERN_BASH_CONFIG_FILE="${config_file}" bash -c \
        'source "$1/src/init.bash"' modern-bash-test "${PROJECT_ROOT}"
    test::assert_eq 0 "${TEST_STATUS}" || return
    test::assert_eq '' "${TEST_STDOUT}" || return
    test::assert_eq '' "${TEST_STDERR}" || return
    if [[ -e ${sentinel} ]]; then
        printf '    non-interactive init loaded the config file\n' >&2
        return 1
    fi
}

test_bootstrap_enables_prompt_by_default() {
    bootstrap_test::defaults
    PS1=original
    unset PROMPT_COMMAND
    modern_bash::bootstrap::initialize || return
    test::assert_eq 1 "${MODERN_BASH_INITIALIZED}" || return
    test::assert_eq 1 "${MODERN_BASH_PROMPT_ENABLED}" || return
    test::assert_eq original "${MODERN_BASH_PROMPT_ORIGINAL_PS1}"
}

test_bootstrap_can_disable_all_features() {
    bootstrap_test::defaults
    MODERN_BASH_FEATURES=''
    PS1='keep this prompt'
    PROMPT_COMMAND='keep_this_hook'
    modern_bash::bootstrap::initialize || return
    test::assert_eq 1 "${MODERN_BASH_INITIALIZED}" || return
    test::assert_eq 0 "${MODERN_BASH_PROMPT_ENABLED}" || return
    test::assert_eq 'keep this prompt' "${PS1}" || return
    test::assert_eq keep_this_hook "${PROMPT_COMMAND}"
}

test_bootstrap_is_idempotent() {
    local first_ps1
    local first_prompt_command

    bootstrap_test::defaults
    PS1=original
    PROMPT_COMMAND='legacy_status=$?'
    modern_bash::bootstrap::initialize || return
    first_ps1=${PS1}
    first_prompt_command=${PROMPT_COMMAND}
    modern_bash::bootstrap::initialize || return
    test::assert_eq "${first_ps1}" "${PS1}" || return
    test::assert_eq "${first_prompt_command}" "${PROMPT_COMMAND}"
}

test_bootstrap_rejects_unknown_feature() {
    local status=0

    bootstrap_test::defaults
    MODERN_BASH_FEATURES=prompt,mystery
    modern_bash::bootstrap::initialize || status=$?
    test::assert_eq 2 "${status}" || return
    test::assert_eq 0 "${MODERN_BASH_INITIALIZED}" || return
    test::assert_contains "${MODERN_BASH_INIT_ERROR}" 'unknown feature: mystery'
}

test_bootstrap_preserves_unrelated_shell_state() {
    local before_options=$-
    local before_ifs=${IFS}
    local before_pwd=${PWD}
    local before_trap
    local before_alias
    local before_shopt

    bootstrap_test::defaults
    MODERN_BASH_FEATURES=''
    trap 'printf trap-fired >/dev/null' USR1
    before_trap=$(trap -p USR1)
    alias modern_bash_bootstrap_probe='printf alias-fired'
    before_alias=$(alias modern_bash_bootstrap_probe)
    before_shopt=$(shopt -p)
    modern_bash::bootstrap::initialize || return
    test::assert_eq "${before_options}" "$-" || return
    test::assert_eq "${before_ifs}" "${IFS}" || return
    test::assert_eq "${before_pwd}" "${PWD}" || return
    test::assert_eq "${before_trap}" "$(trap -p USR1)" || return
    test::assert_eq "${before_alias}" "$(alias modern_bash_bootstrap_probe)" || return
    test::assert_eq "${before_shopt}" "$(shopt -p)"
}

test_interactive_entrypoint_activates() {
    local command_text

    command_text='source "$1/src/init.bash"; printf "active=%s prompt=%s" "$MODERN_BASH_INITIALIZED" "$MODERN_BASH_PROMPT_ENABLED"'
    test::capture env MODERN_BASH_CONFIG_FILE= MODERN_BASH_COLOR=never MODERN_BASH_UNICODE=never \
        bash --noprofile --norc -i -c "${command_text}" modern-bash-test "${PROJECT_ROOT}"
    test::assert_eq 0 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDOUT}" 'active=1 prompt=1'
}

test::run 'init is silent and inert in non-interactive shells' test_init_is_noop_outside_interactive_shell
test::run 'bootstrap enables the prompt by default' test_bootstrap_enables_prompt_by_default
test::run 'an empty feature list preserves the existing prompt' test_bootstrap_can_disable_all_features
test::run 'bootstrap initialization is idempotent' test_bootstrap_is_idempotent
test::run 'unknown feature names are rejected' test_bootstrap_rejects_unknown_feature
test::run 'bootstrap preserves unrelated shell state' test_bootstrap_preserves_unrelated_shell_state
test::run 'the interactive entrypoint activates Modern Bash' test_interactive_entrypoint_activates
