#!/usr/bin/env bash

test_loader_preserves_caller_state() {
    local script

    script='
        set -o nounset
        before_options=$-
        before_ifs=$IFS
        before_pwd=$PWD
        trap "printf trap-fired >/dev/null" USR1
        before_trap=$(trap -p USR1)
        alias modern_bash_probe="printf alias-fired"
        before_alias=$(alias modern_bash_probe)
        source "$1/src/modern-bash.bash" || exit
        [[ $- == "$before_options" ]] || exit 10
        [[ $IFS == "$before_ifs" ]] || exit 11
        [[ $PWD == "$before_pwd" ]] || exit 12
        [[ $(trap -p USR1) == "$before_trap" ]] || exit 13
        [[ $(alias modern_bash_probe) == "$before_alias" ]] || exit 14
    '
    test::capture bash -c "${script}" modern-bash-test "${PROJECT_ROOT}"
    test::assert_eq 0 "${TEST_STATUS}" || return
    test::assert_eq '' "${TEST_STDOUT}" || return
    test::assert_eq '' "${TEST_STDERR}"
}

test_loader_is_idempotent() {
    MODERN_BASH_OUTPUT_FD=1
    # shellcheck source=src/modern-bash.bash
    source "${PROJECT_ROOT}/src/modern-bash.bash" || return
    test::assert_eq 1 "${MODERN_BASH_OUTPUT_FD}"
}

test::run 'the loader preserves caller shell state' test_loader_preserves_caller_state
test::run 'the loader is idempotent' test_loader_is_idempotent
