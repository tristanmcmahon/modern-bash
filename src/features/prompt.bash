#!/usr/bin/env bash

if [[ ${MODERN_BASH_PROMPT_LOADED:-0} == 1 ]]; then
    return 0
fi

MODERN_BASH_PROMPT_LOADED=1
MODERN_BASH_PROMPT_ENABLED=0
MODERN_BASH_PROMPT_ERROR=''
MODERN_BASH_PROMPT_ORIGINAL_PS1_SET=0
MODERN_BASH_PROMPT_ORIGINAL_PS1=''
MODERN_BASH_PROMPT_COMMAND_WAS_ARRAY=0
MODERN_BASH_PROMPT_ORIGINAL_COMMAND=''
MODERN_BASH_PROMPT_ORIGINAL_COMMANDS=()
MODERN_BASH_PROMPT_LAST_STATUS=0
MODERN_BASH_PROMPT_STATUS_SEGMENT=''
MODERN_BASH_PROMPT_CWD=''
MODERN_BASH_PROMPT_GIT_SEGMENT=''
MODERN_BASH_PROMPT_THEME_RESET=''
MODERN_BASH_PROMPT_THEME_INFO=''
MODERN_BASH_PROMPT_THEME_SUCCESS=''
MODERN_BASH_PROMPT_THEME_ERROR=''
MODERN_BASH_PROMPT_THEME_DEBUG=''
MODERN_BASH_PROMPT_UNICODE=0
MODERN_BASH_PROMPT_STYLE_RESET=''
MODERN_BASH_PROMPT_STYLE_INFO=''
MODERN_BASH_PROMPT_STYLE_SUCCESS=''
MODERN_BASH_PROMPT_STYLE_ERROR=''
MODERN_BASH_PROMPT_STYLE_DEBUG=''

