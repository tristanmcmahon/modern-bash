#!/usr/bin/env bash

test_config_prefers_explicit_path() {
    MODERN_BASH_CONFIG_FILE="${TEST_TMPDIR}/config with spaces.bash"
    XDG_CONFIG_HOME=${TEST_TMPDIR}/xdg
    HOME=${TEST_TMPDIR}/home
    modern_bash::config::resolve
    test::assert_eq "${MODERN_BASH_CONFIG_FILE}" "${MODERN_BASH_CONFIG_PATH}"
}

test_config_tracks_explicit_disable() {
    MODERN_BASH_CONFIG_FILE=''
    modern_bash::config::resolve
    test::assert_eq '' "${MODERN_BASH_CONFIG_PATH}" || return
    test::assert_eq 1 "${MODERN_BASH_CONFIG_DISABLED}"
}

test_config_uses_xdg_path() {
    unset MODERN_BASH_CONFIG_FILE
    XDG_CONFIG_HOME=${TEST_TMPDIR}/xdg
    HOME=${TEST_TMPDIR}/home
    modern_bash::config::resolve
    test::assert_eq "${XDG_CONFIG_HOME}/modern-bash/config.bash" "${MODERN_BASH_CONFIG_PATH}"
}

test_config_ignores_relative_xdg_path() {
    unset MODERN_BASH_CONFIG_FILE
    XDG_CONFIG_HOME=relative
    HOME=${TEST_TMPDIR}/home
    modern_bash::config::resolve
    test::assert_eq "${HOME}/.config/modern-bash/config.bash" "${MODERN_BASH_CONFIG_PATH}"
}

test_config_missing_file_uses_defaults() {
    unset MODERN_BASH_FEATURES MODERN_BASH_PROMPT_GIT MODERN_BASH_PROMPT_STATUS MODERN_BASH_PROMPT_MULTILINE
    MODERN_BASH_CONFIG_FILE=${TEST_TMPDIR}/missing.bash
    MODERN_BASH_CONFIG_LOADED=0
    modern_bash::config::load || return
    modern_bash::config::apply_defaults
    test::assert_eq 0 "${MODERN_BASH_CONFIG_FOUND}" || return
    test::assert_eq prompt "${MODERN_BASH_FEATURES}" || return
    test::assert_eq nonzero "${MODERN_BASH_PROMPT_STATUS}"
}

test_config_loads_only_once() {
    local config_file=${TEST_TMPDIR}/load-once.bash

    printf '%s\n' 'MODERN_BASH_CONFIG_LOAD_COUNT=$((${MODERN_BASH_CONFIG_LOAD_COUNT:-0} + 1))' >"${config_file}"
    MODERN_BASH_CONFIG_FILE=${config_file}
    MODERN_BASH_CONFIG_LOADED=0
    modern_bash::config::load || return
    modern_bash::config::load || return
    test::assert_eq 1 "${MODERN_BASH_CONFIG_LOAD_COUNT}" || return
    test::assert_eq 1 "${MODERN_BASH_CONFIG_FOUND}"
}

test_config_loads_quoted_path() {
    local config_file="${TEST_TMPDIR}/config 100%.bash"

    printf '%s\n' 'MODERN_BASH_QUOTED_CONFIG_LOADED=1' >"${config_file}"
    MODERN_BASH_CONFIG_FILE=${config_file}
    MODERN_BASH_CONFIG_LOADED=0
    modern_bash::config::load || return
    test::assert_eq 1 "${MODERN_BASH_QUOTED_CONFIG_LOADED}"
}

test_config_rejects_non_regular_file() {
    local status=0

    MODERN_BASH_CONFIG_FILE=${TEST_TMPDIR}
    MODERN_BASH_CONFIG_LOADED=0
    modern_bash::config::load || status=$?
    test::assert_eq 1 "${status}" || return
    test::assert_contains "${MODERN_BASH_CONFIG_ERROR}" 'not a readable regular file'
}

test_config_rejects_dangling_symlink() {
    local config_file=${TEST_TMPDIR}/dangling-config.bash
    local status=0

    command ln -s "${TEST_TMPDIR}/missing-config-target" "${config_file}" || return
    MODERN_BASH_CONFIG_FILE=${config_file}
    MODERN_BASH_CONFIG_LOADED=0
    modern_bash::config::load || status=$?
    test::assert_eq 1 "${status}" || return
    test::assert_contains "${MODERN_BASH_CONFIG_ERROR}" 'not a readable regular file'
}

