---
id: project-environment
title: Managing the project environment (.venv)
category: projects
tags: [project, venv, config, installation]
source: https://docs.astral.sh/uv/concepts/projects/layout/#the-project-environment
related: [project-structure, project-sync-lock, cmd-sync, config-project-env-settings, integration-docker]
---

## Summary

uv creates and maintains a persistent virtual environment in `.venv` next to
`pyproject.toml`. This environment is the single source of truth for running and
testing the project; its location, sync behavior, and lifecycle are all configurable.

## Syntax / Usage

```bash
uv sync                         # create/update .venv (exact sync by default)
uv sync --inexact               # update .venv, keep extraneous packages
uv run python -V                # auto-sync then run in .venv
uv run --exact python -V        # exact sync before run (removes extraneous)

# partial installs (Docker layer caching)
uv sync --no-install-project    # deps only, skip current project
uv sync --no-install-workspace  # deps only, skip all workspace members
uv sync --no-install-package <pkg>  # skip a specific package

# custom environment path
UV_PROJECT_ENVIRONMENT=/path/to/env uv sync
```

## Details

### Location and git exclusion

uv places `.venv` adjacent to `pyproject.toml` so editors can locate it for
completions and type checking. An internal `.gitignore` file is written into `.venv`
automatically, so the directory is excluded from version control without any manual
configuration.

### Activating the environment

The environment can be activated with the standard virtual-environment mechanism
(`source .venv/bin/activate` on Unix, `.venv\Scripts\activate` on Windows), or you
can use `uv run` directly — the preferred approach because it ensures the environment
is up to date before executing.

### Exact vs inexact sync

`uv sync` performs **exact** syncing by default: packages not present in the lockfile
are removed. `uv run` performs **inexact** syncing by default: it installs what is
needed but leaves extra packages in place.

| Command     | Default behavior | Override flag |
|-------------|-----------------|---------------|
| `uv sync`   | exact (removes extraneous) | `--inexact` / `--no-exact` |
| `uv run`    | inexact (keeps extraneous) | `--exact` |

### Partial installs

Three flags enable step-by-step installation, useful for optimizing Docker layer
caching:

- `--no-install-project` — omit the current project but install all its dependencies.
- `--no-install-workspace` — omit all workspace members (including the root project)
  but install their dependencies.
- `--no-install-package <name>` — omit a specific package. Can be repeated.

Dependencies of excluded packages are still installed; using these flags incorrectly
can produce a broken environment.

### Custom environment path (`UV_PROJECT_ENVIRONMENT`)

Set `UV_PROJECT_ENVIRONMENT` to change where the project environment is created:

- **Relative path** — resolved relative to the workspace root; a child directory is
  created there.
- **Absolute path** — used as-is; no subdirectory is created. If the path is shared
  across multiple projects each `uv sync` invocation will overwrite the previous
  environment, so this is recommended only for single-project CI or Docker setups.

```bash
# relative (creates my-env/ next to pyproject.toml)
UV_PROJECT_ENVIRONMENT=my-env uv sync

# absolute (uses the exact path provided)
UV_PROJECT_ENVIRONMENT=/opt/app/.venv uv sync
```

### `VIRTUAL_ENV` warning and `--active` / `--no-active`

uv ignores the `VIRTUAL_ENV` environment variable during project operations by
default. If `VIRTUAL_ENV` points to a path different from the project's `.venv`, uv
emits a warning.

- `--active` — opt in to using the currently activated environment (the one
  `VIRTUAL_ENV` points to) instead of the project environment. For `uv sync`, this
  syncs dependencies into the active environment directly.
- `--no-active` — silence the mismatch warning without changing which environment is
  used.

### Opting out with `managed = false`

Setting `managed = false` in `[tool.uv]` disables automatic locking and syncing for
the project. uv will ignore the project when `uv run` is invoked.

```toml title="pyproject.toml"
[tool.uv]
managed = false
```

## Examples

```bash
# Standard workflow: sync then run
uv sync
uv run pytest

# Keep manually installed extras intact
uv sync --inexact

# Docker: install only deps in one layer, copy source and install project in next
uv sync --no-install-project
COPY . .
uv sync

# Use a custom env location for the project
UV_PROJECT_ENVIRONMENT=.venv-dev uv sync

# Silence the VIRTUAL_ENV mismatch warning
uv sync --no-active

# Sync into the currently active virtualenv
uv sync --active
```

## Caveats / Common Mistakes

- Do not modify `.venv` with `uv pip install` — use `uv add` so `pyproject.toml` and
  `uv.lock` remain authoritative. `uv sync` (exact mode) will remove packages that
  are not in the lockfile on the next run.
- When `UV_PROJECT_ENVIRONMENT` is an absolute path shared across projects, each
  project's sync overwrites the environment — only safe for single-project contexts.
- `--no-install-project` and `--no-install-workspace` still install dependencies of
  the excluded packages; misusing these flags can leave the environment in a broken
  state.
- `.venv` is platform-specific and should also be added to `.dockerignore`.

## See Also

- project-structure
- project-sync-lock
- cmd-sync
- config-project-env-settings
- integration-docker
