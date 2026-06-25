---
id: python-discovery
title: Python interpreter discovery order
category: python
tags: [python, config, installation, troubleshooting]
source: https://docs.astral.sh/uv/concepts/python-versions/#discovery-of-python-versions
related: [python-versions, python-install, config-python-discovery, cmd-venv, ts-python-not-found]
---

## Summary

When uv needs a Python interpreter it follows a deterministic search order: virtual
environments first, then managed installs, then system PATH, then Windows registry, and
finally a compatible managed download. Understanding this order is essential for diagnosing
unexpected interpreter selection.

## Syntax / Usage

```bash
uv python find [REQUEST]           # print the interpreter uv would use
uv python find --system [REQUEST]  # skip virtual environments; system only
uv python find --show-version      # print version string instead of path
```

## Details

### Full discovery order

1. **Active or local virtual environment** — checked before any interpreter search when
   uv is running a command that allows virtual environments (e.g. `uv python find`,
   `uv pip install`). Two sources are checked:
   - `VIRTUAL_ENV` environment variable (activated venv).
   - `CONDA_PREFIX` environment variable (activated Conda environment; pip interface only).
   - `.venv` directory in the working directory or any parent directory.
   The virtual environment's interpreter is checked for compatibility with the request
   before the search below proceeds.

2. **Managed Python installations** in `UV_PYTHON_INSTALL_DIR` — interpreters installed
   by `uv python install`. uv **prefers the newest compatible version** among managed
   installs.

3. **System Python on PATH** — executables named `python`, `python3`, or `python3.x` on
   macOS/Linux; `python.exe` on Windows. uv uses the **first compatible match**, not the
   newest.

4. **Windows registry and Microsoft Store** — on Windows only, interpreters registered
   per PEP 514 (visible via `py --list-paths`).

5. **Compatible managed download** — if nothing above matches and automatic downloads are
   enabled, uv downloads a suitable managed Python version.

### Per-candidate metadata query

Non-executable files are silently skipped. For each executable candidate uv queries its
metadata (version, implementation, variant). If the query fails the candidate is skipped.
If the candidate satisfies the request it is used immediately without inspecting further
candidates.

### Controlling the search

| Mechanism | Effect |
|---|---|
| `--system` flag | Skip virtual environments; restrict to system path and managed installs |
| `--managed-python` / `UV_MANAGED_PYTHON` | Only use managed installs (`only-managed` preference) |
| `--no-managed-python` / `UV_NO_MANAGED_PYTHON` | Only use system installs (`only-system` preference) |
| `python-preference` setting | `managed` (default), `system`, `only-managed`, `only-system` |
| `--no-python-downloads` | Disable the automatic-download fallback |
| `UV_PYTHON` | Set a default Python request for all commands |

The `python-preference` default is `managed`, meaning managed installs are preferred over
system installs, but system installs are still preferred over downloading a new managed
version.

### Pre-releases and special variants

Pre-release interpreters are not selected by default — they are only used when no stable
release satisfies the request. Free-threaded builds (3.13t) and debug builds (3.13d) are
also not selected by default and must be explicitly requested.

## Examples

```bash
# Show which interpreter uv would use in the current directory
uv python find

# Find an interpreter meeting a version constraint
uv python find '>=3.11'

# Ignore virtual environments; look only at system and managed installs
uv python find --system

# Force managed installs only (never touch system Python)
uv python find --managed-python

# Force system Python only (never use managed installs)
uv python find --no-managed-python 3.12

# Restrict automatic downloads in a config file
# uv.toml
# python-downloads = "manual"

# Prefer system Python globally
# uv.toml
# python-preference = "system"
```

## Caveats / Common Mistakes

- `uv python find` includes the active virtual environment by default. Use `--system` when
  you want to know what interpreter lives on the host, not inside the project venv.
- pyenv-managed Pythons are treated as system Python by uv — not as managed installs.
- uv prefers the **newest** managed version but the **first compatible** system version.
  This asymmetry means adding a system Python earlier on PATH does not override a managed
  install.
- Canonicalizing a managed Python path (resolving symlinks) breaks automatic patch-version
  upgrades for virtual environments, because virtual environments created from the resolved
  path bypass the minor-version symlink mechanism.
- In air-gapped or restricted environments, set `python-downloads = "manual"` to prevent
  uv from reaching out to download an interpreter unexpectedly.

## See Also

- python-versions
- python-install
- config-python-discovery
- cmd-venv
- ts-python-not-found
