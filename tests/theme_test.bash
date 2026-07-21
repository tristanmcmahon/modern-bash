#!/usr/bin/env bash

test_theme_plain_ascii() {
    modern_bash::theme::init 0 0 || return
    test::assert_eq '' "${MODERN_BASH_THEME_ERROR}" || return
    test::assert_eq '' "${MODERN_BASH_THEME_RESET}" || return
    test::assert_eq ok "${MODERN_BASH_THEME_ICON_SUCCESS}"
}

test_theme_ansi_palette() {
    modern_bash::theme::init 1 0 || return
    test::assert_eq $'\033[34m' "${MODERN_BASH_THEME_INFO}" || return
    test::assert_eq $'\033[0m' "${MODERN_BASH_THEME_RESET}"
}

test_theme_truecolor_palette() {
    modern_bash::theme::init 3 1 || return
    test::assert_eq $'\033[38;2;235;95;95m' "${MODERN_BASH_THEME_ERROR}" || return
    test::assert_eq '✓' "${MODERN_BASH_THEME_ICON_SUCCESS}"
}

test_theme_256_palette() {
    modern_bash::theme::init 2 0 || return
    test::assert_eq $'\033[38;5;214m' "${MODERN_BASH_THEME_WARNING}" || return
    test::assert_eq '!' "${MODERN_BASH_THEME_ICON_WARNING}"
}

test_theme_rejects_unknown_level() {
    local status=0

    modern_bash::theme::init 9 0 || status=$?
    test::assert_eq 2 "${status}"
}

test_theme_rejects_unknown_unicode_mode() {
    local status=0

    modern_bash::theme::init 0 2 || status=$?
    test::assert_eq 2 "${status}" || return
    test::assert_eq 0 "${MODERN_BASH_THEME_INITIALIZED}"
}

test::run 'plain themes use ASCII and no escapes' test_theme_plain_ascii
test::run 'ANSI terminals receive the base palette' test_theme_ansi_palette
test::run 'truecolour terminals receive RGB semantic colours' test_theme_truecolor_palette
test::run '256-colour terminals receive the extended palette' test_theme_256_palette
test::run 'unknown colour levels are rejected' test_theme_rejects_unknown_level
test::run 'unknown Unicode modes are rejected' test_theme_rejects_unknown_unicode_mode
