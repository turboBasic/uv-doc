---
id: project-dependency-groups
title: "Dependency groups: dev, custom groups, and default-groups"
category: projects
tags: [project, dependency, config, lockfile]
source: https://docs.astral.sh/uv/concepts/projects/dependencies/#development-dependencies
related: [dep-add, project-sync-lock, project-structure, dep-optional, project-conflicting-deps, project-migrate-from-pip]
---

## Summary

Dependency groups (`[dependency-groups]`, PEP 735) are the standard way to declare
local-only development dependencies that are never published to PyPI. uv provides the
`dev` group by default, arbitrary named groups via `--group`, and a `default-groups`
setting to control what is synced automatically.

## Syntax / Usage

```bash
# Add to the default dev group
uv add --dev pytest

# Add to a named group
uv add --group lint ruff

# Sync only specific groups
uv sync --only-group lint
uv sync --no-dev
uv sync --all-groups
uv sync --no-default-groups --group test
```

## Details

### The `[dependency-groups]` table

Dependency groups are declared in the top-level `[dependency-groups]` table (not under
`[tool.uv]`). Each key is a group name; each value is a list of PEP 508 dependency
specifiers and/or `{include-group = "<name>"}` entries.

```toml
[dependency-groups]
dev = ["pytest>=8.1"]
lint = ["ruff"]
```

Groups are local-only: they are not included in the wheel metadata when the package is
published.

### The special `dev` group

`--dev` is shorthand for `--group dev`. Likewise:

| Flag | Equivalent |
|---|---|
| `--dev` | `--group dev` |
| `--only-dev` | `--only-group dev` |
| `--no-dev` | `--no-group dev` |

The `dev` group is synced by default (see [Default groups](#default-groups) below).

### Custom named groups

Any group name is valid. Add dependencies with `uv add --group <name> <pkg>`. Include
or exclude groups at sync/run time with the flags below.

### Group selection flags

| Flag | Behaviour |
|---|---|
| `--all-groups` | Include every defined group |
| `--group <name>` | Include a specific group (additive) |
| `--only-group <name>` | Include only this group; excludes the project itself and all default groups |
| `--no-group <name>` | Exclude a specific group |
| `--no-default-groups` | Disable all default groups |

Exclusions take precedence over inclusions: `--no-group foo --group foo` results in
`foo` not being installed.

### Group nesting with `include-group`

A group can include another group by embedding `{include-group = "<name>"}` entries:

```toml
[dependency-groups]
dev = [
  {include-group = "lint"},
  {include-group = "test"}
]
lint = ["ruff"]
test = ["pytest"]
```

An included group's dependencies must not conflict with those of the including group.

### Default groups

The `tool.uv.default-groups` setting controls which groups are installed automatically
during `uv run` and `uv sync`. It defaults to `["dev"]`.

```toml
[tool.uv]
default-groups = ["dev", "docs"]
```

To enable all groups by default:

```toml
[tool.uv]
default-groups = "all"
```

Disable default groups at the command line with `--no-default-groups`, or exclude a
single default group with `--no-group <name>`.

### Group `requires-python` override

If a dependency group requires a different Python range than the project, declare it
under `[tool.uv.dependency-groups]` (not `[dependency-groups]`):

```toml
[tool.uv.dependency-groups]
dev = {requires-python = ">=3.12"}
```

This table is for metadata only; the actual dependencies belong in `[dependency-groups]`.

### Legacy `tool.uv.dev-dependencies`

Before PEP 735 was standardized, uv used:

```toml
[tool.uv]
dev-dependencies = ["pytest"]
```

This field is still supported. Its contents are combined with `dependency-groups.dev`
to form the final `dev` group. When `tool.uv.dev-dependencies` is present, `uv add
--dev` appends to that field instead of creating `dependency-groups.dev`. The field
is deprecated and will eventually be removed; new projects should use
`[dependency-groups]`.

## Examples

```toml
# pyproject.toml — typical multi-group setup
[dependency-groups]
dev = [
  {include-group = "lint"},
  {include-group = "test"}
]
lint = ["ruff>=0.5"]
test = ["pytest>=8", "pytest-cov"]
docs = ["mkdocs-material"]

[tool.uv]
default-groups = ["dev"]          # only dev (and its includes) by default

[tool.uv.dependency-groups]
test = {requires-python = ">=3.12"}   # test tooling needs 3.12+
```

```bash
# CI: install only test dependencies, not the project package
uv sync --only-group test

# Local dev: install everything
uv sync --all-groups

# Production: skip all dev deps
uv sync --no-default-groups
```

## Caveats / Common Mistakes

- `--only-group` excludes the project itself (not just other groups). If you need the
  project installed alongside the group, use `--group` instead.
- All groups are resolved together into a single lockfile. If two groups require
  incompatible versions of the same package, resolution fails unless the groups are
  declared as conflicting in `[tool.uv.conflict]`.
- `[tool.uv.dependency-groups]` is for metadata (e.g. `requires-python`), not for
  defining group membership. Define membership in the top-level `[dependency-groups]`.
- When `tool.uv.dev-dependencies` exists, `uv add --dev` will not create
  `dependency-groups.dev`; it adds to the legacy field instead. Migrate manually.
- `tool.uv.sources` entries apply to dependency groups the same way they do to
  `project.dependencies`.

## See Also

- dep-add
- project-sync-lock
- project-structure
- dep-optional
- project-conflicting-deps
- project-migrate-from-pip
