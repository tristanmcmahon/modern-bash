#!/usr/bin/env bash

test_capabilities_disable_color_for_redirected_output() {
    unset FORCE_COLOR NO_COLOR MODERN_BASH_COLOR
    TERM=xterm-256color
    modern_bash::capabilities::detect 1 || return
    test::assert_eq 0 "${MODERN_BASH_CAP_TTY}" 'test output should be redirected' || return
    test::assert_eq 0 "${MODERN_BASH_CAP_COLOR_LEVEL}" || return
    test::assert_eq non-terminal "${MODERN_BASH_CAP_COLOR_SOURCE}"
}

test_capabilities_force_truecolor() {
    FORCE_COLOR=3
    NO_COLOR=1
    unset MODERN_BASH_COLOR
    TERM=dumb
    modern_bash::capabilities::detect 1 || return
    test::assert_eq 3 "${MODERN_BASH_CAP_COLOR_LEVEL}" || return
    test::assert_eq force-color "${MODERN_BASH_CAP_COLOR_SOURCE}"
}

test_capabilities_force_basic_color() {
    FORCE_COLOR=1
    unset NO_COLOR MODERN_BASH_COLOR
    TERM=xterm-256color
    modern_bash::capabilities::detect 1 || return
    test::assert_eq 1 "${MODERN_BASH_CAP_COLOR_LEVEL}" || return
    test::assert_eq force-color "${MODERN_BASH_CAP_COLOR_SOURCE}"
}

test_capabilities_honor_empty_no_color() {
    unset FORCE_COLOR MODERN_BASH_COLOR
    NO_COLOR=''
    TERM=xterm-256color
    modern_bash::capabilities::detect 1 || return
    test::assert_eq 0 "${MODERN_BASH_CAP_COLOR_LEVEL}" || return
    test::assert_eq no-color "${MODERN_BASH_CAP_COLOR_SOURCE}"
}

test_capabilities_namespaced_override_has_priority() {
    FORCE_COLOR=3
    MODERN_BASH_COLOR=never
    modern_bash::capabilities::detect 1 || return
    test::assert_eq 0 "${MODERN_BASH_CAP_COLOR_LEVEL}" || return
    test::assert_eq modern-bash "${MODERN_BASH_CAP_COLOR_SOURCE}"
}

test_capabilities_unknown_terminfo_is_plain() {
    local level

    tput() {
        return 1
    }
    TERM=definitely-not-a-terminfo-entry
    level=$(modern_bash::capabilities::_automatic_color_level) || return
    test::assert_eq 0 "${level}"
}

test_capabilities_known_term_works_without_tput() {
    local level

    PATH=''
    TERM=xterm-256color
    level=$(modern_bash::capabilities::_automatic_color_level) || return
    test::assert_eq 2 "${level}"
}

test_capabilities_detect_utf8_locale() {
    unset LC_ALL LC_CTYPE MODERN_BASH_UNICODE
    LANG=en_NZ.UTF-8
    modern_bash::capabilities::detect 1 || return
    test::assert_eq 1 "${MODERN_BASH_CAP_UNICODE}"
}

test_capabilities_fall_back_to_ascii() {
    LC_ALL=C
    unset MODERN_BASH_UNICODE
    modern_bash::capabilities::detect 1 || return
    test::assert_eq 0 "${MODERN_BASH_CAP_UNICODE}"
}

test_capabilities_use_columns_override() {
    COLUMNS=132
    modern_bash::capabilities::detect 1 || return
    test::assert_eq 132 "${MODERN_BASH_CAP_COLUMNS}"
}

test_capabilities_reject_invalid_fd() {
    local status=0

    modern_bash::capabilities::detect not-a-fd || status=$?
    test::assert_eq 2 "${status}"
}

test_capabilities_reject_partially_numeric_fd() {
    local status=0

    modern_bash::capabilities::detect 12x || status=$?
    test::assert_eq 2 "${status}"
}

test_capabilities_hyperlink_override() {
    MODERN_BASH_HYPERLINKS=always
    modern_bash::capabilities::detect 1 || return
    test::assert_eq 1 "${MODERN_BASH_CAP_HYPERLINKS}"
}

test_capabilities_reject_invalid_override() {
    local status=0

    MODERN_BASH_COLOR=sometimes
    modern_bash::capabilities::detect 1 || status=$?
    test::assert_eq 2 "${status}" || return
    test::assert_eq 0 "${MODERN_BASH_CAPABILITIES_DETECTED}"
}

test_capabilities_reject_empty_namespaced_override() {
    local status=0

    MODERN_BASH_COLOR=''
    modern_bash::capabilities::detect 1 || status=$?
    test::assert_eq 2 "${status}" || return
    test::assert_eq 0 "${MODERN_BASH_CAPABILITIES_DETECTED}"
}

test_capabilities_reject_invalid_unicode_override() {
    local status=0

    unset MODERN_BASH_COLOR
    MODERN_BASH_UNICODE=sometimes
    modern_bash::capabilities::detect 1 || status=$?
    test::assert_eq 2 "${status}" || return
    test::assert_eq 0 "${MODERN_BASH_CAPABILITIES_DETECTED}"
}

test_capabilities_reject_invalid_hyperlink_override() {
    local status=0

    unset MODERN_BASH_COLOR MODERN_BASH_UNICODE
    MODERN_BASH_HYPERLINKS=sometimes
    modern_bash::capabilities::detect 1 || status=$?
    test::assert_eq 2 "${status}" || return
    test::assert_eq 0 "${MODERN_BASH_CAPABILITIES_DETECTED}"
}

test::run 'redirected output disables automatic colour' test_capabilities_disable_color_for_redirected_output
test::run 'FORCE_COLOR selects truecolour even without a TTY' test_capabilities_force_truecolor
test::run 'FORCE_COLOR=1 selects the base ANSI palette exactly' test_capabilities_force_basic_color
test::run 'an empty NO_COLOR variable disables colour' test_capabilities_honor_empty_no_color
test::run 'the namespaced colour override has priority' test_capabilities_namespaced_override_has_priority
test::run 'unknown or broken terminfo falls back to plain text' test_capabilities_unknown_terminfo_is_plain
test::run 'known terminals work when optional tput is absent' test_capabilities_known_term_works_without_tput
test::run 'UTF-8 locales enable Unicode symbols' test_capabilities_detect_utf8_locale
test::run 'non-UTF-8 locales use ASCII symbols' test_capabilities_fall_back_to_ascii
test::run 'COLUMNS supplies a deterministic terminal width' test_capabilities_use_columns_override
test::run 'invalid file descriptors are rejected' test_capabilities_reject_invalid_fd
test::run 'partially numeric file descriptors are rejected' test_capabilities_reject_partially_numeric_fd
test::run 'terminal hyperlink detection can be overridden' test_capabilities_hyperlink_override
test::run 'invalid namespaced overrides are rejected' test_capabilities_reject_invalid_override
test::run 'empty namespaced overrides are rejected' test_capabilities_reject_empty_namespaced_override
test::run 'invalid Unicode overrides are rejected' test_capabilities_reject_invalid_unicode_override
test::run 'invalid hyperlink overrides are rejected' test_capabilities_reject_invalid_hyperlink_override