test_config_uses_the_source_builtin() {
    local config_file=${TEST_TMPDIR}/builtin-source-config.bash

    printf '%s\n' 'MODERN_BASH_BUILTIN_SOURCE_WORKED=1' >"${config_file}"
    source() { return 99; }
    MODERN_BASH_CONFIG_FILE=${config_file}
    MODERN_BASH_CONFIG_LOADED=0
    modern_bash::config::load || return
    test::assert_eq 1 "${MODERN_BASH_BUILTIN_SOURCE_WORKED}"
}

test_config_rejects_invalid_prompt_setting() {
    local status=0

    MODERN_BASH_FEATURES=prompt
    MODERN_BASH_PROMPT_GIT=maybe
    MODERN_BASH_PROMPT_STATUS=nonzero
    MODERN_BASH_PROMPT_MULTILINE=1
    modern_bash::config::validate || status=$?
    test::assert_eq 2 "${status}" || return
    test::assert_contains "${MODERN_BASH_CONFIG_ERROR}" 'MODERN_BASH_PROMPT_GIT'
}

test_config_reports_source_failure_and_can_retry() {
    local config_file=${TEST_TMPDIR}/retry-config.bash
    local status=0

    printf '%s\n' 'return 23' >"${config_file}"
    MODERN_BASH_CONFIG_FILE=${config_file}
    MODERN_BASH_CONFIG_LOADED=0
    modern_bash::config::load || status=$?
    test::assert_eq 1 "${status}" || return
    test::assert_eq 0 "${MODERN_BASH_CONFIG_LOADED}" || return
    test::assert_contains "${MODERN_BASH_CONFIG_ERROR}" 'returned an error' || return

    printf '%s\n' 'MODERN_BASH_CONFIG_RETRY_WORKED=1' >"${config_file}"
    modern_bash::config::load || return
    test::assert_eq 1 "${MODERN_BASH_CONFIG_RETRY_WORKED}" || return
    test::assert_eq 1 "${MODERN_BASH_CONFIG_LOADED}"
}

test_config_validation_clears_stale_errors() {
    MODERN_BASH_CONFIG_ERROR='old error'
    MODERN_BASH_PROMPT_GIT=1
    MODERN_BASH_PROMPT_STATUS=nonzero
    MODERN_BASH_PROMPT_MULTILINE=1
    modern_bash::config::validate || return
    test::assert_eq '' "${MODERN_BASH_CONFIG_ERROR}"
}

test_config_rejects_invalid_capability_override() {
    local status=0

    MODERN_BASH_PROMPT_GIT=1
    MODERN_BASH_PROMPT_STATUS=nonzero
    MODERN_BASH_PROMPT_MULTILINE=1
    MODERN_BASH_COLOR=sometimes
    modern_bash::config::validate || status=$?
    test::assert_eq 2 "${status}" || return
    test::assert_contains "${MODERN_BASH_CONFIG_ERROR}" 'MODERN_BASH_COLOR'
}

test::run 'explicit config paths take precedence' test_config_prefers_explicit_path
test::run 'an empty explicit config path is tracked as disabled' test_config_tracks_explicit_disable
test::run 'XDG_CONFIG_HOME selects the config path' test_config_uses_xdg_path
test::run 'relative XDG paths fall back to HOME' test_config_ignores_relative_xdg_path
test::run 'missing config files activate defaults' test_config_missing_file_uses_defaults
test::run 'configuration is loaded only once' test_config_loads_only_once
test::run 'config paths with spaces and percent signs load safely' test_config_loads_quoted_path
test::run 'non-regular config paths are rejected' test_config_rejects_non_regular_file
test::run 'dangling config symlinks are rejected' test_config_rejects_dangling_symlink
test::run 'config loading selects the source builtin explicitly' test_config_uses_the_source_builtin
test::run 'invalid prompt configuration is rejected' test_config_rejects_invalid_prompt_setting
test::run 'failed configuration loads can be retried' test_config_reports_source_failure_and_can_retry
test::run 'successful validation clears stale errors' test_config_validation_clears_stale_errors
test::run 'invalid capability overrides are rejected by config validation' test_config_rejects_invalid_capability_override
