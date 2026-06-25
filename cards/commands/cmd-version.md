---
id: cmd-version
title: uv version — read or update the project version
category: commands
tags: [command, project, build, publish]
source: https://docs.astral.sh/uv/reference/cli/#uv-version
related: [cmd-init, project-structure, bp-uv-version, cmd-self, dep-add]
---

## Summary

`uv version` reads or updates the version field in `pyproject.toml`. It is the
canonical way to bump a project version without hand-editing the file, and supports
both exact string assignment and semantic-version component bumping.

## Syntax / Usage

```bash
uv version [OPTIONS] [VALUE]
```

`VALUE` is an optional positional argument. When provided, the project version is
set to that exact string. When omitted, the current version is printed.

## Details

`uv version` operates on the current project's `pyproject.toml`. Running it with
no arguments displays the project name and version:

```
example 0.1.0
```

When `VALUE` is supplied, the version is updated in-place. When `--bump` is used
instead, the version is incremented according to the requested semantic-versioning
component.

`--bump` can be passed multiple times in a single invocation to chain increments
(e.g., bump `major` then `dev`). When a version is written, uv also locks and syncs
the project so the lockfile and environment reflect the new version.

Key flags:

- `VALUE` — set the version to this exact string (mutually exclusive with `--bump`).
- `--bump <component>` — increment a version component. Can be repeated. Components:
  - `major` — `1.2.3` => `2.0.0`
  - `minor` — `1.2.3` => `1.3.0`
  - `patch` — `1.2.3` => `1.2.4`
  - `stable` — strip pre-release/post/dev suffixes (`1.2.3b4.post5.dev6` => `1.2.3`)
  - `alpha` — `1.2.3a4` => `1.2.3a5`
  - `beta` — `1.2.3b4` => `1.2.3b5`
  - `rc` — `1.2.3rc4` => `1.2.3rc5`
  - `post` — `1.2.3.post5` => `1.2.3.post6`
  - `dev` — `1.2.3a4.dev6` => `1.2.3.dev7`
- `--short` — print only the version number, without the project name prefix.
- `--dry-run` — display the new version without writing it to `pyproject.toml`.
- `--output-format <text|json>` — control output format (default: `text`).
- `--package <name>` — target a specific member in a workspace.

## Examples

```bash
# Read the current version
uv version
# example 0.1.0

# Print just the version number
uv version --short
# 0.1.0

# Set an exact version
uv version 1.2.3

# Bump the patch component
uv version --bump patch
# example 0.1.0 => 0.1.1

# Bump the major version
uv version --bump major
# example 0.1.0 => 1.0.0

# Preview a bump without writing
uv version --bump minor --dry-run
# example 0.1.0 => 0.2.0 (dry run)

# Output as JSON
uv version --output-format json

# Update a specific workspace member
uv version --package my-lib --bump patch

# Bump pre-release components
uv version --bump beta
# example 0.2.0b1 => 0.2.0b2
```

## Caveats / Common Mistakes

- **`uv version` vs `uv self version` / `uv --version`**: `uv version` manages the
  *project's* version in `pyproject.toml`. To display the installed version of uv
  itself, use `uv self version` or `uv --version`. Before uv 0.7.0, `uv version`
  performed the latter role; this changed as a breaking change in 0.7.0.
- When run outside a project directory with no `pyproject.toml`, uv 0.7.x falls back
  to displaying the uv installer version with a deprecation warning. Passing `--preview`
  converts this fallback into an error.
- `--bump` for pre-release components (`alpha`, `beta`, `rc`, `post`, `dev`) requires
  the current version to already include that pre-release segment, or the bump will
  introduce one. Full pre-release bump support (including creating new pre-release
  segments) was added in uv 0.7.x.
- When a version is written, uv also updates the lockfile and syncs the environment.
  Use `--dry-run` to preview changes without triggering a sync.

## See Also

- cmd-init
- project-structure
- bp-uv-version
- cmd-self
- dep-add
