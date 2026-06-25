---
id: dep-add
title: uv add — manage project dependencies
category: dependencies
tags: [command, dependency, project, config, lockfile]
source: https://docs.astral.sh/uv/concepts/projects/dependencies/
related: [concept-lockfile, project-structure, config-files, pip-install, project-migrate-from-pip]
---

## Summary

`uv add` declares a dependency in `pyproject.toml`, then updates `uv.lock` and the
project environment to match. `uv remove` reverses it. This is the project-interface
counterpart to the lower-level `uv pip install`.

## Syntax / Usage

```bash
uv add <package>[constraint] [OPTIONS]
uv remove <package>
```

## Details

`uv add` writes the dependency into `project.dependencies` (or another table via flags),
re-resolves the lockfile, and syncs `.venv`. uv adds a sensible lower bound automatically
(e.g. `uv add httpx` records something like `httpx>=0.27.2`).

Targets and groups:

- `--dev` — add to the `dev` group under `[dependency-groups]`.
- `--group <name>` — add to a custom group (e.g. `lint`, `test`).
- `--optional <extra>` — add to `[project.optional-dependencies]` as an extra.

Dependency sources go in `[tool.uv.sources]` and apply only to uv (other tools ignore
them): `git+<url>` (with `--tag`/`--branch`/`--rev`), local `path` entries,
`--editable` installs, direct URLs, `--index` pins, and `workspace = true` members.

Environment markers scope a dependency to a platform or Python version, e.g.
`uv add "jax; sys_platform == 'linux'"`.

## Examples

```bash
# Runtime dependency with a constraint
uv add "httpx>=0.27"

# Dev / grouped dependencies
uv add --dev pytest
uv add --group lint ruff

# Optional dependency (extra)
uv add matplotlib --optional plot

# Git source pinned to a tag
uv add git+https://github.com/encode/httpx --tag 0.27.0

# Local editable package
uv add --editable ../projects/bar/

# Import an existing requirements.txt
uv add -r requirements.txt

# Remove a dependency
uv remove httpx
```

Resulting `pyproject.toml` for a git source:

```toml
[project]
dependencies = ["httpx"]

[tool.uv.sources]
httpx = { git = "https://github.com/encode/httpx", tag = "0.27.0" }
```

## Caveats / Common Mistakes

- `[tool.uv.sources]` is uv-specific. Validate a publishable build without it using
  `uv build --no-sources` (or `uv lock --no-sources`).
- Use `uv add`, not `uv pip install`, for project dependencies — only `uv add` updates
  `pyproject.toml` and `uv.lock`.

## See Also

- concept-lockfile
- project-structure
- config-files
- pip-install
- project-migrate-from-pip
