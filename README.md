# Modern Bash

Modern Bash is a thoughtfully engineered Bash environment for people who spend
a significant part of their day in a terminal.

It improves the default Bash experience while remaining recognisable,
predictable, and faithful to traditional Unix behaviour.

## What is here

Modern Bash currently provides:

- stream-specific terminal capability detection;
- semantic colour and symbol themes with automatic plain-text fallbacks;
- composable output helpers that keep diagnostics separate from pipeline data;
- an idempotent interactive bootstrap with XDG-aware configuration;
- a prompt showing failures, the working directory, and the current Git branch;
- a `doctor` command for inspecting the active Bash and terminal environment;
- a dependency-free Bash test suite.

The sourceable API supports Bash 3.2 and newer. Optional terminal features are
enhancements, never requirements.

## Activate it

With `bin/` on your `PATH`, try Modern Bash in the current interactive shell:

```bash
eval "$(modern-bash init)"
```

To activate it for future shells, add that same line to `~/.bashrc`. The command
prints one safely quoted `source` statement for this checkout's `src/init.bash`.
You can use the direct form instead:

```bash
source /path/to/modern-bash/src/init.bash
```

Initialization is idempotent. If `init.bash` is sourced by a non-interactive
script, it returns immediately without loading configuration or producing
output.

Inspect the resulting environment with:

```bash
modern-bash doctor
modern-bash doctor --plain
```

## Configure it

The default configuration path is:

```text
${XDG_CONFIG_HOME}/modern-bash/config.bash
```

When `XDG_CONFIG_HOME` is unset or relative, Modern Bash uses
`~/.config/modern-bash/config.bash`. No file is required; the built-in defaults
enable the prompt.

Example configuration:

```bash
# The list is comma-separated. An empty value disables all features.
MODERN_BASH_FEATURES=prompt

# Show Git branches when Git is available.
MODERN_BASH_PROMPT_GIT=1

# always, nonzero, or never
MODERN_BASH_PROMPT_STATUS=nonzero

# 1 for a two-line prompt, 0 for a single line
MODERN_BASH_PROMPT_MULTILINE=1
```

The configuration file is trusted Bash, like `.bashrc`. Set
`MODERN_BASH_CONFIG_FILE` before activation to select an explicit path; set it
to an empty value to disable configuration loading. See
[`docs/configuration.md`](docs/configuration.md) for the complete contract.

## Use the libraries

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
