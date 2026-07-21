#!/usr/bin/env bash

TEST_TOTAL=0
TEST_FAILED=0
TEST_TMPDIR=$(mktemp -d "${TMPDIR:-/tmp}/modern-bash-tests.XXXXXX") || exit 1
TEST_STDOUT_FILE=${TEST_TMPDIR}/stdout
TEST_STDERR_FILE=${TEST_TMPDIR}/stderr
TEST_STDOUT=''
TEST_STDERR=''
TEST_STATUS=0

test::cleanup() {
    rm -rf -- "${TEST_TMPDIR}"
}
trap test::cleanup EXIT

test::capture() {
    : >"${TEST_STDOUT_FILE}"
    : >"${TEST_STDERR_FILE}"

    "$@" >"${TEST_STDOUT_FILE}" 2>"${TEST_STDERR_FILE}"
    TEST_STATUS=$?
    TEST_STDOUT=$(<"${TEST_STDOUT_FILE}")
    TEST_STDERR=$(<"${TEST_STDERR_FILE}")
}

test::assert_eq() {
    local expected=$1
    local actual=$2
    local context=${3:-values differ}

    if [[ ${actual} != "${expected}" ]]; then
        printf '    %s\n      expected: %q\n      actual:   %q\n' \
            "${context}" "${expected}" "${actual}" >&2
        return 1
    fi
}

test::assert_contains() {
    local haystack=$1
    local needle=$2
    local context=${3:-missing expected text}

    case ${haystack} in
        *"${needle}"*) return 0 ;;
        *)
            printf '    %s\n      needle: %q\n      value:  %q\n' \
                "${context}" "${needle}" "${haystack}" >&2
            return 1
            ;;
    esac
}

test::assert_not_contains() {
    local haystack=$1
    local needle=$2
    local context=${3:-unexpected text found}

    case ${haystack} in
        *"${needle}"*)
            printf '    %s\n      needle: %q\n      value:  %q\n' \
                "${context}" "${needle}" "${haystack}" >&2
            return 1
            ;;
        *) return 0 ;;
    esac
}

test::run() {
    local name=$1
    local function_name=$2
    local details=''
    local status=0

    TEST_TOTAL=$((TEST_TOTAL + 1))
    details=$("${function_name}" 2>&1) || status=$?
    if ((status == 0)); then
        printf 'ok %d - %s\n' "${TEST_TOTAL}" "${name}"
    else
        TEST_FAILED=$((TEST_FAILED + 1))
        printf 'not ok %d - %s\n' "${TEST_TOTAL}" "${name}"
        if [[ -n ${details} ]]; then
            printf '%s\n' "${details}"
        fi
    fi
}

test::finish() {
    printf '\n%d tests, %d failures\n' "${TEST_TOTAL}" "${TEST_FAILED}"
    if ((TEST_FAILED > 0)); then
        return 1
    fi
}
