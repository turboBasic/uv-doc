---
id: project-sync-lock
title: Locking and syncing the project environment
category: projects
tags: [project, lockfile, venv, dependency, ci, docker]
source: https://docs.astral.sh/uv/concepts/projects/sync/
related: [concept-lockfile, cmd-sync, cmd-lock, project-dependency-groups, integration-docker]
---

## Summary

Locking resolves project dependencies into `uv.lock`; syncing installs a subset of
those locked packages into the project environment (`.venv`). Both happen automatically
on `uv run`, but can be driven explicitly and controlled precisely for CI and Docker.

## Syntax / Usage

```bash
uv lock                          # create or update uv.lock
uv sync                          # sync .venv from uv.lock

uv lock --check                  # assert lockfile is up-to-date (non-zero on drift)
uv lock --upgrade                # re-resolve all packages to latest allowed versions
uv lock --upgrade-package <pkg>  # re-resolve a single package
uv lock --upgrade-package <pkg>==<version>  # pin one package to a specific version

uv sync --extra <name>           # include an optional-dependency extra
uv sync --all-extras             # include all extras
uv sync --no-dev                 # exclude the dev dependency group
uv sync --only-dev               # install dev group only (no project itself)
uv sync --group <name>           # include an additional dependency group
uv sync --only-group <name>      # install one group only (no project, no default groups)
uv sync --no-group <name>        # exclude a specific group (overrides inclusions)
uv sync --all-groups             # include all dependency groups

uv sync --no-install-project     # install deps but skip the project itself
uv sync --no-install-workspace   # skip all workspace members including root project
uv sync --no-install-package <pkg>  # skip a specific package

uv sync --inexact                # keep extraneous packages (do not remove them)
uv sync --no-editable            # install project in non-editable mode

uv run --locked ...              # error if lockfile is not up-to-date
uv run --frozen ...              # skip lockfile currency check entirely
uv run --no-sync ...             # skip environment update check
uv run --exact ...               # enable exact syncing (remove extraneous packages)
```

## Details

### Automatic lock and sync

`uv run` locks and syncs the project before every invocation so the environment is
always consistent. Commands that read the lockfile, such as `uv tree`, also trigger
an automatic lock update.

### Checking lockfile currency

uv considers a lockfile outdated when `pyproject.toml` metadata no longer matches it —
for example, after adding a dependency or tightening a version constraint to exclude
the locked version. Changing a constraint such that the existing locked version is
still valid does not mark the lockfile outdated.

New releases of packages on an index do **not** cause the lockfile to be considered
outdated; upgrades must be requested explicitly.

`uv lock --check` exits non-zero if the lockfile would need regeneration. It is
equivalent to `--locked` on other commands and is the recommended CI assertion.

### Upgrading locked versions

`uv lock --upgrade` and `uv lock --upgrade-package` can also be passed to `uv sync`
or `uv run` to update the lockfile and environment in one step. Upgrades are bounded
by the project's dependency constraints; an upper bound in `pyproject.toml` prevents
an upgrade past that version.

The same upgrade semantics apply to Git dependencies: uv prefers the locked commit SHA
unless `--upgrade` or `--upgrade-package` is passed.

### Syncing extras and dependency groups

Extras (from `[project.optional-dependencies]`) are not synced by default; use
`--extra <name>` or `--all-extras` to include them.

The `dev` dependency group (from `[dependency-groups]`) is synced by default.
All other groups must be requested explicitly. Group exclusions (`--no-group`) always
take precedence over inclusions — `--no-group foo --group foo` excludes `foo`.

### Exact vs inexact syncing

`uv sync` removes packages not in the lockfile by default (exact mode). `uv run` uses
inexact mode by default and will not remove extraneous packages. Use `--inexact` on
`uv sync` or `--exact` on `uv run` to invert the respective defaults.

### Editable installs

The project (and workspace members) are installed as editable packages so source
changes are reflected without re-syncing. Use `--no-editable` to install in
non-editable mode; this is useful in Docker multi-stage builds where only the `.venv`
is copied to the final image.

### Partial installs for Docker layer caching

Splitting dependency installation from project installation allows Docker to cache the
dependency layer independently of application code changes:

- `--no-install-project` — install all dependencies, skip the project itself
- `--no-install-workspace` — skip all workspace members including the root project
- `--no-install-package <pkg>` — skip a specific named package

All dependencies of the skipped target(s) are still installed. Misuse can produce a
broken environment where a package is present but its dependencies are missing.

In workspaces, use `--frozen` instead of `--locked` for the initial dependency-only
sync, because uv cannot validate the full lockfile without all workspace member
`pyproject.toml` files present.

### Malware checks (preview)

Setting `UV_MALWARE_CHECK=1` enables a lightweight scan of the lockfile against the
[OSV](https://osv.dev) malicious-packages database during sync. If a locked dependency
matches a MAL advisory, the sync is terminated. This feature is in preview and subject
to change.

## Examples

```bash
# Assert lockfile is up-to-date in CI; fail if drift detected
uv lock --check

# Upgrade a single dependency, keep everything else pinned
uv lock --upgrade-package requests

# Install project with optional "docs" extra
uv sync --extra docs

# Install all dependency groups
uv sync --all-groups

# CI: use exact lockfile, no drift allowed
uv run --locked pytest

# CI: skip all lockfile checks (fastest; lockfile already validated upstream)
uv run --frozen pytest
```

```dockerfile
# Docker: separate dependency layer from project layer for cache efficiency
FROM python:3.12-slim
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
WORKDIR /app

# Layer 1: dependencies only (cached until uv.lock or pyproject.toml changes)
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --locked --no-install-project

# Layer 2: project code + final sync
COPY . /app
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked
```

## Caveats / Common Mistakes

- `--locked` and `--frozen` are not the same: `--locked` asserts currency and errors on
  drift; `--frozen` skips the check entirely and uses whatever is in the lockfile.
- `uv sync` removes unlisted packages by default. If you have manually pip-installed
  packages in the environment, they will be removed. Use `--inexact` to suppress this.
- Partial install flags (`--no-install-*`) silence errors about missing project code, but
  if applied incorrectly they can leave a dependency without its own sub-dependencies
  installed — the environment will be broken at runtime.
- In workspaces, `--locked` requires all `pyproject.toml` files to be present. Use
  `--frozen` when workspace member files have not been copied yet (e.g., first Docker layer).
- Group exclusions take unconditional precedence: `--all-groups --no-group foo` still
  excludes `foo`.
- New package releases on PyPI do not trigger lockfile staleness. Run
  `uv lock --upgrade` intentionally rather than expecting automatic upgrades.

## See Also

- concept-lockfile
- cmd-sync
- cmd-lock
- project-dependency-groups
- integration-docker
