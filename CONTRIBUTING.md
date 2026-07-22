# Contributing

Modern Bash is intentionally conservative: it changes an interactive shell, so
predictability and compatibility matter more than cleverness.

## Development setup

Runtime code requires Bash 3.2 or newer and standard Unix tools. Development
also requires [ShellCheck](https://www.shellcheck.net/).

Run the complete local gate before submitting a change:

```bash
make check
```

`make check` parses every shell file, runs ShellCheck across the complete source
graph, and executes the dependency-free test suite. To select another Bash:

```bash
make test BASH=/path/to/bash
```

## Change guidelines

- Preserve Bash 3.2 compatibility unless a compatibility change is discussed
  explicitly.
- Keep data on stdout and diagnostics on stderr.
- Treat paths, Git refs, environment values, and prompt data as untrusted.
- Do not add a required runtime dependency for an optional enhancement.
- Add deterministic regression tests for every public behavior and bug fix.
- Update the README, configuration reference, and changelog when their contract
  changes.

Use focused commits with imperative messages. Do not include editor state,
credentials, generated files, or unrelated cleanup.
