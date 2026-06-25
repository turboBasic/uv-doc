---
id: config-build-settings
title: Build and installation settings — isolation, editable mode, and build backends
category: configuration
tags: [config, build, installation, project]
source: https://docs.astral.sh/uv/concepts/projects/config/#build-isolation
related: [concept-build-isolation, dep-build-isolation, dep-editable, project-packaging, bp-build-system-config]
---

## Summary

uv exposes several `[tool.uv]` settings that control how packages are built and installed:
`no-build-isolation-package`, `extra-build-dependencies`, `extra-build-variables`,
`tool.uv.package`, `link-mode`, and `compile-bytecode`.

## Syntax / Usage

```toml
[tool.uv]
# Disable PEP 517 isolation for specific packages
no-build-isolation-package = ["cchardet"]

# Inject extra build deps (optionally matching runtime version)
[tool.uv.extra-build-dependencies]
cchardet = ["cython"]
deepspeed = [{ requirement = "torch", match-runtime = true }]

# Inject extra env vars during the build of a package
[tool.uv.extra-build-variables]
flash-attn = { FLASH_ATTENTION_SKIP_CUDA_BUILD = "TRUE" }

# Force or suppress packaging
package = false   # or true

# Installation link strategy
link-mode = "copy"   # clone | copy | hardlink | symlink

# Compile .py to .pyc after install
compile-bytecode = true
```

## Details

### Build isolation (`no-build-isolation-package`)

By default uv builds every package in an isolated virtual environment according to PEP 517,
with only the declared build dependencies present. Setting `no-build-isolation-package`
disables this for the listed packages: uv will build them against whatever is already installed
in the project environment.

When at least one package has build isolation disabled, uv performs a two-phase install: all
packages that support isolation are installed first, then the non-isolated ones. This means
that if the required build dependencies are listed as regular project dependencies, they are
automatically available by the time the non-isolated package is built.

CLI equivalent: `--no-build-isolation-package <pkg>`.

### Extra build dependencies (`extra-build-dependencies`)

Augments the PEP 517 build environment for specific packages without fully disabling isolation.
Each key is a package name; the value is a list of PEP 508 requirement strings or inline tables.

The inline table form `{ requirement = "torch", match-runtime = true }` pins the injected
build dependency to the exact version that will be (or is already) installed in the project
environment. This is only valid for packages that publish static metadata — if a package
requires a build to determine its own metadata, uv cannot know the runtime version before
the first build, so the exact version must be specified explicitly instead.

Changes to `extra-build-dependencies` are tracked in the uv cache; upgrading a matched
runtime dependency (e.g., `torch`) automatically triggers a rebuild of the dependent package.

### Extra build environment variables (`extra-build-variables`)

Sets environment variables only for the build of the named package. Variables are added on
top of the normal environment and do not leak to other packages or to the runtime environment.
Like `extra-build-dependencies`, changes are cache-tracked.

### Project packaging (`tool.uv.package`)

Controls whether uv treats the project itself as an installable package:

- `true` — force the project to be built and installed into the project environment, even if
  no `[build-system]` is declared (uv falls back to the setuptools legacy backend).
- `false` — suppress packaging; the project's own code is not installed, only its dependencies.
  Explicit invocations of `uv build` are still honoured.

The default is inferred from the presence of a `[build-system]` table.

### Editable mode

By default the project itself is installed in editable mode (`uv sync`, `uv run`). Pass
`--no-editable` to install a non-editable copy, which is appropriate for Docker images or
other deployment artefacts where the source tree will not be present.

### Link mode (`link-mode`)

Controls how uv installs files from its global cache into the virtual environment:

| Value | Behaviour |
|-------|-----------|
| `clone` | Copy-on-write (default on macOS and Linux) |
| `copy` | Full file copy |
| `hardlink` | Hard link (default on Windows) |
| `symlink` | Symbolic link |

`symlink` is explicitly discouraged: clearing the cache (`uv cache clean`) breaks all
symlinked installations by removing the underlying files.

### Compile bytecode (`compile-bytecode`)

When `true`, uv compiles all `.py` files in `site-packages` to `.pyc` bytecode after
installation, trading longer install time for faster startup. uv processes the entire
`site-packages` directory for consistency and silently ignores compilation errors, matching
pip's behaviour. Useful for CLI applications and Docker containers where startup latency
matters. Default: `false`.

## Examples

Disable isolation for `cchardet`; declare its build deps as a removable extra:

```toml
[project]
name = "myproject"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = ["cchardet"]

[project.optional-dependencies]
build = ["setuptools", "cython"]

[tool.uv]
no-build-isolation-package = ["cchardet"]
```

```bash
# Install with build deps, then strip them
uv sync --extra build
uv sync
```

Build `flash-attn` against the project's `torch` version:

```toml
[project]
dependencies = ["flash-attn", "torch"]

[tool.uv.extra-build-dependencies]
flash-attn = [{ requirement = "torch", match-runtime = true }]

[tool.uv.extra-build-variables]
flash-attn = { FLASH_ATTENTION_SKIP_CUDA_BUILD = "TRUE" }
```

Force a "virtual" (non-packaged) project with fast Docker installs:

```toml
[tool.uv]
package = false
compile-bytecode = true
link-mode = "copy"
```

## Caveats / Common Mistakes

- `match-runtime = true` requires static package metadata. For packages like `axolotl` that
  use dynamic metadata, specify the exact version string instead:
  `axolotl = ["torch==2.6.0"]`.
- `no-build-isolation-package` requires build dependencies to be present in the project
  environment before the build. If they are only build-time deps (not runtime), use an
  optional dependency group and sync twice (see Examples).
- `symlink` link mode: removing the uv cache (`uv cache clean`) silently breaks every
  package installed via symlink. Prefer `clone` or `hardlink`.
- `compile-bytecode = true` reprocesses the entire `site-packages` on every install, which
  can noticeably increase install times in CI for large dependency sets.
- `tool.uv.package = false` suppresses the project build but not `uv build`; the `[build-system]`
  table is still used if you run `uv build` explicitly.

## See Also

- concept-build-isolation
- dep-build-isolation
- dep-editable
- project-packaging
- bp-build-system-config
