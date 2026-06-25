---
id: project-workspaces
title: "Workspaces: multi-package monorepos"
category: projects
tags: [workspace, project, lockfile, dependency, resolution]
source: https://docs.astral.sh/uv/concepts/projects/workspaces/
related: [project-structure, concept-lockfile, dep-sources, project-run, cmd-sync]
---

## Summary

A uv workspace groups multiple Python packages in a single repository under a shared lockfile,
enabling consistent dependency resolution across all members while letting each package define
its own `pyproject.toml`.

## Syntax / Usage

```toml
# workspace root pyproject.toml
[tool.uv.workspace]
members = ["packages/*"]   # required — glob(s) of member directories
exclude = ["packages/foo"] # optional — glob(s) to omit from members
```

```bash
uv lock                          # lock the entire workspace at once
uv sync                          # sync the workspace root
uv sync --package bird-feeder    # sync a specific member
uv run --package bird-feeder pytest  # run in a specific member
```

## Details

### Workspace root

Adding a `[tool.uv.workspace]` table to a `pyproject.toml` makes that package the workspace
root. The root is itself a workspace member. Running `uv init` inside an existing workspace
automatically adds the new project and, if needed, creates the `[tool.uv.workspace]` table in
the root.

### members and exclude globs

`members` is required and takes a list of glob patterns. Every directory matched by `members`
(and not excluded by `exclude`) must contain a `pyproject.toml`. Members can be applications
or libraries — both are supported.

### Shared lockfile

`uv lock` resolves the entire workspace at once and writes a single `uv.lock` at the workspace
root. All members share this lockfile, which guarantees a consistent set of pinned dependencies
across the repo.

### uv run and uv sync with --package

By default, `uv run` and `uv sync` target the workspace root. Pass `--package <name>` to target
a specific member; the command can be run from any directory within the workspace tree.

### Workspace sources (`workspace = true`)

To declare an inter-member dependency, list the member in `project.dependencies` and add a
`workspace = true` source in `[tool.uv.sources]`. Workspace member dependencies are always
installed as editables.

```toml
[project]
dependencies = ["bird-feeder"]

[tool.uv.sources]
bird-feeder = { workspace = true }
```

### Root sources inheritance

Any `[tool.uv.sources]` entries in the workspace root apply to all members unless a specific
member overrides them. Override is all-or-nothing per dependency: if a member provides any
source for a given package, it ignores the root's source for that package entirely — even if
the member's source is guarded by a marker that doesn't match the current platform.

### Single requires-python constraint

uv computes the effective `requires-python` for the workspace as the intersection of all
members' `requires-python` values. This single intersected range governs the entire lockfile.

### Virtual (non-installed) workspace members

A workspace member that is not listed as a dependency of any other member and has no build
system declared is treated as virtual: it is not installed as a package, but its dependencies
are still included in the lockfile and the shared environment. To force a member to be treated
as virtual, set `tool.uv.package = false` in its `pyproject.toml`.

## Examples

**Minimal workspace layout:**

```text
albatross/
├── pyproject.toml       # workspace root; declares [tool.uv.workspace]
├── uv.lock              # single shared lockfile
├── src/albatross/
└── packages/
    ├── bird-feeder/
    │   ├── pyproject.toml
    │   └── src/bird_feeder/
    └── seeds/           # excluded via exclude glob — not a member
        ├── pyproject.toml
        └── src/seeds/
```

**Root `pyproject.toml` with a workspace source and an excluded member:**

```toml
[project]
name = "albatross"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = ["bird-feeder", "tqdm>=4,<5"]

[tool.uv.sources]
bird-feeder = { workspace = true }
tqdm = { git = "https://github.com/tqdm/tqdm" }

[tool.uv.workspace]
members = ["packages/*"]
exclude = ["packages/seeds"]

[build-system]
requires = ["uv_build>=0.11.24,<0.12"]
build-backend = "uv_build"
```

Every member inherits the `tqdm` git source from the root unless it overrides it.

**Targeting a member from anywhere in the repo:**

```bash
# from the workspace root
uv run --package bird-feeder pytest tests/

# sync only one member's environment
uv sync --package bird-feeder
```

## Caveats / Common Mistakes

- **Conflicting requirements across members** make the entire workspace unresolvable. Use
  path dependencies instead of workspaces when members genuinely need incompatible versions
  of a shared package.
- **Single requires-python intersection**: if one member requires `>=3.12` and another
  `>=3.10,<3.12`, the intersection is empty and the lock will fail. Use `uv pip` with a
  separate virtual environment to test such a member in isolation.
- **`uv run --package` is unavailable with path dependencies.** If you switch from a
  workspace to plain path dependencies, you must `cd` into the member directory before
  running commands.
- **No import isolation**: uv cannot prevent a workspace package from importing symbols
  declared in a sibling member's dependencies. Only declared dependencies are guaranteed
  to be available by the lockfile.
- **Root source override is all-or-nothing per dependency**: a member that provides
  `tool.uv.sources` for a given package suppresses the root's entry for that package
  entirely, even if the member's source has a non-matching platform marker.

## See Also

- project-structure
- concept-lockfile
- dep-sources
- project-run
- cmd-sync
