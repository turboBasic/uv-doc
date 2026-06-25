---
id: bp-uv-version
title: "uv version: reading and bumping package versions"
category: build-publish
tags: [command, build, publish, project]
source: https://docs.astral.sh/uv/reference/cli/#uv-version
related: [bp-build-publish, project-packaging, cmd-sync, cmd-lock, bp-trusted-publishing]
---

## Summary

`uv version` reads or updates the version field in `pyproject.toml`. It covers bare
reads, exact-value writes, and semantic bumps across all PEP 440 components, with a
`--dry-run` preview mode and flags to suppress the lock/sync side effects that run by
default.

## Syntax / Usage

```bash
uv version [OPTIONS] [VALUE]
```

- Omit `VALUE` and `--bump` to read the current version.
- Provide `VALUE` to set an exact version.
- Use `--bump <component>` to increment a version component.

## Details

### Reading the version

Running `uv version` with no arguments prints the package name and version:

```
hello-world 0.7.0
```

Pass `--short` to suppress the package name and emit only the bare version string.
Pass `--output-format json` for machine-readable output including `package_name`,
`version`, and `commit_info`.

### Setting an explicit version

Provide the target version as a positional argument:

```bash
uv version 1.0.0
```

uv prints the old and new values (`hello-world 0.7.0 => 1.0.0`) and writes the change
to `pyproject.toml`.

### Bumping with `--bump`

`--bump <component>` increments a PEP 440 version component. Supported components:

| Component | Effect |
|-----------|--------|
| `major`   | `1.2.3 => 2.0.0` |
| `minor`   | `1.2.3 => 1.3.0` |
| `patch`   | `1.2.3 => 1.2.4` |
| `stable`  | `1.2.3b4.post5.dev6 => 1.2.3` (clears pre-release) |
| `alpha`   | `1.2.3a4 => 1.2.3a5` |
| `beta`    | `1.2.3b4 => 1.2.3b5` |
| `rc`      | `1.2.3rc4 => 1.2.3rc5` |
| `post`    | `1.2.3.post5 => 1.2.3.post6` |
| `dev`     | `1.2.3a4.dev6 => 1.2.3.dev7` |

`--bump` can be provided multiple times. Components are applied in order from largest
(`major`) to smallest (`dev`).

An optional numeric value pins the resulting component explicitly:
`--bump <component>=<value>` (e.g., `--bump dev=66463664`).

### Lock and sync side effects

By default, after writing a new version uv re-locks the project and syncs the
environment. Two flags suppress this:

- `--frozen` — updates `pyproject.toml` but skips both lock and sync.
- `--no-sync` — re-locks but skips the environment sync.

### Workspace packages

Use `--package <name>` to target a specific member of a workspace instead of the root
package.

## Examples

```bash
# Read current version (shows "hello-world 0.7.0")
uv version

# Read bare version string only
uv version --short

# Read version as JSON
uv version --output-format json

# Set an exact version
uv version 1.0.0

# Preview a change without writing it
uv version 2.0.0 --dry-run

# Bump the minor component
uv version --bump minor

# Release a new beta from a stable version
uv version --bump patch --bump beta
# hello-world 1.3.0 => 1.3.1b1

# Advance through pre-releases
uv version --bump beta
# hello-world 1.3.0b1 => 1.3.0b2

# Promote a pre-release to stable
uv version --bump stable
# hello-world 1.3.1b2 => 1.3.1

# Set a dev build with an explicit dev number
uv version --bump patch --bump dev=66463664
# hello-world 0.0.1 => 0.0.2.dev66463664

# Bump without triggering lock or sync
uv version --bump minor --frozen

# Bump and re-lock but skip env sync
uv version --bump minor --no-sync

# Target a workspace member
uv version --package mylib --bump patch
```

## Caveats / Common Mistakes

- By default `uv version` triggers a lock and sync on every write. In CI or scripted
  release pipelines, pass `--frozen` or `--no-sync` to avoid unexpected network
  activity or environment mutations.
- To start a pre-release from a stable version you must bump a base component (`major`,
  `minor`, or `patch`) **together** with the pre-release component in the same
  invocation. Bumping only `alpha`/`beta`/`rc` from a stable version will not produce
  the expected result.
- `--dry-run` does not write to `pyproject.toml`; verify with a bare `uv version` call
  afterwards to confirm the file was not changed.

## See Also

- bp-build-publish
- project-packaging
- cmd-sync
- cmd-lock
- bp-trusted-publishing
