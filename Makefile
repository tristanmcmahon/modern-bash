SHELL := bash

# ShellCheck follows each annotated source edge with -x, so these two roots
# cover every runtime and test shell file while preserving cross-file analysis.
SHELLCHECK_ENTRYPOINTS := bin/modern-bash tests/run.sh

.PHONY: check lint test

check: lint test

lint:
	@command -v shellcheck >/dev/null || { echo 'shellcheck is required' >&2; exit 127; }
	shellcheck -x $(SHELLCHECK_ENTRYPOINTS)

test:
	bash tests/run.sh
