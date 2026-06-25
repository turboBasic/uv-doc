---
id: project-packaging
title: "Project packaging: build systems and tool.uv.package"
category: projects
tags: [project, build, config, installation]
source: https://docs.astral.sh/uv/concepts/projects/config/#build-systems
related: [project-structure, dep-build-isolation, concept-build-isolation, bp-uv-build-backend, project-app-vs-library]
---

## Summary

uv uses the presence of a `[build-system]` table in `pyproject.toml` to decide whether the
project itself should be built and installed into the project environment. The `tool.uv.package`
setting overrides that heuristic, and `--no-editable` switches from editable to non-editable
installation for deployment scenarios.

## Syntax / Usage

```toml
# pyproject.toml

# Force packaging on even without a build system:
[tool.uv]
package = true

# Force no packaging even with a build system declared:
[tool.uv]
package = false
```

```bash
# Init a project with the default build system (hatchling):
uv init --package my-lib

# Init with a specific build backend:
uv init --build-backend setuptools my-lib

# Sync without editable install (for Docker / deployment):
uv sync --no-editable
```

## Details

### Build system detection

uv checks for a `[build-system]` table in `pyproject.toml`. If one is present, uv builds
and installs the project into the project virtual environment. If none is present, uv only
installs the project's dependencies — the project itself is not installed.

The `--package` flag to `uv init` creates a packaged project with the default build system
(hatchling). The `--build-backend` flag selects a specific backend (e.g., `setuptools`,
`flit-core`, `maturin`).

Note: for *dependencies* (not the current project), uv falls back to
`setuptools.build_meta:__legacy__` when no `[build-system]` is declared — this legacy
behavior does not apply to the current project.

### tool.uv.package override

The `tool.uv.package` boolean overrides the build-system heuristic for the current project:

- `true` — force build and install into the environment. If no build system is defined, uv
  uses the setuptools legacy backend.
- `false` — suppress build and install regardless of a declared build system. `uv build`
  still respects the build system when invoked explicitly.

The setting defaults to `true` when a build system is present and `false` when it is absent,
so explicit use is only needed to diverge from that default.

### Entry points

Entry points are only active when the project has a build system defined (or
`tool.uv.package = true`). Three tables are supported:

- `[project.scripts]` — CLI commands installed into the environment's `bin/`.
- `[project.gui-scripts]` — GUI commands; on Windows these are wrapped in a GUI executable
  so they can start without a console window. Identical to scripts on other platforms.
- `[project.entry-points.<group>]` — plugin discovery hooks consumed via
  `importlib.metadata.entry_points(group=...)`.

### requires-python

The `project.requires-python` field constrains which Python interpreter may be used and
which dependency versions are eligible (dependencies must support the same Python range).
Setting it is recommended for every project.

### Editable mode

By default the project is installed in editable mode so source changes are reflected
immediately. Pass `--no-editable` to `uv sync` or `uv run` to install non-editablly. This
is intended for deployment contexts (e.g., Docker images) where the source tree should not
be a runtime dependency.

### Build isolation

By default uv builds every package in an isolated PEP 517 virtual environment seeded with
the package's declared build dependencies. Two mechanisms relax this:

**`tool.uv.extra-build-dependencies`** — augments the isolated build environment for a
named dependency with additional packages. Packages can be pinned or matched to the runtime
version of another dependency via `match-runtime = true`. This is the preferred approach
because the project environment is not polluted with build-time-only packages.

**`tool.uv.no-build-isolation-package`** — disables isolation entirely for the listed
packages. uv performs a two-phase install: packages that support isolation are installed
first so their output is available as build dependencies for the non-isolated packages. The
build dependencies must be present as project (or optional) dependencies. Use this only
when augmenting build deps is insufficient.

## Examples

### Library with entry point

```toml
[project]
name = "my-cli"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = []

[project.scripts]
my-cli = "my_cli:main"

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"
```

```bash
uv run my-cli   # installs project in editable mode, then runs the script
```

### Virtual project (no install)

```toml
[project]
name = "my-app"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = ["fastapi", "uvicorn"]

[tool.uv]
package = false  # no build system, no install; only dependencies are synced
```

### Extra build dependencies with runtime version matching

```toml
[project]
name = "ml-project"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = ["flash-attn", "torch"]

[tool.uv.extra-build-dependencies]
flash-attn = [{ requirement = "torch", match-runtime = true }]
```

### Disable build isolation for a package

```toml
[project]
name = "my-project"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = ["cchardet", "cython", "setuptools"]

[tool.uv]
no-build-isolation-package = ["cchardet"]
```

### Non-editable install for Docker

```bash
uv sync --no-editable
```

## Caveats / Common Mistakes

- Entry points require a build system (or `tool.uv.package = true`). Declaring
  `[project.scripts]` without a build system means the scripts are silently unavailable.
- `tool.uv.package = false` does not prevent `uv build` from running — it only affects
  what gets installed into the project environment during `uv sync` / `uv run`.
- `no-build-isolation-package` requires the listed package's build dependencies to already
  be in the project environment. If they are only needed at build time, use an optional
  dependency group to avoid polluting the runtime environment.
- `match-runtime = true` in `extra-build-dependencies` only works for packages with static
  metadata. For packages with dynamic metadata (e.g., `axolotl`), pin the dependency
  version explicitly instead.
- `gui-scripts` behave identically to `scripts` on non-Windows platforms.

## See Also

- project-structure
- dep-build-isolation
- concept-build-isolation
- bp-uv-build-backend
- project-app-vs-library
