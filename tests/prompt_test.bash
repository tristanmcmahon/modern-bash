#!/usr/bin/env bash

prompt_test::defaults() {
    MODERN_BASH_PROMPT_ENABLED=0
    MODERN_BASH_PROMPT_ORIGINAL_PS1_SET=0
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
    prompt_test::defaults
    MODERN_BASH_PROMPT_GIT=0
    PROMPT_COMMAND=('legacy_status=$?' 'legacy_count=$((${legacy_count:-0} + 1))')
    modern_bash::prompt::enable || return
    test::assert_eq 4 "${#PROMPT_COMMAND[@]}" || return
    test::assert_eq modern_bash::prompt::capture_status "${PROMPT_COMMAND[0]}" || return
    test::assert_eq 'legacy_status=$?' "${PROMPT_COMMAND[1]}" || return
    test::assert_eq modern_bash::prompt::render_captured "${PROMPT_COMMAND[3]}"
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
    bash --noprofile --norc -i -s <"$1"
}

test_prompt_expansion_does_not_execute_dynamic_data() {
    local sentinel=${TEST_TMPDIR}/prompt-injection-ran
    local input_file=${TEST_TMPDIR}/prompt-security-input.bash
    local hostile="\$(touch\${IFS}${sentinel})"
    local quoted_hostile

    printf -v quoted_hostile '%q' "${hostile}"
    {
        printf 'source %q\n' "${PROJECT_ROOT}/src/modern-bash.bash"
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
test::run 'legacy prompt hooks receive the original status once' test_prompt_preserves_legacy_hook_status
test::run 'Modern Bash owns PS1 after a legacy hook runs' test_prompt_owns_ps1_after_legacy_hook
test::run 'prompt composes with legacy trailing semicolons' test_prompt_composes_with_trailing_semicolon
test::run 'prompt composes with legacy comments' test_prompt_composes_with_legacy_comment
test::run 'prompt composes with Bash 5.1 command arrays' test_prompt_composes_with_command_array
test::run 'prompt has a pre-Bash-5.1 array fallback' test_prompt_has_pre_51_array_fallback
test::run 'associative prompt commands are rejected safely' test_prompt_rejects_associative_prompt_command
test::run 'ANSI prompt spans are wrapped for Readline' test_prompt_wraps_ansi_for_readline
test::run 'prompt detection preserves configured output state' test_prompt_preserves_output_capability_snapshot
test::run 'prompt requires promptvars without changing shell options' test_prompt_requires_promptvars_without_changing_it
test::run 'prompt data has terminal control characters sanitized' test_prompt_sanitizes_control_characters
test::run 'dynamic prompt data is never interpolated into PS1' test_prompt_keeps_dynamic_data_out_of_ps1
test::run 'interactive prompt expansion cannot execute dynamic data' test_prompt_expansion_does_not_execute_dynamic_data
