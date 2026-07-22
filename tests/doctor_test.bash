#!/usr/bin/env bash

doctor_test::cli() {
    HOME=${TEST_TMPDIR}/doctor-home \
        XDG_CONFIG_HOME=${TEST_TMPDIR}/doctor-xdg \
        "${BASH}" "${PROJECT_ROOT}/bin/modern-bash" "$@"
}

test_doctor_plain_report() {
    unset NO_COLOR FORCE_COLOR
    test::capture doctor_test::cli doctor --plain
    test::assert_eq 0 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDOUT}" 'Modern Bash doctor' || return
    test::assert_contains "${TEST_STDOUT}" 'Bash:' || return
    test::assert_contains "${TEST_STDOUT}" 'Colour: none (non-terminal)' || return
    test::assert_contains "${TEST_STDOUT}" 'Summary: ready (0 failures)' || return
    test::assert_not_contains "${TEST_STDOUT}" $'\033[' || return
    test::assert_eq '' "${TEST_STDERR}"
}

test_doctor_forced_color_report() {
    unset NO_COLOR
    FORCE_COLOR=2
    MODERN_BASH_UNICODE=never
    export FORCE_COLOR MODERN_BASH_UNICODE
    test::capture doctor_test::cli doctor
    test::assert_eq 0 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDOUT}" $'\033[' || return
    test::assert_contains "${TEST_STDOUT}" 'ANSI 256-colour'
}

test_doctor_plain_changes_presentation_not_detected_facts() {
    unset NO_COLOR MODERN_BASH_COLOR
    FORCE_COLOR=2
    MODERN_BASH_UNICODE=always
    export FORCE_COLOR MODERN_BASH_UNICODE
    test::capture doctor_test::cli doctor --plain
    test::assert_eq 0 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDOUT}" 'Colour: ANSI 256-colour (force-color)' || return
    test::assert_contains "${TEST_STDOUT}" 'UTF-8 symbols: yes' || return
    test::assert_not_contains "${TEST_STDOUT}" $'\033['
}

test_doctor_applies_config_before_capability_detection() {
    local config_file=${TEST_TMPDIR}/doctor-capability-config.bash

    printf '%s\n' 'MODERN_BASH_COLOR=always' >"${config_file}"
    MODERN_BASH_CONFIG_FILE=${config_file}
    TERM=dumb
    export MODERN_BASH_CONFIG_FILE TERM
    unset COLORTERM FORCE_COLOR NO_COLOR
    test::capture doctor_test::cli doctor --plain
    test::assert_eq 0 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDOUT}" 'Colour: ANSI 16-colour (modern-bash)' || return
    test::assert_not_contains "${TEST_STDOUT}" $'\033['
}

test_doctor_help() {
    test::capture doctor_test::cli doctor --help
    test::assert_eq 0 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDOUT}" 'Usage: modern-bash doctor' || return
    test::assert_eq '' "${TEST_STDERR}"
}

test_doctor_rejects_unknown_option() {
    test::capture doctor_test::cli doctor --wat
    test::assert_eq 64 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDERR}" 'unknown option: --wat'
}

test_doctor_rejects_invalid_capability_override() {
    MODERN_BASH_UNICODE=sometimes
    export MODERN_BASH_UNICODE
    test::capture doctor_test::cli doctor
    test::assert_eq 64 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDERR}" 'invalid capability override'
}

test_doctor_plain_does_not_leak_configuration() {
    MODERN_BASH_COLOR=always
    MODERN_BASH_UNICODE=always
    test::capture modern_bash::doctor::run --plain
    test::assert_eq 0 "${TEST_STATUS}" || return
    test::assert_eq always "${MODERN_BASH_COLOR}" || return
    test::assert_eq always "${MODERN_BASH_UNICODE}"
}

test_cli_rejects_unknown_command() {
    test::capture doctor_test::cli wat
    test::assert_eq 64 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDERR}" 'unknown command: wat'
}

test_cli_prints_version() {
    test::capture doctor_test::cli --version
    test::assert_eq 0 "${TEST_STATUS}" || return
    test::assert_eq 'modern-bash 0.3.0' "${TEST_STDOUT}"
}

test_cli_prints_init_code() {
    test::capture doctor_test::cli init
    test::assert_eq 0 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDOUT}" 'builtin source ' || return
    test::assert_contains "${TEST_STDOUT}" '/src/init.bash'
}

test_cli_init_rejects_arguments() {
    test::capture doctor_test::cli init extra
    test::assert_eq 64 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDERR}" 'takes no arguments'
}

