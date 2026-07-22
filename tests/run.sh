#!/usr/bin/env bash

set -o nounset
set -o pipefail

# Keep the suite deterministic even when it is launched from an activated or
# heavily customized shell. Individual tests opt into the variables they need.
modern_bash_test_variable=''
while IFS= read -r modern_bash_test_variable; do
    unset "${modern_bash_test_variable}"
done < <(compgen -A variable MODERN_BASH_)
unset modern_bash_test_variable FORCE_COLOR NO_COLOR BASH_ENV ENV CDPATH

TESTS_DIR=$(
    CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P
) || exit 1
PROJECT_ROOT=$(CDPATH='' cd -- "${TESTS_DIR}/.." && pwd -P) || exit 1

# shellcheck source=tests/test_helper.bash
builtin source "${TESTS_DIR}/test_helper.bash"
# shellcheck source=src/modern-bash.bash
builtin source "${PROJECT_ROOT}/src/modern-bash.bash"
# shellcheck source=src/commands/doctor.bash
builtin source "${PROJECT_ROOT}/src/commands/doctor.bash"

# shellcheck source=tests/loader_test.bash
builtin source "${TESTS_DIR}/loader_test.bash"
# shellcheck source=tests/config_test.bash
builtin source "${TESTS_DIR}/config_test.bash"
# shellcheck source=tests/prompt_test.bash
builtin source "${TESTS_DIR}/prompt_test.bash"
# shellcheck source=tests/bootstrap_test.bash
builtin source "${TESTS_DIR}/bootstrap_test.bash"
# shellcheck source=tests/capabilities_test.bash
builtin source "${TESTS_DIR}/capabilities_test.bash"
# shellcheck source=tests/theme_test.bash
builtin source "${TESTS_DIR}/theme_test.bash"
# shellcheck source=tests/output_test.bash
builtin source "${TESTS_DIR}/output_test.bash"
# shellcheck source=tests/doctor_test.bash
builtin source "${TESTS_DIR}/doctor_test.bash"
# shellcheck source=tests/install_test.bash
builtin source "${TESTS_DIR}/install_test.bash"

test::finish
