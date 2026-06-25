---
id: pip-sync
title: uv pip sync — syncing environments to a lockfile
category: pip
tags: [command, pip, lockfile, venv, installation]
source: https://docs.astral.sh/uv/reference/cli/#uv-pip-sync
related: [pip-install, pip-compile, pip-environments, cmd-sync, concept-lockfile]
---

## Summary

`uv pip sync` brings a virtual environment into exact alignment with a requirements file or
`pylock.toml`: packages listed in the file are installed, and any packages already installed
but **not** listed are removed. Use it instead of `uv pip install` when reproducibility requires
the environment to contain no extra packages.

## Syntax / Usage

```bash
uv pip sync <SRC_FILE> [<SRC_FILE> ...] [OPTIONS]
```

## Details

**Difference from `uv pip install`:** `uv pip install` is additive — it never removes packages
that are already installed unless they conflict with the new requirements. `uv pip sync` is
declarative: after it completes, the environment contains exactly the packages listed in the
input file, no more and no less.

**Input file formats:** `uv pip sync` accepts the following as `SRC_FILE`:

- `requirements.txt` — the primary use case; expected to contain fully pinned, transitive
  dependencies (e.g., output from `uv pip compile` or `uv export`).
- `pylock.toml` — a PEP 751 lock file.
- `pyproject.toml`, `setup.py`, `setup.cfg` — uv extracts the project's requirements from
  these files; use `--extra <name>` or `--all-extras` for optional dependencies.
- `.py` files with PEP 723 inline metadata.
- `-` (stdin).

Multiple source files can be provided; their package sets are merged.

**Transitive dependencies:** The input file is assumed to list all transitive dependencies
explicitly (as `uv pip compile` and `uv export` do). Packages not present in the file will not
be installed. Use `--strict` to emit warnings when transitive dependencies appear to be missing.

**Virtual environment discovery:** `uv pip sync` requires a virtual environment by default. It
searches in order: `VIRTUAL_ENV` env var → `CONDA_PREFIX` env var → `.venv` in the current or
nearest parent directory. If none is found, uv prompts you to create one with `uv venv`. Pass
`--python <path>` to target a specific interpreter, or `--system` to target system Python (CI
use only).

**Key flags:**

- `--dry-run` — resolve and print the planned changes without modifying the environment.
- `--compile-bytecode` / `--compile` — compile `.py` files to `__pycache__/*.pyc` after
  installation, trading longer install time for faster cold-start. Also sets
  `UV_COMPILE_BYTECODE`. When enabled, uv processes the entire `site-packages` directory for
  consistency.
- `--no-build-isolation` — disable PEP 518 build isolation; assumes build dependencies are
  already installed. Also set via `UV_NO_BUILD_ISOLATION`.
- `--link-mode` — controls how packages are linked from the global cache (`clone`, `hardlink`,
  `symlink`, `copy`). Defaults to `clone` (Copy-on-Write) on macOS/Linux and `hardlink` on
  Windows. Symlinks are discouraged because they create tight coupling to the cache directory.
- `--require-hashes` — enforce that every requirement has a hash; requires exact version pins
  or direct URL dependencies.
- `--allow-empty-requirements` — allow syncing with an empty file, which clears all packages
  from the environment.
- `--group <name>` — install a dependency group from a `pylock.toml` or `pyproject.toml` in
  addition to the base requirements.

Settings under `[tool.uv.pip]` in `pyproject.toml` or `uv.toml` apply to this command.

## Examples

```bash
# Sync a venv to a compiled requirements file (removes unlisted packages)
uv pip sync requirements.txt

# Sync to a PEP 751 pylock.toml
uv pip sync pylock.toml

# Dry run — show what would change without touching the environment
uv pip sync requirements.txt --dry-run

# Sync and pre-compile bytecode (faster cold starts in Docker/CLI tools)
uv pip sync requirements.txt --compile-bytecode

# Sync with build dependencies already present (no isolation)
uv pip sync requirements.txt --no-build-isolation

# Sync to a specific venv (bypassing discovery)
uv pip sync requirements.txt --python /path/to/.venv

# Merge two pinned requirement files into one environment
uv pip sync requirements.txt requirements-dev.txt

# Verify no transitive deps are missing after sync
uv pip sync requirements.txt --strict
```

## Caveats / Common Mistakes

- Passing an unpinned `requirements.in` (without transitive deps) will leave those transitive
  packages absent from the environment. Always pass the output of `uv pip compile` or
  `uv export`, not the input spec file.
- `uv pip sync` removes packages not in the file — including packages you installed manually
  since the last compile. This is intentional; it is the point of sync.
- Using `--link-mode symlink` means that `uv cache clean` will break the installed packages
  by removing the underlying source files from the cache.
- `--no-build-isolation` assumes all build-time dependencies are pre-installed; if they are
  missing, builds will fail with confusing errors rather than a clear diagnostic.
- `uv pip sync` operates on the pip-compatible interface only. It does not write to
  `pyproject.toml` or `uv.lock`. For project-managed environments, use `uv sync` instead.

## See Also

- pip-install
- pip-compile
- pip-environments
- cmd-sync
- concept-lockfile
