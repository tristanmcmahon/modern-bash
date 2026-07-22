# Changelog

All notable changes to Modern Bash are recorded here. The project follows
[Semantic Versioning](https://semver.org/) while the public API is developed
toward 1.0.

## Unreleased

## 0.3.0 - 2026-07-22

### Added

- A managed, user-local install, update, and uninstall workflow with `PREFIX`
  and `DESTDIR` support.
- Reversible prompt and bootstrap shutdown APIs.
- Cross-platform GitHub Actions coverage for Ubuntu's Bash and macOS Bash 3.2.
- Installation, symlink, hostile-environment, prompt-lifecycle, and failure-path
  regression tests.

### Changed

- `doctor --plain` now changes presentation without changing the capabilities
  being diagnosed, and distinguishes configured features from active state.
- Git probing avoids a second child process outside repositories.
- Startup path discovery avoids unnecessary `dirname` processes.
- The installer validates every managed path before mutation and preserves
  existing shared-directory modes.
- Switching runtime roots or versions safely tears down an active, owned prompt
  before loading the replacement.

### Fixed

- Symlinked executables now locate the runtime correctly.
- Incomplete installations and inherited internal guard variables fail safely.
- User config scratch variables can no longer corrupt doctor bookkeeping.
- Prompt status preservation no longer amplifies failures through `ERR` traps.
- Prompt status arguments are validated before they can reach arithmetic
  evaluation.
- Sparse `PROMPT_COMMAND` arrays now run every pre-existing hook exactly once.
- Imported function and loader state cannot bypass runtime validation, and
  truncated modules fail closed.
- Install and uninstall reject path traversal and nested directory symlinks.
- Ownership markers remain usable under restrictive inherited umasks.

## 0.2.0 - 2026-07-21

- Added the idempotent interactive bootstrap, XDG configuration, secure Git
  prompt, and activation command.

## 0.1.0 - 2026-07-21

- Added terminal capability detection, semantic themes, composable output,
  engineering principles, the doctor command, and the first test suite.
