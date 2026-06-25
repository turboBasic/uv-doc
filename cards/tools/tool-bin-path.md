---
id: tool-bin-path
title: Tool bin directory and PATH — uv tool update-shell and uv tool dir
category: tools
tags: [command, tool, installation, config]
source: https://docs.astral.sh/uv/concepts/tools/
related: [tool-run, tool-install, tool-environments, tool-list-uninstall, config-env-vars]
---

## Summary

When `uv tool install` installs a tool, it symlinks the tool's executables (on Unix) or
copies them (on Windows) into a dedicated bin directory. That directory must be on `PATH`
for the executables to be reachable from the shell; `uv tool update-shell` automates
adding it.

## Syntax / Usage

```bash
uv tool update-shell          # add the bin dir to shell config files
uv tool dir                   # print the tools data directory
uv tool dir --bin             # print the executable (bin) directory
```

## Details

### Executable directory resolution

The executable directory is determined by checking the following environment variables in
order, falling back to the XDG default:

| Priority | Unix                      | Windows                        |
| -------- | ------------------------- | ------------------------------ |
| 1        | `$UV_TOOL_BIN_DIR`        | `%UV_TOOL_BIN_DIR%`            |
| 2        | `$XDG_BIN_HOME`           | `%XDG_BIN_HOME%`               |
| 3        | `$XDG_DATA_HOME/../bin`   | `%XDG_DATA_HOME%\..\bin`       |
| 4        | `$HOME/.local/bin`        | `%USERPROFILE%\.local\bin`     |

### Symlinks vs copies

On Unix, executables are **symlinked** into the bin directory pointing into the tool's
isolated virtual environment. On Windows, they are **copied** instead.

### Tools data directory

The tools data directory (where virtual environments live) is separate from the bin
directory. By default it is `$XDG_DATA_HOME/uv/tools` (i.e., `~/.local/share/uv/tools`
on Unix) or `%APPDATA%\uv\data\tools` on Windows. Override with `UV_TOOL_DIR`.

`uv tool dir` prints this data directory. `uv tool dir --bin` prints the executable
directory.

### uv tool update-shell

`uv tool update-shell` ensures the executable directory is present on `PATH` by appending
a path-export snippet to the relevant shell configuration files (e.g., `.bashrc`,
`.zshrc`, `.profile`). If the directory is already on `PATH`, the command is a no-op.

If the shell config files already contain the snippet but the directory is still absent
from `PATH` (e.g., the config was not sourced in the current session), uv exits with an
error rather than appending a duplicate entry.

### --force flag on uv tool install

`uv tool install` will not overwrite executables already present in the bin directory
unless they were installed by uv. If the same executable exists from another tool manager
(e.g., pipx), the install fails. Pass `--force` to override and overwrite.

## Examples

```bash
# Check where executables will land
uv tool dir --bin
# => /home/user/.local/bin

# Check where tool environments are stored
uv tool dir
# => /home/user/.local/share/uv/tools

# Add the bin dir to PATH in shell config and reload
uv tool update-shell
source ~/.bashrc

# Redirect executables to a custom directory
export UV_TOOL_BIN_DIR="$HOME/.bin"
uv tool install ruff

# Override the tools data directory
export UV_TOOL_DIR="/opt/uv-tools"
uv tool install ruff

# Overwrite an executable previously installed by pipx
uv tool install --force ruff
```

## Caveats / Common Mistakes

- After `uv tool install`, if the tool command is not found, the bin directory is probably
  not on `PATH`. Run `uv tool update-shell` and start a new shell session (or source your
  shell config).
- `uv tool update-shell` modifies shell config files but cannot modify the current
  session's environment. A new terminal or explicit `source` is always required.
- If the shell config already contains the PATH snippet but the directory is not on the
  current `PATH`, `uv tool update-shell` exits with an error instead of adding a
  duplicate. Manually source your shell config to resolve this.
- On Windows, executables are copied rather than symlinked, so upgrading a tool with
  `uv tool upgrade` always replaces the executable files in the bin directory.
- `UV_TOOL_BIN_DIR` controls only where executables are linked; `UV_TOOL_DIR` controls
  where the isolated virtual environments are stored. They are independent settings.

## See Also

- tool-run
- tool-install
- tool-environments
- tool-list-uninstall
- config-env-vars
