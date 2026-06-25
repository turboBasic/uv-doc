---
id: python-storage
title: Python install storage layout and environment variables
category: python
tags: [python, installation, config]
source: https://docs.astral.sh/uv/reference/storage/#python-versions
related: [python-versions, python-install, python-downloads-control, config-env-vars, tool-bin-path, config-installation]
---

## Summary

uv stores managed Python installs and their executables in well-defined directories that follow
XDG conventions on Unix and Known Folders on Windows, each overridable via environment variables.
Understanding these paths matters for air-gapped setups, CI caching, and diagnosing upgrade issues.

## Syntax / Usage

```bash
uv python dir           # print the Python installation directory
uv python dir --bin     # print the Python executables directory
```

## Details

### Python install directory

Managed Python versions (installed via `uv python install`) are stored in a `python/`
subdirectory of uv's persistent data directory:

- **Unix default:** `$XDG_DATA_HOME/uv/python` → typically `~/.local/share/uv/python`
- **Windows default:** `%APPDATA%\uv\data\python`

Override with `UV_PYTHON_INSTALL_DIR`.

### Python executables directory

uv places per-version executables (e.g. `python3.12`) into a directory that should be on `PATH`:

- **Unix lookup order:** `$UV_PYTHON_BIN_DIR` → `$XDG_BIN_HOME` → `$XDG_DATA_HOME/../bin` → `~/.local/bin`
- **Windows lookup order:** `%UV_PYTHON_BIN_DIR%` → `%XDG_BIN_HOME%` → `%XDG_DATA_HOME%\..\bin` → `%USERPROFILE%\.local\bin`

Override with `UV_PYTHON_BIN_DIR`. Run `uv python update-shell` if the executables directory is
not yet on `PATH`.

### Minor-version symlink / junction for upgrades

To support transparent patch-version upgrades, uv creates a minor-version directory alongside each
full patch install. For example:

```
~/.local/share/uv/python/cpython-3.12-macos-aarch64-none    ← symlink (Unix) / junction (Windows)
~/.local/share/uv/python/cpython-3.12.11-macos-aarch64-none ← actual install
```

The symlink always points to the latest installed patch for that minor version. `uv python upgrade
3.12` updates this pointer and all virtual environments that used the minor-version symlink are
automatically upgraded.

`uv python install 3.12.7` adds `python3.12` to the executables directory. Subsequent installs of
older patches (e.g. `3.12.6`) do not overwrite it; only a newer patch (e.g. `3.12.8`) updates it.

### Custom download mirrors

`python-install-mirror` (or `UV_PYTHON_INSTALL_MIRROR`) redirects CPython downloads to an
alternate URL. The value replaces the default base path
`https://github.com/astral-sh/python-build-standalone/releases/download` in every download URL.
Use `file://` for a local directory mirror.

`python-downloads-json-url` (or `UV_PYTHON_DOWNLOADS_JSON_URL`) points to a JSON file that fully
replaces uv's built-in list of available Python distributions. Use this to serve a custom manifest
from an internal registry.

## Examples

```bash
# Show where Python versions are installed
uv python dir

# Show where python3.12 executables land
uv python dir --bin

# Override install dir globally
UV_PYTHON_INSTALL_DIR=/opt/uv-python uv python install 3.12

# Use a corporate HTTP mirror
UV_PYTHON_INSTALL_MIRROR=https://mirror.corp.example.com/python-build-standalone/releases/download \
  uv python install 3.13

# Use a local directory mirror (air-gapped)
UV_PYTHON_INSTALL_MIRROR=file:///mnt/offline/python uv python install 3.12

# Use a custom JSON manifest for available downloads
UV_PYTHON_DOWNLOADS_JSON_URL=https://internal.corp.example.com/uv-python.json \
  uv python install 3.12
```

```toml
# uv.toml — persist mirror settings
python-install-mirror = "https://mirror.corp.example.com/python-build-standalone/releases/download"
python-downloads-json-url = "https://internal.corp.example.com/uv-python.json"
```

## Caveats / Common Mistakes

- Changing `UV_PYTHON_INSTALL_DIR` does not automatically update existing virtual environments.
  They continue pointing to the old location; recreate them manually.
- If a virtual environment was created with an explicit patch version (e.g. `uv venv -p 3.10.8`),
  it is pinned to that exact install and will not be auto-upgraded when the minor-version symlink
  advances.
- If another tool (e.g. a build system) resolves and canonicalizes the Python interpreter path,
  the resolved path points directly into the patch-version directory, bypassing the minor-version
  symlink. That virtual environment will not receive automatic upgrades.
- `uv python upgrade` only works for uv-managed CPython installs. PyPy, GraalPy, and Pyodide
  upgrades are not currently supported.
- uv will not overwrite an existing executable in the bin directory that it did not install
  (i.e. is not managed by uv) unless `--force` is passed.

## See Also

- python-versions
- python-install
- python-downloads-control
- config-env-vars
- tool-bin-path
- config-installation