modern_bash::prompt::_sanitize() {
    local value=$1

    value=${value//[[:cntrl:]]/?}
    printf '%s' "${value}"
}

modern_bash::prompt::_cwd() {
    local cwd=${PWD:-?}

    if [[ -n ${HOME:-} ]]; then
        case ${cwd} in
            "${HOME}") cwd='~' ;;
            "${HOME}"/*) cwd="~/${cwd#"${HOME}"/}" ;;
        esac
    fi
    modern_bash::prompt::_sanitize "${cwd}"
}

modern_bash::prompt::_git_branch() {
    local branch=''
    local commit=''

    if ! command -v git >/dev/null 2>&1; then
        return 0
    fi

    if branch=$(GIT_OPTIONAL_LOCKS=0 command git symbolic-ref --quiet --short HEAD 2>/dev/null); then
        modern_bash::prompt::_sanitize "${branch}"
    elif commit=$(GIT_OPTIONAL_LOCKS=0 command git rev-parse --short HEAD 2>/dev/null); then
        modern_bash::prompt::_sanitize "@${commit}"
    fi
}

modern_bash::prompt::_style() {
    local ansi=$1

    if [[ -n ${ansi} ]]; then
        printf '\\[%s\\]' "${ansi}"
    fi
}

modern_bash::prompt::_prepare_theme() {
    local saved_capabilities_detected=${MODERN_BASH_CAPABILITIES_DETECTED}
    local saved_cap_fd=${MODERN_BASH_CAP_FD}
    local saved_cap_tty=${MODERN_BASH_CAP_TTY}
    local saved_cap_color_level=${MODERN_BASH_CAP_COLOR_LEVEL}
    local saved_cap_color_source=${MODERN_BASH_CAP_COLOR_SOURCE}
    local saved_cap_unicode=${MODERN_BASH_CAP_UNICODE}
    local saved_cap_hyperlinks=${MODERN_BASH_CAP_HYPERLINKS}
    local saved_cap_columns=${MODERN_BASH_CAP_COLUMNS}
    local saved_theme_initialized=${MODERN_BASH_THEME_INITIALIZED}
    local saved_theme_reset=${MODERN_BASH_THEME_RESET}
    local saved_theme_bold=${MODERN_BASH_THEME_BOLD}
    local saved_theme_dim=${MODERN_BASH_THEME_DIM}
    local saved_theme_info=${MODERN_BASH_THEME_INFO}
    local saved_theme_success=${MODERN_BASH_THEME_SUCCESS}
    local saved_theme_warning=${MODERN_BASH_THEME_WARNING}
    local saved_theme_error=${MODERN_BASH_THEME_ERROR}
    local saved_theme_debug=${MODERN_BASH_THEME_DEBUG}
    local saved_icon_info=${MODERN_BASH_THEME_ICON_INFO}
    local saved_icon_success=${MODERN_BASH_THEME_ICON_SUCCESS}
    local saved_icon_warning=${MODERN_BASH_THEME_ICON_WARNING}
    local saved_icon_error=${MODERN_BASH_THEME_ICON_ERROR}
    local saved_icon_debug=${MODERN_BASH_THEME_ICON_DEBUG}
    local status=0

    modern_bash::capabilities::detect 2 || status=$?
    if ((status == 0)); then
        modern_bash::theme::init || status=$?
    fi
    if ((status == 0)); then
        MODERN_BASH_PROMPT_THEME_RESET=${MODERN_BASH_THEME_RESET}
        MODERN_BASH_PROMPT_THEME_INFO=${MODERN_BASH_THEME_INFO}
        MODERN_BASH_PROMPT_THEME_SUCCESS=${MODERN_BASH_THEME_SUCCESS}
        MODERN_BASH_PROMPT_THEME_ERROR=${MODERN_BASH_THEME_ERROR}
        MODERN_BASH_PROMPT_THEME_DEBUG=${MODERN_BASH_THEME_DEBUG}
        MODERN_BASH_PROMPT_UNICODE=${MODERN_BASH_CAP_UNICODE}
        MODERN_BASH_PROMPT_STYLE_RESET=$(modern_bash::prompt::_style "${MODERN_BASH_PROMPT_THEME_RESET}")
        MODERN_BASH_PROMPT_STYLE_INFO=$(modern_bash::prompt::_style "${MODERN_BASH_PROMPT_THEME_INFO}")
        MODERN_BASH_PROMPT_STYLE_SUCCESS=$(modern_bash::prompt::_style "${MODERN_BASH_PROMPT_THEME_SUCCESS}")
        MODERN_BASH_PROMPT_STYLE_ERROR=$(modern_bash::prompt::_style "${MODERN_BASH_PROMPT_THEME_ERROR}")
        MODERN_BASH_PROMPT_STYLE_DEBUG=$(modern_bash::prompt::_style "${MODERN_BASH_PROMPT_THEME_DEBUG}")
    fi

    MODERN_BASH_CAPABILITIES_DETECTED=${saved_capabilities_detected}
    MODERN_BASH_CAP_FD=${saved_cap_fd}
    MODERN_BASH_CAP_TTY=${saved_cap_tty}
    MODERN_BASH_CAP_COLOR_LEVEL=${saved_cap_color_level}
    MODERN_BASH_CAP_COLOR_SOURCE=${saved_cap_color_source}
    MODERN_BASH_CAP_UNICODE=${saved_cap_unicode}
    MODERN_BASH_CAP_HYPERLINKS=${saved_cap_hyperlinks}
    MODERN_BASH_CAP_COLUMNS=${saved_cap_columns}
    MODERN_BASH_THEME_INITIALIZED=${saved_theme_initialized}
    MODERN_BASH_THEME_RESET=${saved_theme_reset}
    MODERN_BASH_THEME_BOLD=${saved_theme_bold}
    MODERN_BASH_THEME_DIM=${saved_theme_dim}
    MODERN_BASH_THEME_INFO=${saved_theme_info}
    MODERN_BASH_THEME_SUCCESS=${saved_theme_success}
    MODERN_BASH_THEME_WARNING=${saved_theme_warning}
    MODERN_BASH_THEME_ERROR=${saved_theme_error}
    MODERN_BASH_THEME_DEBUG=${saved_theme_debug}
    MODERN_BASH_THEME_ICON_INFO=${saved_icon_info}
    MODERN_BASH_THEME_ICON_SUCCESS=${saved_icon_success}
    MODERN_BASH_THEME_ICON_WARNING=${saved_icon_warning}
    MODERN_BASH_THEME_ICON_ERROR=${saved_icon_error}
    MODERN_BASH_THEME_ICON_DEBUG=${saved_icon_debug}

    return "${status}"
}

modern_bash::prompt::_build_ps1() {
    local status=$1
    local status_style=''
    local cwd_style
    local git_style
    local symbol_style
    local reset_style
    local separator=' '
    local symbol='>'

    cwd_style=${MODERN_BASH_PROMPT_STYLE_INFO}
    git_style=${MODERN_BASH_PROMPT_STYLE_DEBUG}
    symbol_style=${MODERN_BASH_PROMPT_STYLE_SUCCESS}
    reset_style=${MODERN_BASH_PROMPT_STYLE_RESET}

    if [[ ${MODERN_BASH_PROMPT_UNICODE} == 1 ]]; then
        symbol='❯'
    fi
    if ((status == 0)); then
        status_style=${MODERN_BASH_PROMPT_STYLE_SUCCESS}
    else
        status_style=${MODERN_BASH_PROMPT_STYLE_ERROR}
    fi
    if [[ ${MODERN_BASH_PROMPT_MULTILINE} == 1 ]]; then
        separator='\n'
    fi

    # Dynamic text remains in variables and is expanded once by Bash. It is
    # never interpolated into PS1, so branch names and paths cannot inject a
    # second command substitution during prompt expansion.
    PS1="${status_style}"'${MODERN_BASH_PROMPT_STATUS_SEGMENT}'\
"${reset_style}${cwd_style}"'${MODERN_BASH_PROMPT_CWD}'\
"${reset_style}${git_style}"'${MODERN_BASH_PROMPT_GIT_SEGMENT}'\
"${reset_style}${separator}${symbol_style}${symbol}${reset_style} "
}

modern_bash::prompt::render() {
    local status=${1:-0}
    local branch=''

    MODERN_BASH_PROMPT_STATUS_SEGMENT=''
    case ${MODERN_BASH_PROMPT_STATUS} in
        always) MODERN_BASH_PROMPT_STATUS_SEGMENT="[${status}] " ;;
        nonzero)
            if ((status != 0)); then
                MODERN_BASH_PROMPT_STATUS_SEGMENT="[${status}] "
            fi
            ;;
    esac

    MODERN_BASH_PROMPT_CWD=$(modern_bash::prompt::_cwd)
    MODERN_BASH_PROMPT_GIT_SEGMENT=''
    if [[ ${MODERN_BASH_PROMPT_GIT} == 1 ]]; then
        branch=$(modern_bash::prompt::_git_branch)
        if [[ -n ${branch} ]]; then
            MODERN_BASH_PROMPT_GIT_SEGMENT=" (${branch})"
        fi
    fi
    modern_bash::prompt::_build_ps1 "${status}"
}

modern_bash::prompt::update() {
    MODERN_BASH_PROMPT_LAST_STATUS=$?
    modern_bash::prompt::render "${MODERN_BASH_PROMPT_LAST_STATUS}"
    return "${MODERN_BASH_PROMPT_LAST_STATUS}"
}

modern_bash::prompt::capture_status() {
    MODERN_BASH_PROMPT_LAST_STATUS=$?
    return "${MODERN_BASH_PROMPT_LAST_STATUS}"
}

modern_bash::prompt::render_captured() {
    modern_bash::prompt::render "${MODERN_BASH_PROMPT_LAST_STATUS}"
    return "${MODERN_BASH_PROMPT_LAST_STATUS}"
}

modern_bash::prompt::_supports_prompt_command_array() {
    ((BASH_VERSINFO[0] > 5 || (BASH_VERSINFO[0] == 5 && BASH_VERSINFO[1] >= 1)))
}

modern_bash::prompt::_install_hook() {
    local prompt_command_declaration=''
    local declaration_prefix=''
    local original_command=''
    local composed_command=''

    if prompt_command_declaration=$(declare -p PROMPT_COMMAND 2>/dev/null); then
        declaration_prefix=${prompt_command_declaration%% PROMPT_COMMAND=*}
    fi

    case ${declaration_prefix} in
        'declare -'*A*)
            MODERN_BASH_PROMPT_ERROR='associative PROMPT_COMMAND values are not supported'
            return 2
            ;;
        'declare -'*a*)
            MODERN_BASH_PROMPT_COMMAND_WAS_ARRAY=1
            MODERN_BASH_PROMPT_ORIGINAL_COMMANDS=("${PROMPT_COMMAND[@]}")
            if modern_bash::prompt::_supports_prompt_command_array; then
                if ((${#PROMPT_COMMAND[@]} > 0)); then
                    PROMPT_COMMAND=(modern_bash::prompt::capture_status "${PROMPT_COMMAND[@]}" modern_bash::prompt::render_captured)
                else
                    PROMPT_COMMAND=(modern_bash::prompt::update)
                fi
                return
            fi
            original_command=${PROMPT_COMMAND[0]-}
            MODERN_BASH_PROMPT_ORIGINAL_COMMAND=${original_command}
            if [[ -n ${original_command} ]]; then
                composed_command=$'modern_bash::prompt::capture_status\n'"${original_command}"$'\nmodern_bash::prompt::render_captured'
            else
                composed_command='modern_bash::prompt::update'
            fi
            PROMPT_COMMAND[0]=${composed_command}
            return
            ;;
    esac

    MODERN_BASH_PROMPT_COMMAND_WAS_ARRAY=0
    original_command=${PROMPT_COMMAND:-}
    MODERN_BASH_PROMPT_ORIGINAL_COMMAND=${original_command}
    if [[ -n ${original_command} ]]; then
        PROMPT_COMMAND=$'modern_bash::prompt::capture_status\n'"${original_command}"$'\nmodern_bash::prompt::render_captured'
    else
        PROMPT_COMMAND='modern_bash::prompt::update'
    fi
}

modern_bash::prompt::enable() {
    if [[ ${MODERN_BASH_PROMPT_ENABLED} == 1 ]]; then
        return 0
    fi

    MODERN_BASH_PROMPT_ERROR=''
    if ! shopt -q promptvars; then
        MODERN_BASH_PROMPT_ERROR='Bash promptvars must be enabled for the prompt feature'
        return 1
    fi
    if ! modern_bash::prompt::_prepare_theme; then
        MODERN_BASH_PROMPT_ERROR='terminal capability detection failed for the prompt'
        return 1
    fi

    if [[ ${MODERN_BASH_PROMPT_ORIGINAL_PS1_SET} != 1 ]]; then
        MODERN_BASH_PROMPT_ORIGINAL_PS1=${PS1-}
        MODERN_BASH_PROMPT_ORIGINAL_PS1_SET=1
    fi
    if ! modern_bash::prompt::render 0; then
        MODERN_BASH_PROMPT_ERROR='PS1 could not be updated'
        return 1
    fi
    if ! modern_bash::prompt::_install_hook; then
        PS1=${MODERN_BASH_PROMPT_ORIGINAL_PS1}
        MODERN_BASH_PROMPT_ERROR=${MODERN_BASH_PROMPT_ERROR:-PROMPT_COMMAND could not be updated}
        return 1
    fi
    MODERN_BASH_PROMPT_ENABLED=1
}