test_cli_has_command_specific_help() {
    test::capture doctor_test::cli help init
    test::assert_eq 0 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDOUT}" 'Usage: modern-bash init' || return
    test::assert_eq '' "${TEST_STDERR}"
}

test_doctor_reports_interactive_foundation() {
    unset MODERN_BASH_CONFIG_FILE
    test::capture doctor_test::cli doctor --plain
    test::assert_eq 0 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDOUT}" 'Interactive init:' || return
    test::assert_contains "${TEST_STDOUT}" 'Configuration:' || return
    test::assert_contains "${TEST_STDOUT}" 'Prompt feature (configured): enabled' || return
    test::assert_contains "${TEST_STDOUT}" 'Optional dependency git:'
}

test_doctor_config_cannot_overwrite_bookkeeping_locals() {
    local config_file=${TEST_TMPDIR}/doctor-scratch-config.bash

    printf '%s\n' \
        'failures=7' \
        'option=broken' \
        'status=9' \
        'git_path=/definitely/not/git' >"${config_file}"
    MODERN_BASH_CONFIG_FILE=${config_file}
    export MODERN_BASH_CONFIG_FILE
    test::capture doctor_test::cli doctor --plain
    test::assert_eq 0 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDOUT}" 'Summary: ready (0 failures)'
}

test_doctor_sanitizes_terminal_control_data() {
    TERM=$'hostile\n\033]8;;url\a'
    MODERN_BASH_COLOR=never
    export TERM MODERN_BASH_COLOR
    test::capture doctor_test::cli doctor --plain
    test::assert_eq 0 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDOUT}" 'TERM: hostile??]8;;url?' || return
    test::assert_not_contains "${TEST_STDOUT}" $'\033'
}

test_doctor_reports_activation_in_sourced_process() {
    MODERN_BASH_INITIALIZED=1
    test::capture modern_bash::doctor::run --plain
    test::assert_eq 0 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDOUT}" 'Activation in this process: active'
}

test_doctor_rejects_invalid_feature_config() {
    local config_file=${TEST_TMPDIR}/doctor-invalid-config.bash

    printf '%s\n' 'MODERN_BASH_FEATURES=prompt,mystery' >"${config_file}"
    MODERN_BASH_CONFIG_FILE=${config_file}
    export MODERN_BASH_CONFIG_FILE
    test::capture doctor_test::cli doctor --plain
    test::assert_eq 1 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDOUT}" 'unknown feature: mystery' || return
    test::assert_contains "${TEST_STDOUT}" 'Summary: 1 failure(s)'
}

test_doctor_rejects_invalid_capability_config() {
    local config_file=${TEST_TMPDIR}/doctor-invalid-capability-config.bash

    printf '%s\n' 'MODERN_BASH_COLOR=sometimes' >"${config_file}"
    MODERN_BASH_CONFIG_FILE=${config_file}
    export MODERN_BASH_CONFIG_FILE
    test::capture doctor_test::cli doctor --plain
    test::assert_eq 64 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDERR}" 'MODERN_BASH_COLOR must be always, auto, or never'
}

test::run 'doctor produces a complete plain report' test_doctor_plain_report
test::run 'doctor can render a forced 256-colour report' test_doctor_forced_color_report
test::run 'doctor plain mode preserves detected facts' test_doctor_plain_changes_presentation_not_detected_facts
test::run 'doctor applies config before capability detection' test_doctor_applies_config_before_capability_detection
test::run 'doctor has command-specific help' test_doctor_help
test::run 'doctor rejects unknown options' test_doctor_rejects_unknown_option
test::run 'doctor rejects invalid capability overrides' test_doctor_rejects_invalid_capability_override
test::run 'doctor plain mode does not leak configuration' test_doctor_plain_does_not_leak_configuration
test::run 'the CLI rejects unknown commands' test_cli_rejects_unknown_command
test::run 'the CLI reports its version' test_cli_prints_version
test::run 'the CLI prints interactive init code' test_cli_prints_init_code
test::run 'the CLI init command rejects arguments' test_cli_init_rejects_arguments
test::run 'the CLI provides command-specific help' test_cli_has_command_specific_help
test::run 'doctor reports the interactive foundation' test_doctor_reports_interactive_foundation
test::run 'config scratch names cannot corrupt doctor bookkeeping' test_doctor_config_cannot_overwrite_bookkeeping_locals
test::run 'doctor sanitizes terminal control data' test_doctor_sanitizes_terminal_control_data
test::run 'doctor reports activation in its own process' test_doctor_reports_activation_in_sourced_process
test::run 'doctor rejects invalid feature configuration' test_doctor_rejects_invalid_feature_config
test::run 'doctor rejects invalid capability configuration' test_doctor_rejects_invalid_capability_config
