# Configuration

Modern Bash works without a configuration file. The default feature set is the
prompt, with Git detection enabled, non-zero exit statuses shown, and a
two-line layout.

## Activation

Add this to `.bashrc` when the `modern-bash` executable is on `PATH`:

```bash
eval "$(modern-bash init)"
```

`modern-bash init` only prints a safely quoted source statement. The sourced
entrypoint checks for an interactive shell before loading any other file, and
repeated activation in the same shell is a no-op.

## Path resolution

The first applicable location wins:

1. `MODERN_BASH_CONFIG_FILE`, including an empty value to disable loading;
2. `$XDG_CONFIG_HOME/modern-bash/config.bash` when `XDG_CONFIG_HOME` is an
   absolute path;
3. `$HOME/.config/modern-bash/config.bash`.

A missing file is normal and activates built-in defaults. A path that exists
but is not a readable regular file is an initialization error.

The file is sourced as trusted Bash in the interactive shell. This makes
configuration flexible, but it should be protected with the same care as
`.bashrc`.

## Features

`MODERN_BASH_FEATURES` is a comma-separated list with no whitespace. The only
current feature is `prompt`:

```bash
MODERN_BASH_FEATURES=prompt
```

Disable all feature modules while retaining the bootstrap and libraries:

```bash
MODERN_BASH_FEATURES=
```

Unknown names and empty entries such as `prompt,,other` are rejected rather
than silently ignored.

## Prompt

The prompt contains the previous command's failure status, an abbreviated
working directory, an optional Git branch or detached commit, and a prompt
symbol. It automatically follows terminal colour and Unicode capabilities.

Available settings:

| Variable | Values | Default | Meaning |
| --- | --- | --- | --- |
| `MODERN_BASH_PROMPT_GIT` | `0`, `1` | `1` | Show Git context when available |
| `MODERN_BASH_PROMPT_STATUS` | `always`, `nonzero`, `never` | `nonzero` | Choose when exit status is shown |
| `MODERN_BASH_PROMPT_MULTILINE` | `0`, `1` | `1` | Select one-line or two-line layout |

Modern Bash composes idempotently around an existing `PROMPT_COMMAND`, capturing
status before it and rendering the Modern Bash prompt afterward. It saves the
original `PS1` in `MODERN_BASH_PROMPT_ORIGINAL_PS1` for inspection.

The standard Bash `promptvars` shell option must remain enabled. Modern Bash
reports an initialization error instead of silently changing that option.

Paths and branch names remain behind static variable references in `PS1` and
terminal control characters are replaced. This prevents dynamic repository or
directory names from becoming executable prompt substitutions.

## Diagnose configuration

Run:

```bash
modern-bash doctor
```

The doctor verifies the interactive entrypoint, resolves and loads the
effective config in its isolated process, validates settings and feature names,
and reports optional Git availability. A missing config or Git executable is
not a failure.
