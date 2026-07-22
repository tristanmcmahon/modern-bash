# Modern Bash

[![CI](https://github.com/tristanmcmahon/modern-bash/actions/workflows/ci.yml/badge.svg)](https://github.com/tristanmcmahon/modern-bash/actions/workflows/ci.yml)

Modern Bash is a thoughtfully engineered Bash environment for people who spend
a significant part of their day in a terminal. It improves the default Bash
experience while remaining recognisable, predictable, and faithful to Unix
composition.

The runtime supports Bash 3.2 and newer, including the system Bash shipped with
macOS. Terminal styling, Unicode, Git context, and terminfo are enhancements,
never requirements.

## What it provides

- stream-specific terminal capability detection;
- semantic color and symbol themes with plain-text fallbacks;
- output helpers that keep diagnostics separate from pipeline data;
- an idempotent, XDG-aware interactive bootstrap;
- a secure prompt with failure status, working directory, and Git context;
- reversible prompt activation that preserves existing prompt hooks;
- an installation and configuration doctor;
- a managed user-local installer and uninstaller;
- dependency-free tests across Ubuntu's Bash and macOS Bash 3.2.

## Quick start

Clone and install under `~/.local`:

```bash
git clone https://github.com/tristanmcmahon/modern-bash.git
cd modern-bash
make install
```

Make sure the installed command is on `PATH`, then activate it:

```bash
export PATH="$HOME/.local/bin:$PATH"
eval "$(modern-bash init)"
```

For future interactive shells, add those two lines to `~/.bashrc`. The installer
does not edit startup or configuration files for you.

Verify the installation and effective configuration:

```bash
modern-bash doctor
modern-bash doctor --plain
```

`doctor` reports facts about its own process, the installation, config, and
output terminal. A standalone command cannot inspect whether its parent shell
is activated.

### macOS

Modern macOS uses zsh by default; Modern Bash must run inside Bash. Start Bash
with `/bin/bash`. Because Terminal often starts it as a login shell, put this in
`~/.bash_profile` so it also loads `~/.bashrc`:

```bash
if [[ -r "$HOME/.bashrc" ]]; then
    source "$HOME/.bashrc"
fi
```

### Try without installing

From a checkout, either put its `bin` directory on `PATH` or source the
interactive entrypoint directly:

```bash
source /path/to/modern-bash/src/init.bash
```

Non-interactive scripts can source that file safely: it returns before loading
configuration or changing shell state.

## Install, update, and remove

`make install` (or `./bin/modern-bash install` from a source checkout) copies a
managed runtime and documentation tree, then creates
`~/.local/bin/modern-bash` as a relative symlink. Re-running it from an updated
checkout updates the managed installation. It refuses to overwrite an
unrelated launcher or runtime; installing to another prefix also requires a
source checkout.

To update from Git:

```bash
git pull --ff-only
make install
```

Choose another absolute prefix or a packaging staging root when needed:

```bash
make install PREFIX=/opt/modern-bash
make install PREFIX=/usr/local DESTDIR=/tmp/package-root
```

Remove only the managed runtime and documentation:

```bash
modern-bash uninstall
```

`make uninstall` from the checkout is equivalent for the default prefix. Pass
the same settings used at install time for a custom or staged installation:

```bash
make uninstall PREFIX=/opt/modern-bash
make uninstall PREFIX=/usr/local DESTDIR=/tmp/package-root
```

The uninstaller leaves shell startup files and
`~/.config/modern-bash/config.bash` untouched. Remove the activation lines from
`.bashrc` yourself if you no longer want them.

## Configure it

The default configuration path is:

```text
${XDG_CONFIG_HOME}/modern-bash/config.bash
```

When `XDG_CONFIG_HOME` is unset or relative, Modern Bash uses
`~/.config/modern-bash/config.bash`. No file is required; built-in defaults
enable the prompt.

Example:

```bash
# Comma-separated. An empty value disables every feature.
MODERN_BASH_FEATURES=prompt

# Show Git context when Git is available.
MODERN_BASH_PROMPT_GIT=1

# always, nonzero, or never
MODERN_BASH_PROMPT_STATUS=nonzero

# 1 for two lines, 0 for one line
MODERN_BASH_PROMPT_MULTILINE=1
```

The config is trusted Bash, like `.bashrc`. Set `MODERN_BASH_CONFIG_FILE` before
activation to select an explicit path; set it to an empty value to disable
config loading. Open a new shell after changing config.

Activation is idempotent. To restore the prompt state that existed beforehand:

```bash
modern_bash::bootstrap::shutdown
```

Modern Bash refuses to overwrite `PROMPT_COMMAND` during shutdown if another
tool changed it after activation.

See [the configuration reference](docs/configuration.md) for the complete
contract.

## Capability overrides

Color detection follows this precedence:

1. `MODERN_BASH_COLOR=always|never|auto`;
2. the presence of `FORCE_COLOR` (`0` disables, `2` and `3` select richer
   palettes, and any other value enables base ANSI colour);
3. the presence of `NO_COLOR`, including an empty value;
4. automatic output-terminal and terminfo detection.

`MODERN_BASH_UNICODE=always|never|auto` and
`MODERN_BASH_HYPERLINKS=always|never|auto` provide equivalent explicit
controls. Invalid namespaced values are rejected.

## Use the libraries

The sourceable runtime can also support another Bash program:

```bash
source /path/to/modern-bash/src/modern-bash.bash

modern_bash::output::configure 2
modern_bash::output::info "Checking configuration"
modern_bash::output::success "Configuration is valid"

# Pipeline data remains plain and goes to stdout.
modern_bash::output::print "result"
```

Styled output defaults to file descriptor 2. Call
`modern_bash::output::configure FD` to detect capabilities and target another
open stream.

## Develop and validate

Runtime requirements are Bash 3.2 and standard Unix utilities. Git and `tput`
are optional. Development additionally requires ShellCheck.

```bash
make test
make lint
make check
```

`make check` parses every shell file before linting and testing. CI repeats the
suite with Ubuntu's Bash and the macOS `/bin/bash`, which verifies the 3.2
compatibility floor.

Read the [engineering principles](docs/engineering-principles.md),
[contribution guide](CONTRIBUTING.md), and [changelog](CHANGELOG.md) before
expanding the runtime.

## License

No license has been granted; all rights are reserved. A project license still
needs to be selected by the copyright owner.
