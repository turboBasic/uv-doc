---
id: project-conflicting-deps
title: "Conflicting dependencies: extras, groups, and limited environments"
category: projects
tags: [project, resolution, dependency, lockfile, config]
source: https://docs.astral.sh/uv/concepts/projects/config/#conflicting-dependencies
related: [concept-conflicting-dependencies, concept-universal-resolution, project-dependency-groups, dep-optional, project-workspaces]
---

## Summary

uv resolves all project dependencies — including optional dependencies (extras) and
dependency groups — together in a single universal lockfile pass. When two extras or
groups require incompatible versions of the same package, resolution fails unless you
declare them as explicitly conflicting via `tool.uv.conflicts`. Two companion settings,
`tool.uv.environments` and `tool.uv.required-environments`, let you narrow or enforce
platform coverage in the lockfile.

## Syntax / Usage

```toml
# Declare conflicting extras
[tool.uv]
conflicts = [
    [
        { extra = "extra1" },
        { extra = "extra2" },
    ],
]

# Declare conflicting dependency groups
[tool.uv]
conflicts = [
    [
        { group = "group1" },
        { group = "group2" },
    ],
]

# Constrain lockfile to specific platforms
[tool.uv]
environments = [
    "sys_platform == 'darwin'",
    "sys_platform == 'linux'",
]

# Require support for a specific platform
[tool.uv]
required-environments = [
    "sys_platform == 'darwin' and platform_machine == 'x86_64'",
]
```

## Details

### Why joint resolution fails

uv's universal resolver must find a single set of package versions satisfying every
declared dependency across all platforms and Python versions at once. This includes
`project.dependencies`, all `[project.optional-dependencies]` extras, and all
`[dependency-groups]` groups. If `extra1` pins `numpy==2.1.2` while `extra2` pins
`numpy==2.0.0`, there is no single numpy version satisfying both, and `uv lock` exits
with an unsatisfiability error.

### Declaring conflicts (`tool.uv.conflicts`)

Adding a conflict entry tells uv that the listed extras or groups are mutually exclusive
and should be resolved in separate forks. uv records both sets of pins in `uv.lock`.
Resolution succeeds, but `uv sync` will reject any invocation that tries to activate
conflicting sets simultaneously:

```
error: extra `extra1`, extra `extra2` are incompatible with the declared conflicts:
{`myproject[extra1]`, `myproject[extra2]`}
```

Each conflict set must contain at least two items. The `conflicts` key accepts a
`list[list[dict]]`; each inner list is one conflict set, each dict uses either `extra`
or `group` to identify the member.

For workspace scenarios, add a `package` key alongside `extra` or `group` to target a
specific workspace member:

```toml
[tool.uv]
conflicts = [
    [
        { package = "member1", extra = "cpu" },
        { package = "member2", extra = "cuda" },
    ],
]
```

### Limited resolution environments (`tool.uv.environments`)

By default, the universal resolver considers all platforms and Python versions. If your
project only targets a subset, you can reduce the scope of the lockfile using
`environments`, which accepts PEP 508 environment markers. This prevents uv from trying
to resolve platform-specific packages (e.g., Windows-only wheels) that your project will
never use.

Entries must be disjoint: `sys_platform == 'darwin'` and `sys_platform == 'linux'` are
disjoint; `sys_platform == 'darwin'` and `python_version >= '3.9'` are not.

### Required environments (`tool.uv.required-environments`)

`required-environments` takes the opposite approach: it ensures the resolved lockfile
includes wheels for specific platforms. This is relevant only for packages that publish
binary wheels but no source distribution (e.g., PyTorch), which cannot be built from
source. If no compatible wheel exists for a required environment, resolution fails.

While `environments` limits the set of environments uv considers, `required-environments`
expands the set of platforms uv must guarantee coverage for.

## Examples

### Conflicting extras (e.g., cpu vs. cuda builds)

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
# Lock succeeds; both forks are recorded in uv.lock
uv lock

# Install only the cpu variant
uv sync --extra cpu

# Install only the cuda variant
uv sync --extra cuda

# Rejected: cannot install both at the same time
uv sync --extra cpu --extra cuda
```

### Conflicting dependency groups

```toml title="pyproject.toml"
[dependency-groups]
group1 = ["numpy==2.1.2"]
group2 = ["numpy==2.0.0"]

[tool.uv]
conflicts = [
    [
        { group = "group1" },
        { group = "group2" },
    ],
]
```

```bash
uv sync --group group1    # OK
uv sync --group group2    # OK
uv sync --group group1 --group group2  # error
```

### Constraining the lockfile to Linux and macOS only

```toml title="pyproject.toml"
[tool.uv]
environments = [
    "sys_platform == 'darwin'",
    "sys_platform == 'linux'",
]
```

### Requiring Intel macOS wheel coverage

```toml title="pyproject.toml"
[tool.uv]
required-environments = [
    "sys_platform == 'darwin' and platform_machine == 'x86_64'",
]
```

## Caveats / Common Mistakes

- Without a `conflicts` declaration, `uv lock` fails with an unsatisfiability error
  rather than silently picking one version. Add the declaration before re-running
  `uv lock`.
- `conflicts` declarations belong only in `pyproject.toml` under `[tool.uv]`, not in
  `uv.toml`. In a workspace, they must be in the workspace root's `pyproject.toml`.
- Entries in `environments` must be disjoint. Non-disjoint entries cause resolution
  errors.
- `required-environments` is only meaningful for packages without a source distribution.
  It has no effect on packages that publish sdists, since those can be built on any
  platform.
- Even after declaring a conflict, installing both conflicting extras or groups in the
  same environment is blocked at install time by `uv sync`. There is no way to override
  this check.

## See Also

- concept-conflicting-dependencies
- concept-universal-resolution
- project-dependency-groups
- dep-optional
- project-workspaces
