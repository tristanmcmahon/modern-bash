#!/usr/bin/env bash

if [[ ${MODERN_BASH_BOOTSTRAP_LOADED:-0} == 1 ]]; then
    return 0
fi

MODERN_BASH_BOOTSTRAP_LOADED=1
MODERN_BASH_INITIALIZED=${MODERN_BASH_INITIALIZED:-0}
MODERN_BASH_INIT_ERROR=''

modern_bash::bootstrap::_enable_feature() {
    local feature_name=$1

    case ${feature_name} in
        prompt)
            if ! modern_bash::prompt::enable; then
                MODERN_BASH_INIT_ERROR=${MODERN_BASH_PROMPT_ERROR:-prompt initialization failed}
                return 1
            fi
            ;;
        *)
            MODERN_BASH_INIT_ERROR="unknown feature: ${feature_name}"
            return 2
            ;;
    esac
}

modern_bash::bootstrap::validate_features() {
    local remaining=${MODERN_BASH_FEATURES}
    local feature_name

    if [[ -z ${remaining} ]]; then
        return 0
    fi

    case ${remaining} in
        ,*|*,|*,,*)
            MODERN_BASH_INIT_ERROR='MODERN_BASH_FEATURES contains an empty feature name'
            return 2
            ;;
    esac

    while [[ -n ${remaining} ]]; do
        case ${remaining} in
            *,*)
                feature_name=${remaining%%,*}
                remaining=${remaining#*,}
                ;;
            *)
                feature_name=${remaining}
                remaining=''
                ;;
        esac

        case ${feature_name} in
            prompt) ;;
            *)
                MODERN_BASH_INIT_ERROR="unknown feature: ${feature_name}"
                return 2
                ;;
        esac
    done
}

modern_bash::bootstrap::feature_enabled() {
    local wanted=$1
    local remaining=${MODERN_BASH_FEATURES}
    local feature_name

    while [[ -n ${remaining} ]]; do
        case ${remaining} in
            *,*)
                feature_name=${remaining%%,*}
                remaining=${remaining#*,}
                ;;
            *)
                feature_name=${remaining}
                remaining=''
                ;;
        esac
        if [[ ${feature_name} == "${wanted}" ]]; then
            return 0
        fi
    done
    return 1
}

modern_bash::bootstrap::_enable_features() {
    local remaining=${MODERN_BASH_FEATURES}
    local feature_name

    modern_bash::bootstrap::validate_features || return
    while [[ -n ${remaining} ]]; do
        case ${remaining} in
            *,*)
                feature_name=${remaining%%,*}
                remaining=${remaining#*,}
                ;;
            *)
                feature_name=${remaining}
                remaining=''
                ;;
        esac
        modern_bash::bootstrap::_enable_feature "${feature_name}" || return
    done
}

modern_bash::bootstrap::initialize() {
    if [[ ${MODERN_BASH_INITIALIZED} == 1 ]]; then
        return 0
    fi

    MODERN_BASH_INIT_ERROR=''
    if ! modern_bash::config::load; then
        MODERN_BASH_INIT_ERROR=${MODERN_BASH_CONFIG_ERROR}
        return 1
    fi
    modern_bash::config::apply_defaults
    if ! modern_bash::config::validate; then
        MODERN_BASH_INIT_ERROR=${MODERN_BASH_CONFIG_ERROR}
        return 2
    fi
    modern_bash::bootstrap::_enable_features || return

    MODERN_BASH_INITIALIZED=1
}
