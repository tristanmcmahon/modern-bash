# Modern Bash

Modern Bash is a thoughtfully engineered Bash environment for people who spend
a significant part of their day in a terminal.

It improves the default Bash experience while remaining recognisable,
predictable, and faithful to traditional Unix behaviour.

## What is here

This initial foundation provides:

- stream-specific terminal capability detection;
- semantic colour and symbol themes with automatic plain-text fallbacks;
- composable output helpers that keep diagnostics separate from pipeline data;
- a `doctor` command for inspecting the active Bash and terminal environment;
- a dependency-free Bash test suite.

The sourceable API supports Bash 3.2 and newer. Optional terminal features are
enhancements, never requirements.

## Try it

```bash
./bin/modern-bash doctor
./bin/modern-bash doctor --plain
```

To use the libraries in another Bash script:

```bash
source /path/to/modern-bash/src/modern-bash.bash

modern_bash::output::configure 2
modern_bash::output::info "Checking configuration"
modern_bash::output::success "Configuration is valid"

# Plain values intended for a pipeline always go to stdout.
modern_bash::output::print "result"
```

Styled output defaults to file descriptor 2. Call
`modern_bash::output::configure FD` to detect capabilities and target a
different stream.

## Capability overrides

Detection follows this precedence:

1. `MODERN_BASH_COLOR=always|never|auto`;
2. `FORCE_COLOR=0|1|2|3` (`1`, `2`, and `3` mean ANSI, 256-colour, and
   truecolour respectively);
3. the presence of `NO_COLOR`;
4. automatic TTY and terminal detection.

`MODERN_BASH_UNICODE=always|never|auto` and
`MODERN_BASH_HYPERLINKS=always|never|auto` provide equivalent explicit
controls for those features. Invalid namespaced override values are rejected.

## Validate

The tests require only Bash and standard Unix utilities:

```bash
make test
```

ShellCheck is the development-time lint dependency:

```bash
make lint
make check
```

The design constraints behind these choices are recorded in
[`docs/engineering-principles.md`](docs/engineering-principles.md).
