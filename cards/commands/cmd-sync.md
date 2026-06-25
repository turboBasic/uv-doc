---
id: cmd-sync
title: uv sync — install project dependencies into the environment
category: commands
tags: [command, project, dependency, lockfile, venv, installation, ci]
source: https://docs.astral.sh/uv/concepts/projects/sync/
related: [cmd-lock, concept-lockfile, project-sync-lock, dep-groups, project-workspaces]
---

## Summary

`uv sync` installs the project's dependencies into the virtual environment, ensuring
it exactly matches the lockfile. It is the explicit form of the sync step that `uv run`
performs automatically before every command.

## Syntax / Usage

```bash
uv sync [OPTIONS]
```

## Details

### Exact sync (default)

By default, `uv sync` performs an _exact_ sync: packages present in the environment
that are not declared in the lockfile are removed. To retain extraneous packages, pass
`--inexact` (alias `--no-exact`). Note that if an extraneous package conflicts with a
project dependency it is still removed, even with `--inexact`.

`uv run` uses inexact syncing by default; pass `--exact` to `uv run` to opt into
exact behaviour there.

### Lockfile handling

- Default — re-locks if the lockfile is out of date, then syncs.
- `--locked` — asserts the lockfile is current; exits with an error if it needs
  updating. Useful in CI to catch uncommitted lockfile changes.
- `--frozen` — uses the lockfile as-is without checking whether it is up to date.
  Exits with an error if the lockfile is missing.

`UV_LOCKED` and `UV_FROZEN` environment variables provide the same effect.

### Extras (optional dependencies)

Extras declared in `[project.optional-dependencies]` are not included by default.

- `--extra <name>` — include a named extra; may be repeated.
- `--all-extras` — include every declared extra.
- `--no-extra <name>` — exclude a specific extra when `--all-extras` is used.

When extras are declared as conflicting in `tool.uv.conflicts`, using `--all-extras`
always raises an error.

### Dependency groups

The `dev` group (from `[dependency-groups]`) is included by default. All other groups
are opt-in.

| Flag | Effect |
|---|---|
| `--group <name>` | Include a named group (repeatable). |
| `--no-group <name>` | Exclude a named group; always takes precedence over inclusions. |
| `--all-groups` | Include every declared group. |
| `--no-default-groups` | Ignore groups listed in `tool.uv.default-groups`. |
| `--no-dev` | Exclude the `dev` group (alias for `--no-group dev`). |
| `--only-dev` | Install only the `dev` group; omit the project and its dependencies. |
| `--only-group <name>` | Install only that group; omit project deps and default groups. |

Group exclusions always take precedence: `--no-group foo --group foo` results in `foo`
not being installed.

### Partial installations

These flags are designed for layered Docker builds where dependency installation and
project installation happen in separate steps:

- `--no-install-project` — omit the current project but install all its dependencies.
- `--no-install-workspace` — omit all workspace members (including the root project)
  but install their dependencies.
- `--no-install-package <pkg>` — omit a specific package but install its dependencies.
- `--no-install-local` — skip all local path/editable packages; install only
  remote/indexed dependencies.

Each flag has an inverse (`--only-install-project`, `--only-install-workspace`,
`--only-install-package <pkg>`, `--only-install-local`).

Using these flags improperly can produce a broken environment — a package may be
missing its own dependencies.

### Editable installs

The project and workspace members are installed as editable packages by default, so
source changes are reflected without re-syncing. Pass `--no-editable` to install them
as non-editable distributions instead.

If the project does not define a build system, it will not be installed at all.

### Active virtual environment (`--active`)

When `VIRTUAL_ENV` is set, `--active` instructs uv to sync into that environment
instead of creating or updating the project's own `.venv`.

### Workspace packages

- `--all-packages` — sync all workspace members into the shared `.venv`.
- `--package <name>` — sync only the specified workspace member's subset of
  dependencies.

### Malware checks (preview)

While syncing, uv can scan the lockfile against OSV MAL advisories from the
[OpenSSF malicious packages database](https://github.com/ossf/malicious-packages).
If a locked dependency matches a malware advisory, the sync is terminated.

Enable with `UV_MALWARE_CHECK=1`. This feature is in preview and subject to change.

### Dry run

`--dry-run` resolves dependencies and reports what would change in the lockfile and
environment without writing anything.

## Examples

```bash
# Basic sync — re-lock if needed, then install
uv sync

# CI: fail if lockfile is not committed up-to-date
uv sync --locked

# CI: use lockfile as-is, no staleness check
uv sync --frozen

# Include the "docs" extra and the "lint" group
uv sync --extra docs --group lint

# Include all extras and all groups
uv sync --all-extras --all-groups

# Exclude the dev group
uv sync --no-dev

# Install only the lint group's packages (no project deps)
uv sync --only-group lint

# Docker layer 1: install only third-party deps, skip local project
uv sync --no-install-project

# Docker layer 2: install the project on top of the cached deps layer
uv sync --no-deps

# Install everything as non-editable (e.g. for production containers)
uv sync --no-editable

# Sync into an already-activated virtualenv
uv sync --active

# Dry run — see what would change without modifying anything
uv sync --dry-run

# Enable malware scanning (preview)
UV_MALWARE_CHECK=1 uv sync
```

## Caveats / Common Mistakes

- **Default is exact.** `uv sync` removes packages not in the lockfile. If you have
  manually installed packages into `.venv` for debugging, they will be removed. Use
  `--inexact` if you need to preserve them.
- **`--frozen` vs `--locked`.** `--frozen` trusts the lockfile blindly (stale metadata
  silently not applied); `--locked` validates it is current and errors otherwise.
  For strict CI, `--locked` is the safer choice.
- **Group exclusions win.** Passing both `--group foo` and `--no-group foo` always
  excludes `foo`.
- **Partial install flags can break the environment.** Packages omitted via
  `--no-install-*` may be missing transitive dependencies of other installed packages.
  These flags are intended for multi-step Docker builds, not general use.
- **`--no-build-isolation` disables extraneous package removal.** When
  `--no-build-isolation` is active, uv will not remove extraneous packages to avoid
  stripping possible build dependencies.
- **Malware check is preview.** `UV_MALWARE_CHECK=1` behaviour may change without a
  deprecation cycle until the feature is stabilised.

## See Also

- cmd-lock
- concept-lockfile
- project-sync-lock
- dep-groups
- project-workspaces
