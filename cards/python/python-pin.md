---
id: python-pin
title: Pinning Python versions with .python-version
category: python
tags: [python, command, config, project]
source: https://docs.astral.sh/uv/concepts/python-versions/#python-version-files
related: [python-versions, python-discovery, config-python-version-file, python-install, project-structure]
---

## Summary

`uv python pin` writes a `.python-version` file that records the Python version request
for a directory. uv reads this file automatically when determining which interpreter to
use, searching up the directory tree and stopping at project or workspace boundaries.

## Syntax / Usage

```bash
uv python pin [OPTIONS] [REQUEST]

uv python list [OPTIONS] [REQUEST]
uv python find [OPTIONS] [REQUEST]
uv python dir [OPTIONS]
```

## Details

### Writing and reading .python-version

`uv python pin <request>` writes the request to `.python-version` in the current working
directory. With `--global`, the file is written to the uv user configuration directory
(`$XDG_CONFIG_HOME/uv` on Linux/macOS, `%APPDATA%\uv` on Windows) instead.

Running `uv python pin` with no argument displays the currently pinned version from the
nearest `.python-version` file; it exits with an error if none is found.

`--rm` removes the pin (deletes the `.python-version` file).

### Discovery order

When looking for a Python version, uv first checks for `.python-version` in the working
directory, then walks up through parent directories. Discovery stops at a project or
workspace boundary — uv will not cross `pyproject.toml`/workspace roots to search further
up. If no local file is found, uv falls back to the global `.python-version` file in the
user configuration directory.

Pass `--no-config` to disable `.python-version` file discovery entirely.

### Validation against requires-python

By default, `uv python pin` discovers the nearest project or workspace and validates that
the pinned version satisfies the `requires-python` constraint. Use `--no-project` (alias
`--no-workspace`) to skip this validation.

### .python-versions (plural) for multi-version projects

A `.python-versions` file (plural) can list multiple Python versions, one per line. When
`uv python install` is run without arguments and this file is present, uv installs all
listed versions. This is useful for projects that need to test against several Python
releases.

### --resolved flag

`--resolved` writes the full resolved interpreter path instead of the version request.
This pins the exact interpreter binary, which is generally not safe to commit to version
control because the path is machine-specific.

### Viewing available versions

`uv python list` lists installed Python versions and downloadable latest-patch versions
for each supported minor. Useful flags:

| Flag | Effect |
|---|---|
| `--all-versions` | Show all patch versions, not just latest per minor |
| `--all-platforms` | Show downloads for all platforms |
| `--only-installed` | Omit available downloads, show only installed |
| `<request>` | Filter by version or implementation (e.g. `3.13`, `pypy`) |

`uv python find <request>` prints the path to the first matching interpreter. By default
it includes virtual environments (`.venv` in CWD or parents, or `$VIRTUAL_ENV`). Use
`--system` to ignore virtual environments.

### Install paths

`uv python dir` prints the directory where uv stores managed Python installations
(default: `$HOME/.local/share/uv/python` on Unix, `%APPDATA%\uv\data\python` on
Windows). Override with `$UV_PYTHON_INSTALL_DIR`.

`uv python dir --bin` prints the directory where uv installs Python executables such as
`python3.12` (default: `$HOME/.local/bin` on Unix). Override with `$UV_PYTHON_BIN_DIR`.

## Examples

```bash
# Pin the current directory to Python 3.12
uv python pin 3.12

# Pin globally (user config dir)
uv python pin --global 3.11

# Show the current pin without changing it
uv python pin

# Remove the pin
uv python pin --rm

# Pin without validating against requires-python
uv python pin 3.10 --no-project

# List installed and downloadable versions
uv python list

# Show only installed versions
uv python list --only-installed

# List all 3.13 interpreters
uv python list 3.13

# Show all patch versions across all platforms
uv python list --all-versions --all-platforms

# Find the path of the first available Python >= 3.11
uv python find '>=3.11'

# Find ignoring virtual environments
uv python find --system 3.12

# Show Python install directory
uv python dir

# Show Python executables directory
uv python dir --bin
```

### .python-versions for multi-version testing

```
# .python-versions
3.10
3.11
3.12
3.13
```

```bash
# Install all listed versions
uv python install
```

## Caveats / Common Mistakes

- uv supports richer request formats in `.python-version` than tools like pyenv (e.g.
  `cpython@3.12`, `3.13t`). Using non-version-number requests breaks interoperability
  with pyenv and other tools that read `.python-version`. Stick to plain version numbers
  when sharing a file across tools.
- `--resolved` writes an absolute path, making the `.python-version` file
  machine-specific. Do not commit a `--resolved` pin to version control.
- `.python-version` discovery stops at project/workspace boundaries. A file in a parent
  directory above the workspace root will not be found unless `--no-config` is used and
  the path is provided explicitly.
- The `--bin` flag for `uv python dir` only reflects executables installed in preview
  mode; in non-preview mode the directory is still shown but may not be populated by uv.

## See Also

- python-versions
- python-discovery
- config-python-version-file
- python-install
- project-structure
