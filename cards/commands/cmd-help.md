---
id: cmd-help
title: uv help — display documentation and navigate the CLI
category: commands
tags: [command, troubleshooting]
source: https://docs.astral.sh/uv/getting-started/help/
related: [cmd-run, cmd-init, cmd-version, ts-verbose-debugging, cmd-self]
---

## Summary

`uv help` displays the full paged documentation for any uv command, while `--help`/`-h`
prints a condensed inline version. Together they are the primary way to navigate the CLI
without leaving the terminal.

## Syntax / Usage

```bash
# Paged long-form help (uses less/more)
uv help [COMMAND]...

# Condensed inline help
uv [COMMAND] --help
uv [COMMAND] -h

# Shell completion script
uv generate-shell-completion <SHELL>
```

## Details

**`uv help` vs `--help`**

`uv help` shows the long-form documentation for a command and pipes it through the
system pager (`less` or `more`). Press `q` to exit. `--help` / `-h` prints a shorter,
unpaged summary to stdout.

Both forms accept a subcommand argument:

```
uv help init          # long help for uv init
uv init --help        # condensed help for uv init
uv help tool install  # long help for uv tool install
```

**`--no-pager`**

Pass `--no-pager` to `uv help` to print the full output directly to stdout without
invoking a pager. Useful in scripts or environments where a pager is not available.

**Verbosity flags**

The `-v` / `--verbose` flag is accepted by every uv command and increases log output.
Repeat it (`-vv`) for more detail. Fine-grained logging is also configurable via the
`RUST_LOG` environment variable. Verbose output often explains why uv made a particular
decision (resolver choices, cache hits, environment selection).

**Shell completion**

`uv generate-shell-completion <SHELL>` writes a completion script to stdout. Supported
values for `<SHELL>` are the standard set recognised by the underlying clap library
(bash, zsh, fish, elvish, powershell). Pipe the output into your shell's completion
directory or eval it from your shell profile.

**Top-level CLI command groups**

`uv --help` lists all available commands grouped by purpose:

| Group | Commands |
|---|---|
| Auth | `uv auth` (login, logout, token, dir) |
| Projects | `uv run`, `uv init`, `uv add`, `uv remove`, `uv version`, `uv sync`, `uv lock`, `uv export`, `uv tree`, `uv format`, `uv check`, `uv audit` |
| Tools | `uv tool` (run, install, upgrade, list, uninstall, update-shell, dir) |
| Python | `uv python` (install, list, find, pin, uninstall) |
| pip interface | `uv pip` (install, show, freeze, check, list, uninstall, tree, compile, sync) |
| Environments | `uv venv` |
| Build/Publish | `uv build`, `uv publish` |
| Workspaces | `uv workspace` |
| Utility | `uv cache`, `uv self` |
| Help | `uv help`, `uv generate-shell-completion` |

**Checking the installed version**

```bash
uv self version   # full version string including build commit and date
uv --version      # same output as uv self version
uv -V             # shorter — omits build commit and date
```

Note: before uv 0.7.0 the command was `uv version` instead of `uv self version`.

## Examples

```bash
# Open paged help for uv sync
uv help sync

# Inline condensed help for uv add
uv add --help

# Long help for a nested subcommand
uv help tool install

# Disable the pager (print full output to stdout)
uv help sync --no-pager

# Verbose output while syncing
uv sync -v

# Extra-verbose (includes resolver internals)
uv sync -vv

# Generate and install zsh completion
uv generate-shell-completion zsh > ~/.zfunc/_uv

# Generate bash completion and eval it
eval "$(uv generate-shell-completion bash)"

# Check uv version
uv self version
```

## Caveats / Common Mistakes

- `uv help` opens a pager by default. In non-interactive environments (CI, piped
  output, minimal containers) the pager may hang or error — use `--no-pager` or
  `--help` instead.
- `uv version` was the version command before uv 0.7.0. It now refers to reading or
  updating the project version in `pyproject.toml`. Use `uv self version` or
  `uv --version` to check the uv binary version.

## See Also

- cmd-run
- cmd-init
- cmd-version
- ts-verbose-debugging
- cmd-self
