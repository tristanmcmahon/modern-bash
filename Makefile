SHELL := bash
BASH ?= bash
ifeq ($(strip $(HOME)),)
PREFIX ?=
else
PREFIX ?= $(HOME)/.local
endif
DESTDIR ?=

SHELL_SOURCES := \
	bin/modern-bash \
	scripts/install.bash \
	$(wildcard src/*.bash src/commands/*.bash src/features/*.bash src/lib/*.bash tests/*.bash)
# These roots source every runtime and test file, allowing ShellCheck to follow
# cross-file globals without reporting each module as an isolated program.
SHELLCHECK_ENTRYPOINTS := bin/modern-bash src/init.bash tests/run.sh scripts/install.bash

.PHONY: check help install lint syntax test uninstall

check: syntax lint test

help:
	@printf '%s\n' \
		'make check      Run syntax checks, ShellCheck, and tests' \
		'make test       Run the dependency-free test suite' \
		'make install    Install under PREFIX (default: $$HOME/.local)' \
		'make uninstall  Remove that installation; preserve user config'

syntax:
	@for shell_file in $(SHELL_SOURCES); do \
		$(BASH) -n "$$shell_file" || exit; \
	done

lint:
	@command -v shellcheck >/dev/null || { echo 'shellcheck is required' >&2; exit 127; }
	shellcheck -x $(SHELLCHECK_ENTRYPOINTS)

test:
	$(BASH) tests/run.sh

install:
	MODERN_BASH_INSTALL_PREFIX="$(PREFIX)" MODERN_BASH_INSTALL_DESTDIR="$(DESTDIR)" \
		$(BASH) scripts/install.bash install

uninstall:
	MODERN_BASH_INSTALL_PREFIX="$(PREFIX)" MODERN_BASH_INSTALL_DESTDIR="$(DESTDIR)" \
		$(BASH) scripts/install.bash uninstall
