#!/usr/bin/env bash

test_output_defaults_to_stderr() {
    MODERN_BASH_OUTPUT_INITIALIZED=0
    MODERN_BASH_COLOR=never
    MODERN_BASH_UNICODE=never
    test::capture modern_bash::output::info 'hello world'
    test::assert_eq 0 "${TEST_STATUS}" || return
    test::assert_eq '' "${TEST_STDOUT}" || return
    test::assert_eq 'i hello world' "${TEST_STDERR}"
}

test_output_can_target_stdout() {
    MODERN_BASH_COLOR=never
    MODERN_BASH_UNICODE=never
    modern_bash::output::configure 1 || return
    test::capture modern_bash::output::success 'done'
    test::assert_eq 'ok done' "${TEST_STDOUT}" || return
    test::assert_eq '' "${TEST_STDERR}"
}

test_output_adds_ansi_when_forced() {
    unset MODERN_BASH_COLOR NO_COLOR
    FORCE_COLOR=1
    MODERN_BASH_UNICODE=never
    modern_bash::output::configure 1 || return
    test::capture modern_bash::output::error broken
    test::assert_contains "${TEST_STDOUT}" $'\033[' || return
    test::assert_contains "${TEST_STDOUT}" 'x' || return
    test::assert_contains "${TEST_STDOUT}" broken
}

test_output_never_leaks_ansi_with_no_color() {
    unset MODERN_BASH_COLOR FORCE_COLOR
    NO_COLOR=''
    MODERN_BASH_UNICODE=never
    modern_bash::output::configure 1 || return
    test::capture modern_bash::output::warning caution
    test::assert_eq '! caution' "${TEST_STDOUT}" || return
    test::assert_not_contains "${TEST_STDOUT}" $'\033['
}

test_output_warning_uses_semantic_label() {
    MODERN_BASH_COLOR=never
    MODERN_BASH_UNICODE=never
    modern_bash::output::configure 1 || return
    test::capture modern_bash::output::warning caution
    test::assert_eq '! caution' "${TEST_STDOUT}"
}

test_output_rejects_unknown_status() {
    local status=0

    modern_bash::output::configure 1 || return
    modern_bash::output::status verbose message || status=$?
    test::assert_eq 2 "${status}"
}

test_output_preserves_printf_characters() {
    MODERN_BASH_COLOR=never
    MODERN_BASH_UNICODE=never
    modern_bash::output::configure 1 || return
    test::capture modern_bash::output::info 'progress: 100% %s'
    test::assert_eq 'i progress: 100% %s' "${TEST_STDOUT}"
}

test_output_debug_is_opt_in() {
    MODERN_BASH_COLOR=never
    MODERN_BASH_UNICODE=never
    modern_bash::output::configure 1 || return
    unset MODERN_BASH_DEBUG
    test::capture modern_bash::output::debug hidden
    test::assert_eq '' "${TEST_STDOUT}" || return
    MODERN_BASH_DEBUG=1
    test::capture modern_bash::output::debug visible
    test::assert_eq '. visible' "${TEST_STDOUT}"
}

test_output_plain_print_uses_stdout() {
    modern_bash::output::configure 2 || return
    test::capture modern_bash::output::print 'pipeline value'
    test::assert_eq 'pipeline value' "${TEST_STDOUT}" || return
    test::assert_eq '' "${TEST_STDERR}"
}

test_output_rejects_closed_fd() {
    local status=0

    exec 99>&-
    modern_bash::output::configure 99 || status=$?
    test::assert_eq 2 "${status}"
}

test::run 'styled output defaults to stderr' test_output_defaults_to_stderr
test::run 'styled output can target stdout explicitly' test_output_can_target_stdout
test::run 'forced colour emits ANSI styling' test_output_adds_ansi_when_forced
test::run 'NO_COLOR output contains no ANSI sequence' test_output_never_leaks_ansi_with_no_color
test::run 'warnings use the warning semantic label' test_output_warning_uses_semantic_label
test::run 'unknown output statuses are rejected' test_output_rejects_unknown_status
test::run 'messages are never interpreted as printf formats' test_output_preserves_printf_characters
test::run 'debug messages are opt-in' test_output_debug_is_opt_in
test::run 'plain pipeline output always uses stdout' test_output_plain_print_uses_stdout
test::run 'closed output file descriptors are rejected' test_output_rejects_closed_fd
