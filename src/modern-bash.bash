#!/usr/bin/env bash

# This file is a sourceable entry point. It intentionally does not alter shell
# options, traps, aliases, the working directory, or the caller's IFS.

if [[ ${MODERN_BASH_LOADED:-0} == 1 ]]; then
    return 0
fi

MODERN_BASH_VERSION=0.2.0

MODERN_BASH_SOURCE_DIR=$(
    CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P
) || return 1

# shellcheck source=src/lib/capabilities.bash
source "${MODERN_BASH_SOURCE_DIR}/lib/capabilities.bash"
# shellcheck source=src/lib/theme.bash
source "${MODERN_BASH_SOURCE_DIR}/lib/theme.bash"
# shellcheck source=src/lib/output.bash
source "${MODERN_BASH_SOURCE_DIR}/lib/output.bash"
# shellcheck source=src/lib/config.bash
source "${MODERN_BASH_SOURCE_DIR}/lib/config.bash"
# shellcheck source=src/features/prompt.bash
source "${MODERN_BASH_SOURCE_DIR}/features/prompt.bash"
# shellcheck source=src/lib/bootstrap.bash
source "${MODERN_BASH_SOURCE_DIR}/lib/bootstrap.bash"

MODERN_BASH_LOADED=1
