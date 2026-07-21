#!/usr/bin/env bash

if [[ ${MODERN_BASH_DOCTOR_LOADED:-0} == 1 ]]; then
    return 0
fi

MODERN_BASH_DOCTOR_LOADED=1

modern_bash::doctor::usage() {
    cat <<'USAGE'
Usage: modern-bash doctor [--plain]

Inspect Bash, interactive setup, configuration, and terminal capabilities.

Options:
  --plain       Use ASCII labels and no ANSI styling
  -h, --help    Show this help
USAGE
}

modern_bash::doctor::_version_supported() {
    ((BASH_VERSINFO[0] > 3 || (BASH_VERSINFO[0] == 3 && BASH_VERSINFO[1] >= 2)))
}

modern_bash::doctor::_yes_no() {
    if (($1 == 1)); then
        printf 'yes\n'
    else
        printf 'no\n'
    fi
}

modern_bash::doctor::run() (
    local option
    local failures=0
    local shell_mode=non-interactive
    local tty_description
    local color_description
    local unicode_description
    local hyperlink_description
    local tput_path=''
    local git_path=''
    local init_path=${MODERN_BASH_SOURCE_DIR}/init.bash

    while (($# > 0)); do
        option=$1
        shift
        case ${option} in
            --plain)
                MODERN_BASH_COLOR=never
                MODERN_BASH_UNICODE=never
                ;;
            -h|--help)
                modern_bash::doctor::usage
                return 0
                ;;
            *)
                printf 'modern-bash doctor: unknown option: %s\n' "${option}" >&2
                return 64
                ;;
        esac
    done

    if ! modern_bash::output::configure 1; then
        printf 'modern-bash doctor: invalid capability override\n' >&2
        return 64
    fi

    modern_bash::output::heading 'Modern Bash doctor'
    modern_bash::output::line

    if modern_bash::doctor::_version_supported; then
        modern_bash::output::success "Bash: ${BASH_VERSION} (supported; minimum 3.2)"
    else
        modern_bash::output::error "Bash: ${BASH_VERSION} (3.2 or newer is required)"
        failures=$((failures + 1))
    fi

    case $- in
        *i*) shell_mode=interactive ;;
    esac
    modern_bash::output::info "Shell mode: ${shell_mode}"

    tty_description=$(modern_bash::doctor::_yes_no "${MODERN_BASH_CAP_TTY}")
    modern_bash::output::info "Output is a terminal: ${tty_description} (fd ${MODERN_BASH_CAP_FD})"

    color_description=$(modern_bash::capabilities::color_name)
    modern_bash::output::info "Colour: ${color_description} (${MODERN_BASH_CAP_COLOR_SOURCE})"

    unicode_description=$(modern_bash::doctor::_yes_no "${MODERN_BASH_CAP_UNICODE}")
    modern_bash::output::info "UTF-8 symbols: ${unicode_description}"

    hyperlink_description=$(modern_bash::doctor::_yes_no "${MODERN_BASH_CAP_HYPERLINKS}")
    modern_bash::output::info "Terminal hyperlinks: ${hyperlink_description}"
    modern_bash::output::info "Terminal width: ${MODERN_BASH_CAP_COLUMNS} columns"
    modern_bash::output::info "TERM: ${TERM:-unset}"

    if tput_path=$(command -v tput 2>/dev/null); then
        modern_bash::output::success "Optional dependency tput: ${tput_path}"
    else
        modern_bash::output::info 'Optional dependency tput: unavailable (fallbacks active)'
    fi

    if [[ -f ${init_path} && -r ${init_path} ]]; then
        modern_bash::output::success "Interactive init: ${init_path}"
    else
        modern_bash::output::error "Interactive init: unavailable at ${init_path}"
        failures=$((failures + 1))
    fi

    if modern_bash::config::load; then
        modern_bash::config::apply_defaults
        if modern_bash::config::validate && modern_bash::bootstrap::validate_features; then
            if [[ ${MODERN_BASH_CONFIG_FOUND} == 1 ]]; then
                modern_bash::output::success "Configuration: ${MODERN_BASH_CONFIG_PATH}"
            elif [[ -n ${MODERN_BASH_CONFIG_PATH} ]]; then
                modern_bash::output::info "Configuration: ${MODERN_BASH_CONFIG_PATH} (not present; defaults active)"
            else
                modern_bash::output::info 'Configuration: disabled; defaults active'
            fi

            if modern_bash::bootstrap::feature_enabled prompt; then
                modern_bash::output::success 'Prompt feature: enabled'
            else
                modern_bash::output::info 'Prompt feature: disabled'
            fi
        else
            modern_bash::output::error "Configuration: ${MODERN_BASH_CONFIG_ERROR:-${MODERN_BASH_INIT_ERROR}}"
            failures=$((failures + 1))
        fi
    else
        modern_bash::output::error "Configuration: ${MODERN_BASH_CONFIG_ERROR}"
        failures=$((failures + 1))
    fi

    if git_path=$(command -v git 2>/dev/null); then
        modern_bash::output::success "Optional dependency git: ${git_path}"
    else
        modern_bash::output::info 'Optional dependency git: unavailable (Git prompt segment disabled)'
    fi

    modern_bash::output::line
    if ((failures == 0)); then
        modern_bash::output::success 'Summary: ready (0 failures)'
    else
        modern_bash::output::error "Summary: ${failures} failure(s)"
        return 1
    fi
)
