#!/usr/bin/env bash

install_test::installer() {
    "${BASH}" "${PROJECT_ROOT}/scripts/install.bash" "$@"
}

install_test::installer_with_restrictive_umask() {
    umask 0777
    install_test::installer "$@"
}

install_test::activate_installed() {
    local launcher=$1
    local activation=''

    activation=$("${BASH}" "${launcher}" init) || return
    MODERN_BASH_CONFIG_FILE='' \
        MODERN_BASH_COLOR=never \
        MODERN_BASH_UNICODE=never \
        "${BASH}" --noprofile --norc -i -c \
        "${activation}; printf 'active=%s prompt=%s' \"\${MODERN_BASH_INITIALIZED}\" \"\${MODERN_BASH_PROMPT_ENABLED}\""
}

test_managed_install_update_activation_and_uninstall() {
    local prefix="${TEST_TMPDIR}/prefix \$(false) with spaces ' 100%"
    local launcher=${prefix}/bin/modern-bash
    local runtime=${prefix}/lib/modern-bash
    local doc_root=${prefix}/share/doc/modern-bash
    local config_file=${TEST_TMPDIR}/preserved-config/config.bash
    local link_target=''

    mkdir -p "${config_file%/*}" || return
    printf '%s\n' '# preserve me' >"${config_file}"

    test::capture "${BASH}" "${PROJECT_ROOT}/bin/modern-bash" install --prefix "${prefix}"
    test::assert_eq 0 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDOUT}" 'Installed Modern Bash' || return
    test::assert_eq '' "${TEST_STDERR}" || return
    [[ -x ${launcher} ]] || { printf '    installed launcher is not executable\n' >&2; return 1; }
    [[ -r ${runtime}/src/init.bash ]] || { printf '    installed init is missing\n' >&2; return 1; }
    [[ -r ${prefix}/share/doc/modern-bash/README.md ]] || {
        printf '    installed documentation is missing\n' >&2
        return 1
    }
    link_target=$(readlink "${launcher}") || return
    test::assert_eq '../lib/modern-bash/bin/modern-bash' "${link_target}" || return

    test::capture "${BASH}" "${launcher}" --version
    test::assert_eq 0 "${TEST_STATUS}" || return
    test::assert_eq 'modern-bash 0.3.0' "${TEST_STDOUT}" || return
    test::assert_eq '' "${TEST_STDERR}" || return

    test::capture install_test::activate_installed "${launcher}"
    test::assert_eq 0 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDOUT}" 'active=1 prompt=1' || return

    test::capture "${BASH}" "${launcher}" install
    test::assert_eq 0 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDOUT}" 'already installed' || return

    # Updating an installation owned by this installer is intentionally safe.
    test::capture install_test::installer install --prefix "${prefix}"
    test::assert_eq 0 "${TEST_STATUS}" || return

    test::capture "${BASH}" "${launcher}" uninstall
    test::assert_eq 0 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDOUT}" 'Configuration and shell startup files were left unchanged.' || return
    if [[ -e ${launcher} || -h ${launcher} || -e ${runtime} || -h ${runtime} ||
        -e ${doc_root} || -h ${doc_root} ]]; then
        printf '    uninstall left managed files behind\n' >&2
        return 1
    fi
    [[ -r ${config_file} ]] || { printf '    uninstall removed user configuration\n' >&2; return 1; }
}

test_installer_supports_destdir_staging() {
    local stage="${TEST_TMPDIR}/package stage"
    local prefix='/opt/modern bash'
    local staged_prefix=${stage}${prefix}
    local launcher=${staged_prefix}/bin/modern-bash

    test::capture install_test::installer install --prefix "${prefix}" --destdir "${stage}"
    test::assert_eq 0 "${TEST_STATUS}" || return
    test::assert_not_contains "${TEST_STDOUT}" 'Add /opt/modern bash/bin to PATH' || return
    test::capture "${BASH}" "${launcher}" version
    test::assert_eq 0 "${TEST_STATUS}" || return
    test::assert_eq 'modern-bash 0.3.0' "${TEST_STDOUT}" || return

    test::capture install_test::installer uninstall --prefix "${prefix}" --destdir "${stage}"
    test::assert_eq 0 "${TEST_STATUS}"
}

