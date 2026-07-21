#!/usr/bin/env bash

if [[ ${MODERN_BASH_CONFIG_LOADER_LOADED:-0} == 1 ]]; then
    return 0
fi

MODERN_BASH_CONFIG_LOADER_LOADED=1
MODERN_BASH_CONFIG_LOADED=0
MODERN_BASH_CONFIG_FOUND=0
MODERN_BASH_CONFIG_PATH=''
MODERN_BASH_CONFIG_ERROR=''

modern_bash::config::resolve() {
    local config_path=''

    if [[ ${MODERN_BASH_CONFIG_FILE+x} == x ]]; then
        config_path=${MODERN_BASH_CONFIG_FILE}
    elif [[ ${XDG_CONFIG_HOME:-} == /* ]]; then
        config_path=${XDG_CONFIG_HOME}/modern-bash/config.bash
    elif [[ -n ${HOME:-} ]]; then
        config_path=${HOME}/.config/modern-bash/config.bash
    fi

    MODERN_BASH_CONFIG_PATH=${config_path}
}

modern_bash::config::load() {
    if [[ ${MODERN_BASH_CONFIG_LOADED} == 1 ]]; then
        return 0
    fi

    MODERN_BASH_CONFIG_ERROR=''
    MODERN_BASH_CONFIG_FOUND=0
    modern_bash::config::resolve

    if [[ -z ${MODERN_BASH_CONFIG_PATH} ]]; then
        MODERN_BASH_CONFIG_LOADED=1
        return 0
    fi

    if [[ ! -e ${MODERN_BASH_CONFIG_PATH} ]]; then
        MODERN_BASH_CONFIG_LOADED=1
        return 0
    fi

    if [[ ! -f ${MODERN_BASH_CONFIG_PATH} || ! -r ${MODERN_BASH_CONFIG_PATH} ]]; then
        MODERN_BASH_CONFIG_ERROR="configuration is not a readable regular file: ${MODERN_BASH_CONFIG_PATH}"
        return 1
    fi

    # The config file is trusted user-authored Bash, like .bashrc itself.
    # shellcheck disable=SC1090
    if ! source "${MODERN_BASH_CONFIG_PATH}"; then
        MODERN_BASH_CONFIG_ERROR="configuration returned an error: ${MODERN_BASH_CONFIG_PATH}"
        return 1
    fi

    MODERN_BASH_CONFIG_FOUND=1
    MODERN_BASH_CONFIG_LOADED=1
}

modern_bash::config::apply_defaults() {
    if [[ ${MODERN_BASH_FEATURES+x} != x ]]; then
        MODERN_BASH_FEATURES=prompt
    fi
    if [[ ${MODERN_BASH_PROMPT_GIT+x} != x ]]; then
        MODERN_BASH_PROMPT_GIT=1
    fi
    if [[ ${MODERN_BASH_PROMPT_STATUS+x} != x ]]; then
        MODERN_BASH_PROMPT_STATUS=nonzero
    fi
    if [[ ${MODERN_BASH_PROMPT_MULTILINE+x} != x ]]; then
        MODERN_BASH_PROMPT_MULTILINE=1
    fi
}

modern_bash::config::validate() {
    case ${MODERN_BASH_PROMPT_GIT} in
        0|1) ;;
        *)
            MODERN_BASH_CONFIG_ERROR='MODERN_BASH_PROMPT_GIT must be 0 or 1'
            return 2
            ;;
    esac

    case ${MODERN_BASH_PROMPT_STATUS} in
        always|never|nonzero) ;;
        *)
            MODERN_BASH_CONFIG_ERROR='MODERN_BASH_PROMPT_STATUS must be always, never, or nonzero'
            return 2
            ;;
    esac

    case ${MODERN_BASH_PROMPT_MULTILINE} in
        0|1) ;;
        *)
            MODERN_BASH_CONFIG_ERROR='MODERN_BASH_PROMPT_MULTILINE must be 0 or 1'
            return 2
            ;;
    esac
}
