---
id: config-project-env-settings
title: Project environment settings — venv path, conflicts, and resolution environments
category: configuration
tags: [config, venv, resolution, project, lockfile]
source: https://docs.astral.sh/uv/concepts/projects/config/#project-environment-path
related: [concept-project-environment, project-conflicting-deps, dep-platform-environments, cmd-sync, config-resolution-settings]
---

## Summary

Three `[tool.uv]` settings control where the project virtual environment lives
(`UV_PROJECT_ENVIRONMENT`), which extras or dependency groups are mutually exclusive
(`conflicts`), and which platforms the lockfile must cover (`environments`,
`required-environments`).

## Syntax / Usage

```toml
# pyproject.toml

[tool.uv]
# Declare extras that cannot be installed together
conflicts = [
    [
        { extra = "extra1" },
        { extra = "extra2" },
    ],
]

# Limit lockfile resolution to specific platforms
environments = [
    "sys_platform == 'darwin'",
    "sys_platform == 'linux'",
]

# Require that binary-only packages supply wheels for these platforms
required-environments = [
    "sys_platform == 'darwin' and platform_machine == 'x86_64'",
]
```

```bash
# Override venv path at runtime
UV_PROJECT_ENVIRONMENT=/opt/myenv uv sync

# Use the currently active virtual environment instead of the project's .venv
uv sync --active

# Silence the warning when VIRTUAL_ENV points elsewhere
uv sync --no-active
```

## Details

### UV_PROJECT_ENVIRONMENT

The environment variable `UV_PROJECT_ENVIRONMENT` overrides the default `.venv`
location inside the workspace root.

- **Relative path**: resolved relative to the workspace root; uv creates a subdirectory
  at that path.
- **Absolute path**: used as-is — uv does not append a child directory. If the path
  spans multiple projects, each `uv sync` invocation will overwrite the same environment.
  This setting is therefore recommended only for single-project CI or Docker images.
- If the path does not exist, uv creates the environment there.
- Setting this variable to the Python installation prefix (e.g. `/usr/local` on
  Debian-based systems) targets the system environment. Using `uv sync` against a system
  environment is risky because uv removes extraneous packages by default.

### VIRTUAL_ENV interaction and --active / --no-active

By default, uv **ignores** the `VIRTUAL_ENV` environment variable during project
operations. If `VIRTUAL_ENV` points to a different path than the project environment,
uv prints a warning.

- `--active` opts in to respecting `VIRTUAL_ENV`: uv will sync to or run inside the
  active virtual environment instead of the project's `.venv`.
- `--no-active` suppresses the warning without changing behavior.

### tool.uv.conflicts

uv resolves all project dependencies — including optional extras and dependency groups —
in a single universal pass. If two extras or groups require incompatible versions of the
same package, resolution fails.

`conflicts` declares which extras or groups are mutually exclusive, allowing uv to
resolve them in separate forks and produce a valid lockfile despite the incompatibility.
In exchange, attempting to install both conflicting sets at the same time (e.g.
`uv sync --extra extra1 --extra extra2`) will fail with an explicit error.

Each element in `conflicts` is a list of two or more conflict members. A member is a
dict with one of these keys:

- `extra = "<name>"` — an optional dependency extra of the current project.
- `group = "<name>"` — a dependency group.
- `package = "<name>"` combined with `extra` or `group` — an extra or group belonging
  to a specific workspace member.

**Default value**: `[]`  **Type**: `list[list[dict]]`

### tool.uv.environments

By default, the universal resolver solves for all platforms and Python versions. Use
`environments` to restrict the set of platforms the lockfile covers, reducing resolution
time and avoiding unsatisfiable branches.

Entries are PEP 508 environment markers. They **must be disjoint** — overlapping
entries (e.g. `sys_platform == 'darwin'` alongside `python_version >= '3.9'`) are not
allowed because both could be true simultaneously.

This setting also applies when `uv pip compile --universal` is invoked.

**Default value**: `[]`  **Type**: `str | list[str]`

### tool.uv.required-environments

Some packages (like PyTorch) publish only wheels, no source distributions. The universal
resolver must find a compatible wheel for every platform it considers. By default, uv
requires each such package to supply at least one wheel compatible with the target Python
version.

`required-environments` tightens this: it lists platforms for which a wheel **must**
exist or resolution fails. This is useful for ensuring binary-only dependencies cover
specific non-latest platforms (e.g. Intel macOS, x86-64 Linux) where backtracking to
older versions may be needed.

`environments` *limits* the platform set; `required-environments` *expands* the
mandatory coverage within that set (or within the default universal set).

**Default value**: `[]`  **Type**: `str | list[str]`

## Examples

**Custom venv path for Docker:**

```bash
UV_PROJECT_ENVIRONMENT=/app/.venv uv sync --no-dev
```

**Conflicting extras (different numpy versions per ML backend):**

```toml
[project.optional-dependencies]
cpu = ["numpy==2.0.0"]
gpu = ["numpy==2.1.2"]

[tool.uv]
conflicts = [
    [
        { extra = "cpu" },
        { extra = "gpu" },
    ],
]
```

`uv lock` succeeds. `uv sync --extra cpu --extra gpu` fails with a clear error.

**Conflicting dependency groups:**

```toml
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

**Linux-only lockfile (skip Windows and macOS solver branches):**

```toml
[tool.uv]
environments = ["sys_platform == 'linux'"]
```

**Require Intel macOS wheels for binary-only packages:**

```toml
[tool.uv]
required-environments = [
    "sys_platform == 'darwin' and platform_machine == 'x86_64'",
]
```

**Workspace-level conflict across members:**

```toml
# workspace root pyproject.toml
[tool.uv]
conflicts = [
    [
        { package = "member1", extra = "extra1" },
        { package = "member2", extra = "extra2" },
    ],
]
```

## Caveats / Common Mistakes

- Using an absolute `UV_PROJECT_ENVIRONMENT` path across multiple projects will cause
  each project's `uv sync` to overwrite the same environment — recommended only for
  single-project contexts (CI, Docker).
- Setting `UV_PROJECT_ENVIRONMENT` to a system Python prefix is dangerous: `uv sync`
  removes packages it considers extraneous, which can break system tools.
- `environments` entries must be **disjoint**. For example, combining
  `sys_platform == 'darwin'` with `python_version >= '3.9'` is invalid because they
  can both be true at the same time.
- Declaring conflicts enables resolution but enforces mutual exclusivity at install
  time — `--all-extras` will always fail when conflicting extras are present.
- `required-environments` only has an effect for packages that lack a source
  distribution; packages that publish sdists are always buildable regardless of platform.

## See Also

- concept-project-environment
- project-conflicting-deps
- dep-platform-environments
- cmd-sync
- config-resolution-settings