test_installer_allows_symlinks_above_destdir_boundary() {
    local real_parent=${TEST_TMPDIR}/real-staging-parent
    local linked_parent=${TEST_TMPDIR}/linked-staging-parent
    local destdir=${linked_parent}/package-root
    local installed_launcher=${real_parent}/package-root/opt/modern-bash/bin/modern-bash

    mkdir -p "${real_parent}" || return
    command ln -s "${real_parent}" "${linked_parent}" || return

    test::capture install_test::installer install \
        --prefix /opt/modern-bash --destdir "${destdir}"
    test::assert_eq 0 "${TEST_STATUS}" || return
    [[ -x ${installed_launcher} ]] || {
        printf '    installer did not follow the staging-root ancestor safely\n' >&2
        return 1
    }

    test::capture install_test::installer uninstall \
        --prefix /opt/modern-bash --destdir "${destdir}"
    test::assert_eq 0 "${TEST_STATUS}" || return
    [[ ! -e ${installed_launcher} && ! -h ${installed_launcher} ]]
}

test_installer_rejects_symlink_components_below_destdir() {
    local destdir=${TEST_TMPDIR}/contained-stage
    local external_root=${TEST_TMPDIR}/external-stage-target

    mkdir -p "${destdir}" "${external_root}/usr" || return
    command ln -s "${external_root}/usr" "${destdir}/usr" || return

    test::capture install_test::installer install \
        --prefix /usr/local --destdir "${destdir}"
    test::assert_eq 1 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDERR}" \
        'refusing to follow a directory symlink' || return
    if [[ -e ${external_root}/usr/local || -h ${external_root}/usr/local ]]; then
        printf '    staged install escaped through a prefix-component symlink\n' >&2
        return 1
    fi
}

test_uninstaller_rejects_symlink_components_below_destdir() {
    local destdir=${TEST_TMPDIR}/contained-uninstall-stage
    local external_root=${TEST_TMPDIR}/external-uninstall-target
    local external_launcher=${external_root}/usr/local/bin/modern-bash

    install_test::installer install --prefix /usr/local --destdir "${destdir}" \
        >/dev/null || return
    mkdir -p "${external_root}" || return
    command mv "${destdir}/usr" "${external_root}/usr" || return
    command ln -s "${external_root}/usr" "${destdir}/usr" || return

    test::capture install_test::installer uninstall \
        --prefix /usr/local --destdir "${destdir}"
    test::assert_eq 1 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDERR}" \
        'refusing to follow a directory symlink' || return
    [[ -x ${external_launcher} ]] || {
        printf '    staged uninstall followed a prefix-component symlink\n' >&2
        return 1
    }
}

test_installer_markers_ignore_restrictive_umask() {
    local prefix=${TEST_TMPDIR}/restrictive-umask-prefix
    local runtime_marker=${prefix}/lib/modern-bash/.modern-bash-install
    local doc_marker=${prefix}/share/doc/modern-bash/.modern-bash-install

    test::capture install_test::installer_with_restrictive_umask \
        install --prefix "${prefix}"
    test::assert_eq 0 "${TEST_STATUS}" || return
    [[ -r ${runtime_marker} && -w ${runtime_marker} && \
        -r ${doc_marker} && -w ${doc_marker} ]] || {
        printf '    ownership markers are not readable and writable by their owner\n' >&2
        return 1
    }

    test::capture install_test::installer_with_restrictive_umask \
        install --prefix "${prefix}"
    test::assert_eq 0 "${TEST_STATUS}" || return
    test::capture install_test::installer_with_restrictive_umask \
        uninstall --prefix "${prefix}"
    test::assert_eq 0 "${TEST_STATUS}"
}

test_installed_runtime_requires_checkout_for_another_prefix() {
    local source_prefix=${TEST_TMPDIR}/managed-install-source
    local target_prefix=${TEST_TMPDIR}/managed-install-target
    local launcher=${source_prefix}/bin/modern-bash

    install_test::installer install --prefix "${source_prefix}" >/dev/null || return
    test::capture "${BASH}" "${launcher}" install --prefix "${target_prefix}"
    test::assert_eq 1 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDERR}" \
        'installing to a different prefix requires a source checkout' || return
    if [[ -e ${target_prefix} || -h ${target_prefix} ]]; then
        printf '    rejected cross-prefix install changed the target\n' >&2
        return 1
    fi
}

test_installer_refuses_unmanaged_launcher() {
    local prefix=${TEST_TMPDIR}/collision-prefix
    local launcher=${prefix}/bin/modern-bash

    mkdir -p "${prefix}/bin" || return
    printf '%s\n' 'do not replace' >"${launcher}"
    test::capture install_test::installer install --prefix "${prefix}"
    test::assert_eq 1 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDERR}" 'refusing to replace an unmanaged path' || return
    test::assert_eq 'do not replace' "$(<"${launcher}")"
}

