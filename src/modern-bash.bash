#!/usr/bin/env bash

# This file is a sourceable entry point. It intentionally does not alter shell
# options, traps, aliases, the working directory, or the caller's IFS.

if [[ ${MODERN_BASH_LOADED:-0} == 1 ]]; then
    return 0
fi

MODERN_BASH_VERSION=0.1.0

_modern_bash_source_dir=$(
    CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P
) || return 1

# shellcheck source=src/lib/capabilities.bash
source "${_modern_bash_source_dir}/lib/capabilities.bash"
# shellcheck source=src/lib/theme.bash
source "${_modern_bash_source_dir}/lib/theme.bash"
# shellcheck source=src/lib/output.bash
source "${_modern_bash_source_dir}/lib/output.bash"

unset _modern_bash_source_dir
MODERN_BASH_LOADED=1
