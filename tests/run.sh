#!/usr/bin/env bash

set -o nounset
set -o pipefail

TESTS_DIR=$(
    CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P
) || exit 1
PROJECT_ROOT=$(CDPATH='' cd -- "${TESTS_DIR}/.." && pwd -P) || exit 1

# shellcheck source=tests/test_helper.bash
source "${TESTS_DIR}/test_helper.bash"
# shellcheck source=src/modern-bash.bash
source "${PROJECT_ROOT}/src/modern-bash.bash"
# shellcheck source=src/commands/doctor.bash
source "${PROJECT_ROOT}/src/commands/doctor.bash"

# shellcheck source=tests/loader_test.bash
source "${TESTS_DIR}/loader_test.bash"
# shellcheck source=tests/capabilities_test.bash
source "${TESTS_DIR}/capabilities_test.bash"
# shellcheck source=tests/theme_test.bash
source "${TESTS_DIR}/theme_test.bash"
# shellcheck source=tests/output_test.bash
source "${TESTS_DIR}/output_test.bash"
# shellcheck source=tests/doctor_test.bash
source "${TESTS_DIR}/doctor_test.bash"

test::finish