test_installer_rejects_relative_prefix() {
    test::capture install_test::installer install --prefix relative/path
    test::assert_eq 64 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDERR}" '--prefix must be an absolute path'
}

test_installer_rejects_parent_path_components() {
    test::capture install_test::installer install --prefix /opt/../tmp/modern-bash
    test::assert_eq 64 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDERR}" 'must not contain . or .. path components'
}

test_installer_preserves_existing_bin_mode() {
    local prefix=${TEST_TMPDIR}/mode-prefix
    local before_mode=''
    local after_mode=''

    mkdir -p "${prefix}/bin" || return
    chmod 0700 "${prefix}/bin" || return
    before_mode=$(LC_ALL=C command ls -ld "${prefix}/bin") || return
    before_mode=${before_mode%% *}
    install_test::installer install --prefix "${prefix}" >/dev/null || return
    after_mode=$(LC_ALL=C command ls -ld "${prefix}/bin") || return
    after_mode=${after_mode%% *}
    test::assert_eq "${before_mode}" "${after_mode}"
}

test_installer_rejects_nested_runtime_symlinks() {
    local prefix=${TEST_TMPDIR}/runtime-symlink-prefix
    local runtime=${prefix}/lib/modern-bash
    local launcher=${prefix}/bin/modern-bash
    local external_dir=${TEST_TMPDIR}/external-runtime-lib

    install_test::installer install --prefix "${prefix}" >/dev/null || return
    command mv "${runtime}/src/lib" "${runtime}/src/lib.original" || return
    mkdir -p "${external_dir}" || return
    printf '%s\n' 'external sentinel' >"${external_dir}/capabilities.bash"
    command ln -s "${external_dir}" "${runtime}/src/lib" || return

    test::capture install_test::installer install --prefix "${prefix}"
    test::assert_eq 1 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDERR}" 'refusing to follow a directory symlink' || return
    test::assert_eq 'external sentinel' "$(<"${external_dir}/capabilities.bash")" || return

    test::capture install_test::installer uninstall --prefix "${prefix}"
    test::assert_eq 1 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDERR}" 'refusing to follow a directory symlink' || return
    test::assert_eq 'external sentinel' "$(<"${external_dir}/capabilities.bash")" || return
    [[ -h ${launcher} ]] || { printf '    rejected uninstall removed the launcher\n' >&2; return 1; }
}

test_installer_rejects_nested_documentation_symlinks() {
    local prefix=${TEST_TMPDIR}/documentation-symlink-prefix
    local doc_root=${prefix}/share/doc/modern-bash
    local launcher=${prefix}/bin/modern-bash
    local external_dir=${TEST_TMPDIR}/external-docs

    install_test::installer install --prefix "${prefix}" >/dev/null || return
    command mv "${doc_root}/docs" "${doc_root}/docs.original" || return
    mkdir -p "${external_dir}" || return
    printf '%s\n' 'external documentation' >"${external_dir}/configuration.md"
    command ln -s "${external_dir}" "${doc_root}/docs" || return

    test::capture install_test::installer uninstall --prefix "${prefix}"
    test::assert_eq 1 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDERR}" 'refusing to follow a directory symlink' || return
    test::assert_eq 'external documentation' "$(<"${external_dir}/configuration.md")" || return
    [[ -h ${launcher} ]] || { printf '    rejected uninstall removed the launcher\n' >&2; return 1; }
}

test_uninstall_is_safe_with_failglob() {
    local prefix=${TEST_TMPDIR}/failglob-prefix
    local launcher=${prefix}/bin/modern-bash
    local runtime=${prefix}/lib/modern-bash
    local doc_root=${prefix}/share/doc/modern-bash

    install_test::installer install --prefix "${prefix}" >/dev/null || return
    test::capture "${BASH}" -O failglob "${PROJECT_ROOT}/scripts/install.bash" \
        uninstall --prefix "${prefix}"
    test::assert_eq 0 "${TEST_STATUS}" || return
    if [[ -e ${launcher} || -h ${launcher} || -e ${runtime} || -h ${runtime} ||
        -e ${doc_root} || -h ${doc_root} ]]; then
        printf '    failglob uninstall left managed files behind\n' >&2
        return 1
    fi
}

