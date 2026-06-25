---
id: pip-environments
title: Virtual environments and environment targeting in uv pip
category: pip
tags: [pip, venv, python, command]
source: https://docs.astral.sh/uv/pip/environments/
related: [cmd-venv, python-discovery, pip-install, pip-compile, pip-sync]
---

## Summary

`uv pip` commands require a virtual environment by default — unlike pip, which falls back to the
global Python environment. uv discovers the active or nearest venv automatically, and provides
`--python` and `--system` flags for explicit environment targeting.

## Syntax / Usage

```bash
# Create a venv, then use it implicitly
uv venv [<path>] [--python <version>]

# Target a specific interpreter (venv path or executable)
uv pip install --python /path/to/python <package>

# Opt into system Python (no venv required)
uv pip install --system <package>
```

## Details

### Virtual environment discovery order

When running a mutating command (`uv pip install`, `uv pip sync`), uv searches for an environment
in this order:

1. `VIRTUAL_ENV` environment variable — an activated virtual environment.
2. `CONDA_PREFIX` environment variable — an activated Conda environment.
3. `.venv` in the current directory, or the nearest parent directory (even if not activated).

If no environment is found, uv prompts the user to create one via `uv venv`.

### Why uv requires a venv by default

pip installs into the global Python environment when no venv is active. uv inverts this default:
installing globally is opt-in, not opt-out. This prevents accidental mutation of system or
interpreter-wide state and makes the common case — working with a venv — zero-friction.

### Targeting an arbitrary environment with `--python`

`--python` accepts either:

- A path to a Python executable: `--python /usr/local/bin/python3.12`
- A path to the root of a virtual environment: `--python /path/to/venv`
- A version string (e.g. `--python 3.12`), in which case uv searches for a matching interpreter

When `--python` resolves to a system interpreter (not inside a venv), the `--system` flag must also
be provided; without it, uv ignores non-venv interpreters.

### `--system` flag

`--system` installs into the first Python interpreter found on `PATH`, skipping any venv
interpreters — roughly equivalent to `uv pip install --python $(which python)`. It is the
appropriate choice in CI and containerized environments where no venv is present.

When `--system` is provided, uv ignores any interpreters that are inside virtual environments.

### `VIRTUAL_ENV` environment variable

Setting `VIRTUAL_ENV=/path/to/venv` causes uv to install into that path regardless of the current
directory or shell activation state. If the path is not a PEP 405-compliant virtual environment,
uv ignores the variable.

### `uv pip compile` does not require an active venv

`uv pip compile` resolves dependencies and writes a pinned requirements file without modifying any
environment. A Python interpreter is still required for resolution (to evaluate markers), but no
virtual environment needs to be active or present.

## Examples

```bash
# Create a venv at the default .venv path, then install into it implicitly
uv venv
uv pip install flask

# Create a venv with a specific Python version
uv venv --python 3.11
uv pip install "flask[dotenv]"

# Activate and install (VIRTUAL_ENV is set by the activation script)
source .venv/bin/activate
uv pip install ruff

# Point at an arbitrary venv without activating
uv pip install --python /path/to/other-venv ruff

# Install into system Python (CI / Docker)
uv pip install --system ruff

# Compile requirements without an active venv
uv pip compile requirements.in -o requirements.txt
```

## Caveats / Common Mistakes

- If `VIRTUAL_ENV` points to a directory that is not a PEP 405-compliant venv, uv silently ignores
  it and falls back to the discovery order. This can cause installs to land in an unexpected venv.
- `--python <version>` without `--system` will skip system interpreters even if they match the
  requested version. Add `--system` to allow uv to select a system-installed interpreter.
- Installing into system Python on Debian prior to Python 3.10 is unsupported due to distribution
  patching of `distutils` (but not `sysconfig`).
- When uv is invoked via `python -m uv`, it defaults to the parent interpreter's environment.
  Prefer invoking uv directly for consistent behavior.

## See Also

- cmd-venv
- python-discovery
- pip-install
- pip-compile
- pip-sync
