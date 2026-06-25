---
id: project-structure
title: uv project structure and layout
category: projects
tags: [project, config, venv, lockfile, python]
source: https://docs.astral.sh/uv/concepts/projects/layout/
related: [config-files, concept-lockfile, dep-add, python-versions]
---

## Summary

A uv project is a directory rooted at a `pyproject.toml`, accompanied by a managed
virtual environment (`.venv`) and a universal lockfile (`uv.lock`). uv creates and
maintains these for you as you add dependencies and run code.

## Syntax / Usage

```bash
uv init my-project       # scaffold a new project
cd my-project
uv run python -V         # creates .venv + uv.lock on first run
```

## Details

Core files in a uv project:

- **`pyproject.toml`** — project metadata (name, version, `requires-python`,
  dependencies) and the marker for the project root. uv-specific settings live under
  `[tool.uv]`.
- **`uv.lock`** — universal, cross-platform lockfile; checked into version control,
  managed by uv, not hand-edited.
- **`.venv/`** — the project environment, created next to `pyproject.toml` and
  auto-excluded from git. Editors use it for completion and type checking.
- **`README.md`** — conventional, referenced by packaging metadata.

When you run `uv run`, uv creates the project environment if it does not exist and
ensures it is up-to-date otherwise. Manage dependencies with `uv add` rather than
`uv pip install`, so `pyproject.toml` and `uv.lock` stay in sync.

The `[tool.uv]` table controls project behavior; for example `managed = false` disables
uv's automatic locking and syncing for the project.

A minimal `pyproject.toml`:

```toml
[project]
name = "example"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = []
```

## Examples

```text
my-project/
├── pyproject.toml
├── uv.lock
├── .venv/
├── src/
│   └── my_package/
│       └── __init__.py
└── README.md
```

## Caveats / Common Mistakes

- Do not modify the project environment with `uv pip install`; use `uv add` so the
  lockfile and `pyproject.toml` remain authoritative.
- `.venv` is platform-specific — keep it git-ignored (and add it to `.dockerignore`).

## See Also

- config-files
- concept-lockfile
- dep-add
- python-versions
