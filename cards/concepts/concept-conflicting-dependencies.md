---
id: concept-conflicting-dependencies
title: Conflicting dependencies and the tool.uv.conflicts table
category: concepts
tags: [resolution, dependency, lockfile, project, workspace]
source: https://docs.astral.sh/uv/concepts/resolution/#conflicting-dependencies
related: [concept-resolution, dep-groups, dep-optional, project-workspaces, cmd-sync]
---

## Summary

uv resolves all extras and dependency groups together in a single universal pass. When two extras or groups pin incompatible versions of the same package, resolution fails. Declaring `tool.uv.conflicts` tells uv to fork those groups into separate resolution passes, allowing the lockfile to be generated while still preventing them from being installed simultaneously.

## Details

### Why joint resolution fails

uv's universal resolver must find a single set of package versions that satisfies every declared dependency — project dependencies, optional dependencies (extras), and dependency groups — across all platforms and Python versions at once. If `extra1` pins `numpy==2.1.2` and `extra2` pins `numpy==2.0.0`, there is no single version of numpy that satisfies both, so resolution fails with an unsatisfiable error.

### Declaring conflicts

Adding a conflict declaration tells uv that the listed extras or groups are mutually exclusive. uv then resolves them in separate forks and records both sets of pins in `uv.lock`. Resolution succeeds, but the lockfile encodes the incompatibility.

The `conflicts` key lives in `[tool.uv]` and accepts a list of conflict sets. Each conflict set is itself a list of items; each item identifies one extra or group using the `extra` or `group` key.

```toml title="pyproject.toml"
[tool.uv]
conflicts = [
    [
        { extra = "extra1" },
        { extra = "extra2" },
    ],
]
```

For dependency groups, substitute `group` for `extra`:

```toml title="pyproject.toml"
[tool.uv]
conflicts = [
    [
        { group = "group1" },
        { group = "group2" },
    ],
]
```

### Runtime enforcement

Once conflicts are declared, `uv sync` (and `uv run`) will reject any invocation that tries to activate both conflicting sets at once:

```
error: extra `extra1`, extra `extra2` are incompatible with the declared conflicts: {`myproject[extra1]`, `myproject[extra2]`}
```

This prevents two incompatible versions of a package from landing in the same environment.

### Workspace-level conflicts

In a workspace, extras or dependency groups from different members can also conflict. Use the `package` key alongside `extra` or `group` to identify the member:

```toml title="pyproject.toml (workspace root)"
[tool.uv]
conflicts = [
    [
        { package = "member1", extra = "extra1" },
        { package = "member2", extra = "extra2" },
    ],
]
```

If the conflict involves a member's base `project.dependencies` (not an extra), omit the `extra` key and specify only `package`:

```toml
[tool.uv]
conflicts = [
    [
        { package = "member1" },
        { package = "member2", extra = "extra2" },
    ],
]
```

When two workspace members have conflicting base dependencies, they cannot both be listed as dependencies of the workspace root.

## Examples

### Conflicting extras

```toml title="pyproject.toml"
[project]
name = "myproject"
version = "0.1.0"

[project.optional-dependencies]
cpu  = ["torch==2.2.0"]
cuda = ["torch==2.3.0+cu121"]

[tool.uv]
conflicts = [
    [
        { extra = "cpu" },
        { extra = "cuda" },
    ],
]
```

```bash
# Lock succeeds; each fork is recorded separately
uv lock

# Install only the cpu variant
uv sync --extra cpu

# This is rejected at runtime
uv sync --extra cpu --extra cuda
# error: extra `cpu`, extra `cuda` are incompatible with the declared conflicts
```

### Conflicting dependency groups

```toml title="pyproject.toml"
[dependency-groups]
lint  = ["ruff==0.4.0"]
mypy  = ["ruff==0.3.0"]   # hypothetical version pin conflict

[tool.uv]
conflicts = [
    [
        { group = "lint" },
        { group = "mypy" },
    ],
]
```

```bash
uv sync --group lint    # OK
uv sync --group mypy    # OK
uv sync --group lint --group mypy  # error
```

## Caveats / Common Mistakes

- Forgetting to declare a conflict causes `uv lock` to fail outright with an unsatisfiability error. Add the `conflicts` declaration first, then re-lock.
- Each conflict set must contain at least two items. A single-item set is meaningless and will not affect resolution.
- Conflict declarations live only in `[tool.uv]` inside `pyproject.toml`. They cannot be placed in `uv.toml`.
- In a workspace, conflict declarations go in the **workspace root's** `pyproject.toml` under `[tool.uv]`, not in individual member files.
- Conflicting workspace members whose base `project.dependencies` conflict cannot both appear as dependencies of the workspace root, even with a conflicts declaration.

## See Also

- concept-resolution
- dep-groups
- dep-optional
- project-workspaces
- cmd-sync
