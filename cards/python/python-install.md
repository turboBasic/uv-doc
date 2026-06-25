---
id: python-install
title: Installing and upgrading Python with uv
category: python
tags: [python, command, installation]
source: https://docs.astral.sh/uv/guides/install-python/
related: [python-versions, python-pin, python-discovery, python-downloads-control, cmd-venv]
---

## Summary

`uv python install` downloads and installs managed Python versions (CPython, PyPy, Pyodide) without
requiring a separate tool like pyenv. `uv python upgrade` patches installed versions in-place, with
virtual environments upgrading transparently via minor-version symlinks.

## Syntax / Usage

```bash
uv python install [OPTIONS] [TARGETS]...
uv python upgrade [OPTIONS] [TARGETS]...
uv python uninstall [OPTIONS] <TARGETS>...
uv python update-shell [OPTIONS]
```

## Details

### Installing

`uv python install` downloads from Astral's `python-build-standalone` project (CPython) or
`python.org` (PyPy). The available versions are frozen per uv release; to access newer Python
versions you may need to upgrade uv first.

With no arguments, uv installs the Python version recorded in `UV_PYTHON`, then `.python-versions`,
then `.python-version`. If none are present and no managed version is installed, uv installs the
latest stable CPython.

All [version request formats](https://docs.astral.sh/uv/concepts/python-versions/#requesting-a-version)
are accepted: plain version numbers (`3.12`, `3.12.3`), version specifiers (`>=3.8,<3.10`),
implementation tags (`pypy@3.10`, `cpython3.12`), variant suffixes (`3.13t`, `3.13+freethreaded`,
`3.13d`), and full platform tuples (`cpython-3.12.3-macos-aarch64-none`).

Key flags:

- `--reinstall` (`-r`): re-download and reinstall even if the version is already present. Useful
  when the underlying `python-build-standalone` distribution has been patched.
- `--force` (`-f`): replace executables not managed by uv. Implies `--reinstall`.
- `--default`: also install `python` and `python3` executables in addition to the versioned
  `python3.x` executable. Experimental. Only one version may be requested when this flag is used.
  Free-threaded variants install `pythont` / `python3t` instead.
- `--upgrade` (`-U`): upgrade the requested minor version(s) to their latest available patch.
  Only minor-version requests (e.g. `3.12`) are valid; patch requests cause an error.

### Executables and PATH

After installation, uv writes a versioned executable (`python3.12`) into the executable directory
(`~/.local/bin` on Unix, determined by XDG). uv only overwrites an existing executable if it is
itself managed by uv; use `--force` to overwrite foreign executables.

When multiple patch versions of the same minor are installed, the executable tracks the latest patch:
installing 3.12.7 writes `python3.12`, installing 3.12.8 later updates it, but installing 3.12.6
does not downgrade it.

Run `uv python dir --bin` to see the executable directory. If that directory is not on `PATH`,
run `uv python update-shell`: uv appends the required export to shell configuration files. If the
shell config already contains the entry but the directory is still absent from `PATH`, the command
exits with an error.

### Upgrading (patch-level)

`uv python upgrade` is a preview feature. It upgrades uv-managed CPython to the latest supported
patch release within the requested minor version (e.g. 3.12.10 → 3.12.11). Cross-minor upgrades
(3.12 → 3.13) are not supported because they can affect dependency resolution.

Upgrades are not supported for PyPy, GraalPy, or Pyodide.

After an upgrade, old patch installations are retained (they may still be used by existing venvs).
New venvs and venvs that were created via the minor-version directory will transparently use the
new patch.

#### Minor-version directories

The transparent upgrade mechanism relies on a minor-version symlink (Unix) or junction (Windows):

```
~/.local/share/uv/python/cpython-3.12-macos-aarch64-none
  -> ~/.local/share/uv/python/cpython-3.12.11-macos-aarch64-none
```

Virtual environments whose Python path points to this minor-version directory are automatically
upgraded when the symlink target changes. Environments created with an explicit patch request
(e.g. `uv venv -p 3.12.8`) bypass the symlink and will not be automatically upgraded.

If another tool resolves (canonicalizes) the interpreter path before creating a venv, it will
capture the specific patch path and lose automatic upgrade behavior.

Environments created before the upgrade feature was added must be recreated to opt in.

### Uninstalling

`uv python uninstall <TARGETS>` removes specified managed Python versions. Use `--all` to remove
every managed Python version. On Windows, the registry entry for the uninstalled version is also
removed, along with any broken registry entries.

## Examples

```bash
# Install latest stable CPython
uv python install

# Install specific versions
uv python install 3.12
uv python install 3.12.3
uv python install 3.11 3.12 3.13

# Alternative implementations
uv python install pypy@3.10
uv python install pypy

# Variants
uv python install 3.13t           # free-threaded
uv python install 3.13+freethreaded
uv python install 3.13d           # debug build

# Install with python/python3 executables (experimental)
uv python install 3.12 --default

# Reinstall (refresh distribution without changing version)
uv python install --reinstall
uv python install 3.12 --reinstall

# Force-replace executables not owned by uv
uv python install 3.12 --force

# Upgrade a minor version to latest patch (preview)
uv python upgrade 3.12

# Upgrade all managed CPython versions
uv python upgrade

# Remove a version
uv python uninstall 3.11
uv python uninstall --all

# Add Python executable directory to PATH
uv python update-shell

# Verify where executables are installed
uv python dir --bin
```

## Caveats / Common Mistakes

- The available Python versions are frozen per uv release. If a newly released Python version is
  not available, upgrade uv first.
- `--default` is experimental and only accepts a single version request; passing multiple versions
  causes an error.
- `uv python upgrade` is in preview and only works for uv-managed CPython. PyPy, GraalPy, and
  Pyodide upgrades are not supported.
- Venvs created with an explicit patch version (e.g. `-p 3.12.8`) are not transparently upgraded;
  only those pointing through the minor-version symlink benefit from automatic upgrades.
- If another tool canonicalizes the Python interpreter path when creating a venv, it will capture
  the specific patch directory, bypassing the minor-version symlink and losing upgrade transparency.
- `uv python update-shell` exits with an error if the shell configuration already contains the PATH
  entry but the directory is still missing from `PATH` (e.g. the session was not restarted).
- Python installations are stored under `~/.local/share/uv/python` by default. Changing
  `UV_PYTHON_INSTALL_DIR` does not update existing virtual environments; they must be recreated.
- Free-threaded variants (`3.13t`) are not selected by default for Python 3.13; they must be
  explicitly requested. For Python 3.14+, free-threaded builds can be used without explicit
  selection, though the GIL-enabled build is still preferred.

## See Also

- python-versions
- python-pin
- python-discovery
- python-downloads-control
- cmd-venv
