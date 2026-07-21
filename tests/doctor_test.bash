#!/usr/bin/env bash

test_doctor_plain_report() {
    test::capture env -u NO_COLOR -u FORCE_COLOR "${PROJECT_ROOT}/bin/modern-bash" doctor --plain
    test::assert_eq 0 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDOUT}" 'Modern Bash doctor' || return
    test::assert_contains "${TEST_STDOUT}" 'Bash:' || return
    test::assert_contains "${TEST_STDOUT}" 'Colour: none (modern-bash)' || return
    test::assert_contains "${TEST_STDOUT}" 'Summary: ready (0 failures)' || return
    test::assert_not_contains "${TEST_STDOUT}" $'\033[' || return
    test::assert_eq '' "${TEST_STDERR}"
}

test_doctor_forced_color_report() {
    test::capture env FORCE_COLOR=2 MODERN_BASH_UNICODE=never "${PROJECT_ROOT}/bin/modern-bash" doctor
    test::assert_eq 0 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDOUT}" $'\033[' || return
    test::assert_contains "${TEST_STDOUT}" 'ANSI 256-colour'
}

test_doctor_help() {
    test::capture "${PROJECT_ROOT}/bin/modern-bash" doctor --help
    test::assert_eq 0 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDOUT}" 'Usage: modern-bash doctor' || return
    test::assert_eq '' "${TEST_STDERR}"
}

test_doctor_rejects_unknown_option() {
    test::capture "${PROJECT_ROOT}/bin/modern-bash" doctor --wat
    test::assert_eq 64 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDERR}" 'unknown option: --wat'
}

test_doctor_rejects_invalid_capability_override() {
    test::capture env MODERN_BASH_UNICODE=sometimes "${PROJECT_ROOT}/bin/modern-bash" doctor
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
    test::capture "${PROJECT_ROOT}/bin/modern-bash" wat
    test::assert_eq 64 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDERR}" 'unknown command: wat'
}

test_cli_prints_version() {
    test::capture "${PROJECT_ROOT}/bin/modern-bash" --version
    test::assert_eq 0 "${TEST_STATUS}" || return
    test::assert_eq 'modern-bash 0.1.0' "${TEST_STDOUT}"
}

test::run 'doctor produces a complete plain report' test_doctor_plain_report
test::run 'doctor can render a forced 256-colour report' test_doctor_forced_color_report
test::run 'doctor has command-specific help' test_doctor_help
test::run 'doctor rejects unknown options' test_doctor_rejects_unknown_option
test::run 'doctor rejects invalid capability overrides' test_doctor_rejects_invalid_capability_override
test::run 'doctor plain mode does not leak configuration' test_doctor_plain_does_not_leak_configuration
test::run 'the CLI rejects unknown commands' test_cli_rejects_unknown_command
test::run 'the CLI reports its version' test_cli_prints_version
