---
id: dep-groups
title: Dependency groups (development dependencies)
category: dependencies
tags: [dependency, project, config, lockfile]
source: https://docs.astral.sh/uv/concepts/projects/dependencies/#dependency-groups
related: [dep-add, dep-optional, cmd-sync, project-sync-lock, config-files]
---

## Summary

Dependency groups (PEP 735) are local-only dependency sets declared in `[dependency-groups]`
that are excluded from published package metadata. The `dev` group is the canonical home for
development tools; additional named groups let you segment test, lint, docs, and other toolchains.

## Syntax / Usage

```bash
# Add to the default dev group
uv add --dev <package>

# Add to a named group
uv add --group <name> <package>

# Sync / run with group control
uv sync --all-groups
uv sync --only-group <name>
uv sync --no-group <name>
uv sync --no-default-groups
uv run --group <name> <command>
```

## Details

### The dev group and --dev flag

`uv add --dev` writes the dependency into a `dev` entry under `[dependency-groups]`.
The `dev` group is special-cased: `--dev`, `--only-dev`, and `--no-dev` are convenience
aliases for `--group dev`, `--only-group dev`, and `--no-group dev` respectively.
The `dev` group is synced by default during `uv run` and `uv sync`.

### Custom groups

Any name is valid. Use `uv add --group <name>` to create and populate custom groups
such as `lint`, `test`, or `docs`. Once defined, all group flags (`--all-groups`,
`--group`, `--only-group`, `--no-group`) apply.

Group exclusions always take precedence over inclusions: if you pass both
`--no-group foo` and `--group foo`, the group is excluded.

`--only-group` excludes the project itself and all default groups — only the named
group's dependencies are installed.

### Nesting groups with include-group

A group can include another group using the `{include-group = "<name>"}` syntax.
An included group's dependencies cannot conflict with the other dependencies in the
including group.

```toml
[dependency-groups]
dev = [
  {include-group = "lint"},
  {include-group = "test"}
]
lint = ["ruff"]
test = ["pytest"]
```

### default-groups setting

`tool.uv.default-groups` controls which groups are activated by default during
`uv run` and `uv sync`. The built-in default is `["dev"]`. Set it to a list of
group names or to the literal string `"all"` to activate all groups by default.

### Per-group requires-python

If a dependency group requires a different Python range than the project, declare it
in `[tool.uv.dependency-groups]`. This table only accepts `requires-python`; it cannot
define groups (use the top-level `[dependency-groups]` table for that).

### Lockfile behaviour

uv resolves all dependency groups together when creating `uv.lock`. If two groups
declare incompatible requirements, resolution fails unless the groups are explicitly
declared as conflicting.

### Legacy tool.uv.dev-dependencies

Before `[dependency-groups]` was standardized, uv used `tool.uv.dev-dependencies`.
Its contents are combined with `dependency-groups.dev` at resolve time. When this
legacy field is present, `uv add --dev` continues to write to it rather than creating
a new `dependency-groups.dev` section. Prefer `[dependency-groups]` for new projects.

## Examples

```bash
# Add pytest to dev and ruff to a lint group
uv add --dev pytest
uv add --group lint ruff
```

Resulting `pyproject.toml`:

```toml
[dependency-groups]
dev = ["pytest>=8.1.1,<9"]
lint = ["ruff>=0.4.0"]
```

---

```bash
# Activate all groups during sync
uv sync --all-groups

# Install only the test group (no project, no dev)
uv sync --only-group test

# Run a command with the docs group included on top of defaults
uv run --group docs mkdocs build

# Disable all defaults and include only lint
uv sync --no-default-groups --group lint
```

---

Changing which groups are active by default:

```toml
[tool.uv]
default-groups = ["dev", "test"]   # specific list
# or
default-groups = "all"             # every defined group
```

---

Per-group Python requirement:

```toml
[project]
requires-python = ">=3.10"

[dependency-groups]
dev = ["pytest"]

[tool.uv.dependency-groups]
dev = {requires-python = ">=3.12"}
```

---

Nested groups:

```toml
[dependency-groups]
dev = [
  {include-group = "lint"},
  {include-group = "test"}
]
lint = ["ruff"]
test = ["pytest"]
```

## Caveats / Common Mistakes

- `[dependency-groups]` is PEP 735 and may not be supported by tools other than uv.
  If you need cross-tool compatibility, `[project.optional-dependencies]` (extras) may
  be more appropriate, at the cost of the groups appearing in published metadata.
- When `tool.uv.dev-dependencies` already exists, `uv add --dev` appends to it instead
  of creating `dependency-groups.dev`. Migrate by moving entries to `[dependency-groups]`
  and removing the legacy field.
- `--only-group` implies `--no-default-groups`, so combining it with `--group dev`
  still excludes all other defaults.
- Group exclusions take precedence: `--no-group foo --group foo` results in `foo` being
  excluded, not included.
- Conflicting requirements across groups cause resolution failure unless the groups are
  declared as conflicting in `[tool.uv.conflicting-groups]`.

## See Also

- dep-add
- dep-optional
- cmd-sync
- project-sync-lock
- config-files
