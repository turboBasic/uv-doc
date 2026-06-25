---
id: concept-project-environment
title: The project virtual environment (.venv) and managed vs unmanaged projects
category: concepts
tags: [venv, project, config, installation, lockfile]
source: https://docs.astral.sh/uv/concepts/projects/layout/#the-project-environment
related: [cmd-sync, concept-lockfile, project-sync-lock, config-project-env-settings, cmd-run]
---

## Summary

uv automatically creates and maintains a `.venv` directory next to `pyproject.toml` as the
persistent project environment. Every `uv run` invocation locks and syncs this environment before
executing the requested command; `tool.uv.managed = false` opts the project out of this automatic
management.

## Details

### Environment location and discovery

The project environment lives at `.venv` relative to the workspace root. uv writes an internal
`.gitignore` so the directory is excluded from version control automatically. Editors (IDEs, type
checkers) find it at this predictable path for completions and type hints.

### Automatic lock and sync on `uv run`

When `uv run` is invoked, uv performs two steps before running the command:

1. **Lock** — checks whether `uv.lock` is up-to-date with `pyproject.toml` and regenerates it if
   not.
2. **Sync** — installs the packages recorded in the lockfile into `.venv`.

Both steps can be individually suppressed. Use `--locked` to error instead of re-locking, `--frozen`
to skip the freshness check entirely, and `--no-sync` to skip the sync step without touching the
lockfile.

### Editable vs non-editable install

By default `uv sync` installs the project itself (and workspace members) as **editable** packages,
so source changes are reflected immediately without re-syncing. Pass `--no-editable` to install in
non-editable mode — useful for Docker image builds or deployment artifacts where the source tree
will not be present at runtime.

Note: if the project declares no `[build-system]`, uv does not install the project at all — only
its dependencies are synced.

### Exact vs inexact sync

- `uv sync` uses **exact** mode by default: packages not present in the lockfile are removed from
  the environment.
- `uv run` uses **inexact** mode by default: required packages are added but extraneous packages
  are left in place.

Override with `--inexact` on `uv sync` or `--exact` on `uv run` to swap the behaviour.

### Partial installs

Three flags on `uv sync` let you stage installations (e.g., for optimal Docker layer caching):

- `--no-install-project` — omit the current project but install its dependencies.
- `--no-install-workspace` — omit all workspace members (including root) but install their
  dependencies.
- `--no-install-package <name>` — omit a specific named package.

In all cases the omitted package's dependencies are still installed. Misuse can produce a broken
environment where a package is missing its own dependencies.

### Overriding the environment path

Set the `UV_PROJECT_ENVIRONMENT` environment variable to redirect the project environment to a
different path. A relative path is resolved from the workspace root; an absolute path is used
as-is (no child directory is created). If no environment exists at the target path, uv creates one.

This is the mechanism used to target a system Python environment in Docker, though the docs warn
against it in shared contexts: `uv sync`'s default exact mode will remove any packages not in the
lockfile, potentially breaking the system Python.

If `UV_PROJECT_ENVIRONMENT` is set to an absolute path and is shared across multiple projects,
each invocation overwrites the same environment — only safe for single-project CI or containers.

By default, uv ignores `VIRTUAL_ENV` during project operations. A warning is shown if `VIRTUAL_ENV`
points elsewhere; use `--active` to opt in to respecting it, or `--no-active` to silence the
warning without opting in.

### Opting out of automatic management

Set `tool.uv.managed = false` in `pyproject.toml` to disable automatic locking and syncing. When
this flag is `false`, `uv run` ignores the project and will not create or update the environment.
Default value is `true`.

## Examples

```bash
# Normal run — locks and syncs automatically before executing
uv run python -m pytest

# Run without re-checking the lockfile (fastest, assumes lock is fresh)
uv run --frozen python -m pytest

# Run without syncing (use current environment as-is)
uv run --no-sync python -m pytest

# Explicitly sync to latest lockfile state
uv sync

# Sync but keep extraneous packages (inexact mode)
uv sync --inexact

# Sync with exact mode on uv run (remove packages not in lockfile)
uv run --exact python -m pytest

# Non-editable install for deployment
uv sync --no-editable

# Partial install: copy deps layer, then project layer (Docker pattern)
uv sync --no-install-project   # layer 1: all deps
uv sync                        # layer 2: add the project itself
```

```toml title="pyproject.toml"
# Opt out of automatic management
[tool.uv]
managed = false
```

```bash
# Redirect the environment to a custom path (e.g., in CI)
UV_PROJECT_ENVIRONMENT=/opt/myapp/.venv uv sync
```

## Caveats / Common Mistakes

- Using `--no-install-project` / `--no-install-workspace` without understanding the layering can
  leave packages missing their own dependencies and produce confusing import errors at runtime.
- Setting `UV_PROJECT_ENVIRONMENT` to an absolute path shared by multiple projects causes each
  `uv sync` to overwrite the same environment; use it only for single-project contexts.
- `uv sync` exact mode (the default) **removes** unlocked packages. Pointing it at a system Python
  prefix can delete system packages. Use with care or prefer an isolated `.venv`.
- `uv run` does not respect `VIRTUAL_ENV` by default; passing `--active` opts in but is not the
  default workflow.
- If the project has no `[build-system]` declared, the project itself is not installed — only its
  dependencies. This is expected but surprises users who expect their own package to be importable
  immediately after `uv sync`.

## See Also

- cmd-sync
- concept-lockfile
- project-sync-lock
- config-project-env-settings
- cmd-run
