---
id: pip-install
title: uv pip install — the pip-compatible interface
category: pip
tags: [command, pip, dependency, venv]
source: https://docs.astral.sh/uv/pip/packages/
related: [dep-add, config-files, concept-lockfile, cmd-run]
---

## Summary

`uv pip install` is uv's drop-in, pip-compatible installer. It installs packages into the
active or discovered virtual environment **without** touching `pyproject.toml` or
`uv.lock` — the low-level counterpart to the project interface (`uv add`).

## Syntax / Usage

```bash
uv pip install <package>[extras][constraint] ...
uv pip install -r requirements.txt
uv pip uninstall <package> ...
```

## Details

`uv pip install` mirrors pip's surface area while operating on the venv uv discovers
(active `VIRTUAL_ENV`, or `.venv`). It does not modify project files, so it is the right
tool when you are managing an environment imperatively rather than via a locked project.

Supported sources:

- PyPI with optional extras and constraints: `"flask[dotenv]"`, `'ruff>=0.2.0'`,
  `'ruff==0.3.0'`.
- Local paths: `"ruff @ ./projects/ruff"`.
- Git: `"git+https://github.com/astral-sh/ruff"` (with `@<tag>` or `@<branch>`).
- Editable installs: `uv pip install -e .`.
- Requirements files: `-r requirements.txt`.
- A `pyproject.toml`: `-r pyproject.toml` (with `--extra <name>` or `--all-extras`).
- Dependency groups: `--group <name>`.

Settings under `[tool.uv.pip]` (see config-files) apply specifically to this interface.

## Examples

```bash
# Basic and constrained installs
uv pip install flask
uv pip install "flask[dotenv]" 'ruff>=0.2.0'

# Editable current project
uv pip install -e .

# From a requirements file or pyproject extras
uv pip install -r requirements.txt
uv pip install -r pyproject.toml --all-extras

# From Git at a tag
uv pip install "git+https://github.com/astral-sh/ruff@v0.6.0"

# Uninstall
uv pip uninstall flask
```

## Caveats / Common Mistakes

- `uv pip install` changes only the environment — it will not update `pyproject.toml` or
  `uv.lock`. For reproducible project dependencies, use `uv add` instead.
- `--group` reads the group from the current project's `pyproject.toml`, not from a path
  passed to `-r`/`-e`.

## See Also

- dep-add
- config-files
- concept-lockfile
- cmd-run
