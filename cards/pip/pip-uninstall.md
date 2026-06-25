---
id: pip-uninstall
title: uv pip uninstall — removing packages from an environment
category: pip
tags: [command, pip, dependency, venv]
source: https://docs.astral.sh/uv/pip/packages/#uninstalling-a-package
related: [pip-install, pip-environments, dep-add, cmd-sync, pip-sync]
---

## Summary

`uv pip uninstall` removes one or more packages from the active or discovered virtual
environment. It is the pip-compatible counterpart to `uv remove` and operates only on the
environment — it does not modify `pyproject.toml` or `uv.lock`.

## Syntax / Usage

```bash
uv pip uninstall <PACKAGE> [<PACKAGE> ...]
uv pip uninstall -r <requirements.txt>
uv pip uninstall --python <python> <PACKAGE> ...
uv pip uninstall --system <PACKAGE> ...
```

## Details

`uv pip uninstall` removes packages from the environment that uv discovers (see
pip-environments for the full discovery order). By default this is:

1. The activated virtual environment (`VIRTUAL_ENV` env var).
2. An activated Conda environment (`CONDA_PREFIX` env var).
3. A `.venv` in the current directory or nearest parent directory.

If no virtual environment is found uv will error and prompt you to create one.

**Targeting a specific environment:**

- `--python <request>` / `-p` — specifies the Python interpreter whose environment should
  be modified. Accepts a path to a Python binary or the root of a virtual environment, or a
  version request (e.g. `3.12`). When a version request resolves to a system interpreter,
  `--system` must also be passed; without it uv skips non-venv interpreters.
- `--system` — bypasses virtual environment discovery and targets the first Python found on
  the system `PATH`. Mutually exclusive with venv-based discovery; when `--system` is
  provided uv ignores interpreters that *are* in virtual environments.

**Bulk removal via requirements file:**

`-r` / `--requirements` accepts a `requirements.txt`, `.py` file with inline metadata,
`pylock.toml`, `pyproject.toml`, `setup.py`, or `setup.cfg`. Only the package names are
used — version specifiers in the file are ignored for uninstallation purposes.

**Dry run:**

`--dry-run` prints the removal plan without making any changes to disk.

**Target/prefix directories:**

- `--target <dir>` / `-t` — uninstall from a `--target` directory.
- `--prefix <dir>` — uninstall from a `--prefix` directory.

## Examples

```bash
# Remove a single package
uv pip uninstall flask

# Remove multiple packages at once
uv pip uninstall flask ruff

# Remove everything listed in a requirements file
uv pip uninstall -r requirements.txt

# Target a specific virtual environment by path
uv pip uninstall --python /path/to/.venv flask

# Target a specific Python version (venv only; add --system for system interpreters)
uv pip uninstall --python 3.11 flask

# Use the system Python (CI / container use case)
uv pip uninstall --system flask

# Preview what would be removed without doing it
uv pip uninstall --dry-run flask ruff
```

## Caveats / Common Mistakes

- `uv pip uninstall` modifies only the environment. It does **not** update
  `pyproject.toml` or `uv.lock`. For a reproducible project workflow use `uv remove`
  instead, which removes the dependency declaration and regenerates the lockfile.
- By default uv requires a virtual environment. Running `uv pip uninstall` outside any
  venv (without `--system`) will error. Use `uv venv` to create one first, or pass
  `--system` for CI/container environments.
- `--system` skips all virtual environments and targets system Python. Use with caution —
  modifying a system Python installation can break OS-level tools.
- When `--python` resolves to a system interpreter, `--system` must be explicitly passed
  as well; uv will otherwise ignore it to protect system installations.

## See Also

- pip-install
- pip-environments
- dep-add
- cmd-sync
- pip-sync
