---
id: bp-build-system-config
title: "Build system configuration: [build-system], tool.uv.package, and build isolation"
category: build-publish
tags: [build, config, project, installation, troubleshooting]
source: https://docs.astral.sh/uv/concepts/projects/config/#build-systems
related: [project-packaging, dep-build-isolation, config-build-settings, bp-uv-build-backend, concept-build-isolation]
---

## Summary

The `[build-system]` table in `pyproject.toml` controls whether uv builds and installs the
project itself; `tool.uv.package` overrides that heuristic. For dependency packages that cannot
be built in PEP 517 isolated environments, `extra-build-dependencies` (with optional
`match-runtime`) and `no-build-isolation-package` provide targeted escape hatches.

## Syntax / Usage

```toml
# Declare a build system (required for uv to treat the project as a package)
[build-system]
requires = ["uv_build>=0.11.24,<0.12"]
build-backend = "uv_build"

# Override packaging heuristic
[tool.uv]
package = false  # or true

# Augment build deps for specific dependencies
[tool.uv.extra-build-dependencies]
cchardet = ["cython"]
flash-attn = [{ requirement = "torch", match-runtime = true }]

# Disable build isolation for specific packages
[tool.uv]
no-build-isolation-package = ["cchardet"]
```

## Details

### [build-system] and project packaging

uv inspects `[build-system]` to decide whether to build and install the current project
into the project virtual environment. If `[build-system]` is present, uv builds and
installs the project in editable mode. If absent, uv only installs the project's
dependencies and does not install the project itself.

Entry points (`[project.scripts]`, `[project.gui-scripts]`, `[project.entry-points]`)
require a `[build-system]` to be present.

For legacy reasons, packages you depend on that omit `[build-system]` are still buildable
by uv — they fall back to `setuptools.build_meta:__legacy__`. This legacy fallback only
applies to dependencies, not to your own project.

### tool.uv.package

`tool.uv.package` overrides the `[build-system]` heuristic:

- `tool.uv.package = true` — forces the project to be built and installed even if no
  `[build-system]` is declared; falls back to the setuptools legacy backend in that case.
- `tool.uv.package = false` — prevents the project from being built and installed even if
  `[build-system]` is declared. uv ignores the build system during `uv sync`/`uv run`, but
  still respects it for explicit build invocations like `uv build`.

The default value is `true` when a `[build-system]` is present, `false` otherwise.

### Build isolation default (PEP 517)

By default, uv builds all packages in isolated virtual environments that contain only the
packages declared in `[build-system].requires`, per PEP 517. This prevents build-time
packages from leaking into the runtime environment.

### extra-build-dependencies

`extra-build-dependencies` augments the isolated build environment for a specific
dependency without disabling isolation entirely. The value is a dict mapping package names
to lists of additional build requirements:

```toml
[tool.uv.extra-build-dependencies]
cchardet = ["cython"]
```

With `match-runtime = true`, the additional dependency is pinned to whatever version will
be installed in the project environment. This is the recommended approach for ML packages
like `flash-attn` and `deepspeed` that must be compiled against the exact version of
`torch` in the runtime environment:

```toml
[tool.uv.extra-build-dependencies]
flash-attn = [{ requirement = "torch", match-runtime = true }]
```

`match-runtime` only works when the package declares **static metadata**. For packages
with dynamic metadata (e.g., `axolotl`), pin the version explicitly in both the project
dependencies and `extra-build-dependencies`.

Changes to `extra-build-dependencies` or `extra-build-variables` are tracked in the uv
cache, so upgrading `torch` will automatically trigger a rebuild of `flash-attn`.

### no-build-isolation-package

`no-build-isolation-package` disables PEP 517 isolation entirely for the named packages,
building them directly in the project environment. uv performs a two-phase install: it
first installs all packages that support isolation, then installs the listed packages
without isolation. As a result, if a package's build dependencies are declared as project
dependencies, they will be available automatically before the isolated-off package builds.

This approach is simpler but has a downside: build-only dependencies (like `cython` for
`cchardet`) end up installed in the project environment. To avoid that, place build deps
in an optional group, sync with the group to build, then sync without it to remove them.

Prefer `extra-build-dependencies` over `no-build-isolation-package` when possible.

## Examples

### uv_build as build system

```toml
[build-system]
requires = ["uv_build>=0.11.24,<0.12"]
build-backend = "uv_build"
```

### Virtual project (no package installation)

```toml
[project]
name = "my-app"
version = "0.1.0"

[tool.uv]
package = false
```

### Augmenting build deps (flash-attn with match-runtime)

```toml
[project]
name = "ml-project"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = ["flash-attn", "torch"]

[tool.uv.extra-build-dependencies]
flash-attn = [{ requirement = "torch", match-runtime = true }]

[tool.uv.extra-build-variables]
flash-attn = { FLASH_ATTENTION_SKIP_CUDA_BUILD = "TRUE" }
```

### Augmenting build deps for dynamic-metadata package (axolotl)

```toml
[project]
dependencies = ["axolotl[deepspeed,flash-attn]", "torch==2.6.0"]

[tool.uv.extra-build-dependencies]
axolotl = ["torch==2.6.0"]
deepspeed = ["torch==2.6.0"]
flash-attn = ["torch==2.6.0"]
```

### Disabling build isolation via optional group (cchardet)

```toml
[project]
dependencies = ["cchardet"]

[project.optional-dependencies]
build = ["setuptools", "cython"]

[tool.uv]
no-build-isolation-package = ["cchardet"]
```

```bash
# Install with build deps, build cchardet, then remove build deps
uv sync --extra build
uv sync
```

## Caveats / Common Mistakes

- Without `[build-system]`, `uv sync` does not install the project itself — only its
  dependencies. This means entry points and the package's own imports are unavailable
  unless you set `tool.uv.package = true`.
- `tool.uv.package = false` suppresses installation during `uv sync`/`uv run` but does
  not prevent `uv build` from running — the build system is still used when explicitly
  invoked.
- `match-runtime = true` requires the package to declare static metadata. Packages with
  dynamic metadata (those that need to build before their dependencies are known) cannot
  use `match-runtime`; pin the version explicitly instead.
- `FLASH_ATTENTION_SKIP_CUDA_BUILD = "TRUE"` resolves `flash-attn` from a pre-built
  wheel. Omit this variable when the CUDA toolkit is available and you need a
  source-built wheel; the pre-built wheel may be incompatible if no matching wheel exists
  for the target PyTorch/GPU/platform combination.
- When using `no-build-isolation-package`, build dependencies that are only needed at
  build time (e.g., `cython`) will pollute the project environment unless isolated into
  an optional dependency group and removed after building.

## See Also

- project-packaging
- dep-build-isolation
- config-build-settings
- bp-uv-build-backend
- concept-build-isolation
