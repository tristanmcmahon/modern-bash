#!/usr/bin/env bash

# This is the interactive entry point intended for .bashrc. Scripts may source
# it safely: no files are loaded and no state is changed outside an interactive
# shell.
case $- in
    *i*) ;;
    *) return 0 ;;
esac

if [[ ${MODERN_BASH_INITIALIZED:-0} == 1 ]]; then
    return 0
fi

# shellcheck source=src/modern-bash.bash
source "$({
    CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P
})/modern-bash.bash" || return

if ! modern_bash::bootstrap::initialize; then
    printf 'modern-bash: initialization failed: %s\n' \
        "${MODERN_BASH_INIT_ERROR:-unknown error}" >&2
    return 1
fi