test_cli_can_uninstall_a_damaged_runtime() {
    local prefix=${TEST_TMPDIR}/damaged-runtime-prefix
    local launcher=${prefix}/bin/modern-bash
    local runtime=${prefix}/lib/modern-bash

    install_test::installer install --prefix "${prefix}" >/dev/null || return
    : >"${runtime}/src/lib/theme.bash"
    test::capture "${BASH}" "${launcher}" uninstall
    test::assert_eq 0 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDOUT}" 'Uninstalled Modern Bash' || return
    if [[ -e ${launcher} || -h ${launcher} || -e ${runtime} || -h ${runtime} ]]; then
        printf '    recovery uninstall left the damaged runtime behind\n' >&2
        return 1
    fi
}

test_cli_reports_incomplete_runtime_once() {
    local broken_root=${TEST_TMPDIR}/broken-cli

    mkdir -p "${broken_root}/bin" || return
    cp "${PROJECT_ROOT}/bin/modern-bash" "${broken_root}/bin/modern-bash" || return
    chmod +x "${broken_root}/bin/modern-bash"
    test::capture "${BASH}" "${broken_root}/bin/modern-bash" --version
    test::assert_eq 1 "${TEST_STATUS}" || return
    test::assert_eq '' "${TEST_STDOUT}" || return
    test::assert_contains "${TEST_STDERR}" 'installation is incomplete' || return
    test::assert_not_contains "${TEST_STDERR}" 'unbound variable'
}

test_uninstall_preserves_unmanaged_runtime_files() {
    local prefix=${TEST_TMPDIR}/extended-runtime
    local runtime=${prefix}/lib/modern-bash

    install_test::installer install --prefix "${prefix}" >/dev/null || return
    printf '%s\n' 'keep me' >"${runtime}/custom-file"
    test::capture install_test::installer uninstall --prefix "${prefix}"
    test::assert_eq 1 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDERR}" 'runtime contains unmanaged files' || return
    test::assert_eq 'keep me' "$(<"${runtime}/custom-file")"
}

test_uninstall_preserves_unmanaged_documentation_files() {
    local prefix=${TEST_TMPDIR}/extended-documentation
    local doc_root=${prefix}/share/doc/modern-bash

    install_test::installer install --prefix "${prefix}" >/dev/null || return
    printf '%s\n' 'keep this documentation' >"${doc_root}/custom-file"
    test::capture install_test::installer uninstall --prefix "${prefix}"
    test::assert_eq 1 "${TEST_STATUS}" || return
    test::assert_contains "${TEST_STDERR}" 'documentation contains unmanaged files' || return
    test::assert_eq 'keep this documentation' "$(<"${doc_root}/custom-file")"
}

test::run 'managed install, update, activation, and uninstall work' test_managed_install_update_activation_and_uninstall
test::run 'installer supports DESTDIR staging' test_installer_supports_destdir_staging
test::run 'installer allows symlinks above the DESTDIR boundary' test_installer_allows_symlinks_above_destdir_boundary
test::run 'installer rejects symlink components below DESTDIR' test_installer_rejects_symlink_components_below_destdir
test::run 'uninstaller rejects symlink components below DESTDIR' test_uninstaller_rejects_symlink_components_below_destdir
test::run 'installer markers survive a restrictive umask' test_installer_markers_ignore_restrictive_umask
test::run 'installed runtimes require a checkout for another prefix' test_installed_runtime_requires_checkout_for_another_prefix
test::run 'installer refuses an unmanaged launcher' test_installer_refuses_unmanaged_launcher
test::run 'installer rejects a relative prefix' test_installer_rejects_relative_prefix
test::run 'installer rejects parent path components' test_installer_rejects_parent_path_components
test::run 'installer preserves an existing bin directory mode' test_installer_preserves_existing_bin_mode
test::run 'installer rejects nested runtime symlinks safely' test_installer_rejects_nested_runtime_symlinks
test::run 'installer rejects nested documentation symlinks safely' test_installer_rejects_nested_documentation_symlinks
test::run 'uninstall is safe with failglob inherited' test_uninstall_is_safe_with_failglob
test::run 'CLI can uninstall a damaged managed runtime' test_cli_can_uninstall_a_damaged_runtime
test::run 'CLI reports an incomplete runtime cleanly' test_cli_reports_incomplete_runtime_once
test::run 'uninstall preserves unmanaged runtime files' test_uninstall_preserves_unmanaged_runtime_files
test::run 'uninstall preserves unmanaged documentation files' test_uninstall_preserves_unmanaged_documentation_files
