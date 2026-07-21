#!/usr/bin/env bash

doctor_test::cli() {
    HOME=${TEST_TMPDIR}/doctor-home \
        XDG_CONFIG_HOME=${TEST_TMPDIR}/doctor-xdg \
        "${PROJECT_ROOT}/bin/modern-bash" "$@"
}

test_doctor_plain_report() {
    unset NO_COLOR FORCE_COLOR
    test::capture doctor_test::cli doctor --plain
    test::assert_eq 0 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDOUT}" 'Modern Bash doctor' || return
    test::assert_contains "${TEST_STDOUT}" 'Bash:' || return
    test::assert_contains "${TEST_STDOUT}" 'Colour: none (modern-bash)' || return
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
    test::assert_eq 'modern-bash 0.2.0' "${TEST_STDOUT}"
}

test_cli_prints_init_code() {
    test::capture doctor_test::cli init
    test::assert_eq 0 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDOUT}" 'source ' || return
    test::assert_contains "${TEST_STDOUT}" '/src/init.bash'
}

test_doctor_reports_interactive_foundation() {
    unset MODERN_BASH_CONFIG_FILE
    test::capture doctor_test::cli doctor --plain
    test::assert_eq 0 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDOUT}" 'Interactive init:' || return
    test::assert_contains "${TEST_STDOUT}" 'Configuration:' || return
    test::assert_contains "${TEST_STDOUT}" 'Prompt feature: enabled' || return
    test::assert_contains "${TEST_STDOUT}" 'Optional dependency git:'
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

test::run 'doctor produces a complete plain report' test_doctor_plain_report
test::run 'doctor can render a forced 256-colour report' test_doctor_forced_color_report
test::run 'doctor has command-specific help' test_doctor_help
test::run 'doctor rejects unknown options' test_doctor_rejects_unknown_option
test::run 'doctor rejects invalid capability overrides' test_doctor_rejects_invalid_capability_override
test::run 'doctor plain mode does not leak configuration' test_doctor_plain_does_not_leak_configuration
test::run 'the CLI rejects unknown commands' test_cli_rejects_unknown_command
test::run 'the CLI reports its version' test_cli_prints_version
test::run 'the CLI prints interactive init code' test_cli_prints_init_code
test::run 'doctor reports the interactive foundation' test_doctor_reports_interactive_foundation
test::run 'doctor rejects invalid feature configuration' test_doctor_rejects_invalid_feature_config
