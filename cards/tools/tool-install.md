---
id: tool-install
title: uv tool install — persistent tool installation
category: tools
tags: [command, tool, installation, venv]
source: https://docs.astral.sh/uv/reference/cli/#uv-tool-install
related: [tool-run, tool-environments, tool-upgrade, tool-list-uninstall, tool-bin-path]
---

## Summary

`uv tool install` installs a Python package as a persistent CLI tool: it creates an isolated
virtual environment in the uv tools directory and symlinks (Unix) or copies (Windows) every
executable the package provides into the tool executable directory on your `PATH`.

## Syntax / Usage

```bash
uv tool install [OPTIONS] <PACKAGE>
```

## Details

### Environment and executable linking

Each installed tool lives in its own isolated environment under
`~/.local/share/uv/tools/<tool-name>` (the exact path is shown by `uv tool dir`).
All console entry points, script entry points, and binary scripts provided by the package are
linked into the executable directory (`~/.local/bin` on Unix by default, retrievable with
`uv tool dir --bin`). That directory must be on `PATH`; if it is not, uv prints a warning
and `uv tool update-shell` can add it automatically.

On Unix, executables are symlinked; on Windows, they are copied.

### All executables are linked

Unlike `uvx`, which runs a single named command, `uv tool install` links **all** executables
provided by the package. Installing `httpie`, for example, links `http`, `https`, and `httpie`.

### Version specifiers

- `<package>@<version>` — pin an exact version: `uv tool install ruff@0.6.0`
- `<package>@latest` — fetch and install the latest available version
- PEP 508 constraint syntax without `@`: `uv tool install 'ruff>=0.5,<0.7'`

Version constraints are recorded and respected by subsequent `uv tool upgrade` calls.

### `--from` — decouple package name from command name

When the executable name differs from the package name, or when you need extras or an
alternative source, use `--from`:

```bash
uv tool install --from httpie http        # package httpie, command http
uv tool install --from 'mypy[faster-cache]' mypy
uv tool install --from git+https://github.com/httpie/cli httpie
```

Without `--from`, the argument is treated as both the package specifier and the command name.

### `--with` — extra dependencies

Include additional packages in the tool environment without exposing their executables:

```bash
uv tool install mkdocs --with mkdocs-material
```

`--with` can be repeated and accepts full PEP 508 specifiers.

### `--with-executables-from` — expose sibling executables

Also link the executables of additional packages into the `PATH`:

```bash
uv tool install --with-executables-from ansible-core,ansible-lint ansible
```

This differs from `--with`: both options add packages as dependencies, but only
`--with-executables-from` links those packages' executables.

### `--force` — overwrite existing entries

By default, uv refuses to overwrite executables that it did not place there (e.g., those
installed by pipx or the system package manager). Pass `--force` to recreate the environment
and replace any conflicting entries:

```bash
uv tool install --force ruff
```

### `--editable` — editable install

Install the target package in editable mode (`-e` shorthand), so changes to the source
directory are reflected without reinstallation:

```bash
uv tool install --editable /path/to/my-tool
```

### Python version

Use `--python` (`-p`) to select a specific interpreter for the tool environment:

```bash
uv tool install --python 3.11 ruff
```

Tool environments are tied to one Python interpreter. If that interpreter is later uninstalled,
the tool environment breaks and the tool will fail to run.

### Replacing vs upgrading

Reinstalling with `uv tool install` replaces the environment and updates version constraints.
Use `uv tool upgrade` when you want to upgrade within existing constraints without changing them.

## Examples

```bash
# Basic install — latest version
uv tool install ruff

# Pin an exact version
uv tool install ruff@0.6.0

# PEP 508 range constraint
uv tool install 'ruff>=0.5,<0.7'

# Always-latest install
uv tool install ruff@latest

# Package name differs from command name
uv tool install --from httpie http

# With extras via --from
uv tool install --from 'mypy[faster-cache,reports]' mypy

# Extra dependency in the environment (not linked to PATH)
uv tool install mkdocs --with mkdocs-material

# Expose executables from sibling packages
uv tool install --with-executables-from ansible-core,ansible-lint ansible

# Overwrite an entry installed by another tool manager
uv tool install --force ruff

# Editable install from a local directory
uv tool install --editable /path/to/my-tool

# Specific Python version for the environment
uv tool install --python 3.11 black

# Install from a git repository
uv tool install git+https://github.com/httpie/cli

# After install: add bin directory to PATH if not already there
uv tool update-shell
```

## Caveats / Common Mistakes

- **Executable not found after install.** The tool bin directory may not be on `PATH`.
  Run `uv tool update-shell` and restart your shell.
- **`--force` required when migrating from pipx.** uv will not overwrite executables it
  did not install. Use `--force` to take over management from another tool.
- **Do not mutate the tool environment directly** (e.g., with `pip install` inside it).
  uv treats tool environments as managed; direct mutations will be overwritten on the next
  install or upgrade.
- **Broken environment after Python uninstall.** If the Python interpreter linked to a tool
  environment is removed, the tool will stop working. Reinstall the tool to rebuild the
  environment against an available interpreter.
- **`@` syntax is exact-version only.** To specify a range, use PEP 508 syntax with quotes:
  `uv tool install 'ruff>=0.5,<0.7'`, not `ruff@>=0.5`.
- **Executables from `--with` dependencies are not linked.** Only the main package's
  executables (and those from `--with-executables-from`) appear on `PATH`.

## See Also

- tool-run
- tool-environments
- tool-upgrade
- tool-list-uninstall
- tool-bin-path
