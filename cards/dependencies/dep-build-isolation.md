---
id: dep-build-isolation
title: Build dependencies, build isolation, and dependency metadata
category: dependencies
tags: [dependency, build, config, resolution, troubleshooting]
source: https://docs.astral.sh/uv/concepts/projects/config/#build-isolation
related: [dep-add, config-build-settings, concept-resolution, ts-build-failure, dep-groups]
---

## Summary

By default uv builds every package in an isolated virtual environment using only that package's
declared `[build-system].requires`. When a package omits build deps or must build against
runtime deps (e.g. `flash-attn`, `deepspeed`), uv offers three complementary escape hatches:
augmenting build dependencies, disabling build isolation per-package, and supplying static
dependency metadata upfront to skip building during resolution entirely.

## Syntax / Usage

```toml
# Augment build deps (preferred)
[tool.uv.extra-build-dependencies]
<package> = ["<extra-dep>", ...]

# Augment with match-runtime (requires static metadata on the package)
[tool.uv.extra-build-dependencies]
<package> = [{ requirement = "<dep>", match-runtime = true }]

# Inject env vars into the build environment
[tool.uv.extra-build-variables]
<package> = { VAR = "value" }

# Disable isolation (two-phase install)
[tool.uv]
no-build-isolation-package = ["<package>", ...]

# Provide static metadata to skip build during resolution
[[tool.uv.dependency-metadata]]
name = "<package>"
version = "<version>"
requires-dist = ["<dep1>", "<dep2>"]
```

## Details

### PEP 517 / PEP 518 baseline

uv always respects `[build-system].requires` (PEP 518) to populate the isolated build
environment. Build dependencies listed there are installed only for the build step and do not
appear in the project environment.

### Augmenting build dependencies (`tool.uv.extra-build-dependencies`)

Adds packages to the isolated build environment without disabling isolation. This is the
preferred approach because it keeps the build sandboxed.

`match-runtime = true` pins the build dependency to the same version that will be installed in
the project environment. This is only available when the package declares **static metadata**
(i.e. uv does not need to build the package just to discover its dependencies). If the package
has dynamic metadata, pin the version explicitly instead (e.g. `"torch==2.6.0"`).

Changes to `extra-build-dependencies` and `extra-build-variables` are tracked in the uv cache.
Upgrading `torch` in the project will therefore trigger a rebuild of any package that lists
`torch` with `match-runtime = true`.

### Build-time environment variables (`tool.uv.extra-build-variables`)

Injects environment variables into the isolated build environment for a specific package. Useful
for packages that gate source vs. wheel builds on an env var (e.g. `FLASH_ATTENTION_SKIP_CUDA_BUILD`).

### Disabling build isolation (`no-build-isolation-package`)

Marks specific packages to be built without isolation. uv performs a two-phase install: it first
installs all packages that support isolation (including declared build deps), then installs the
no-isolation packages against the partially-populated environment.

Because build deps must be present in the project environment _before_ the non-isolated build,
any required build dep must appear in `project.dependencies`, a dependency group, or an optional
extra. For build deps that are only needed at build time (e.g. `cython` for `cchardet`), use an
optional group and sync in two passes to remove them after installation.

If a package needs its build deps present even during the **resolution** phase (not just
installation), pre-install them via `uv pip install` before running `uv lock` or `uv sync`.

### Providing dependency metadata (`tool.uv.dependency-metadata`)

Lets you supply `name`, `version`, `requires-dist`, `requires-python`, and `provides-extra`
directly in `pyproject.toml`. uv treats this as authoritative, skipping any build step that
would otherwise be required to discover the metadata.

The `version` field is optional for registry packages (metadata applies to all versions when
omitted) but **required** for direct URL / Git dependencies.

Entries follow the [Metadata 2.3](https://packaging.python.org/en/latest/specifications/core-metadata/)
specification. uv reads only the fields listed above.

## Examples

### cchardet — missing build dep, augment with extra-build-dependencies

```toml
[project]
name = "project"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = ["cchardet"]

[tool.uv.extra-build-dependencies]
cchardet = ["cython"]
```

### deepspeed — match build dep to runtime torch version

```toml
[project]
dependencies = ["deepspeed", "torch"]

[tool.uv.extra-build-dependencies]
deepspeed = [{ requirement = "torch", match-runtime = true }]
```

### flash-attn — env var + match-runtime

```toml
[project]
dependencies = ["flash-attn", "torch"]

[tool.uv.extra-build-dependencies]
flash-attn = [{ requirement = "torch", match-runtime = true }]

[tool.uv.extra-build-variables]
flash-attn = { FLASH_ATTENTION_SKIP_CUDA_BUILD = "TRUE" }
```

> Setting `FLASH_ATTENTION_SKIP_CUDA_BUILD = "TRUE"` resolves from a pre-built wheel instead
> of compiling from source. Omit the variable when the CUDA toolkit is available so that a
> compatible wheel for your GPU and PyTorch version can be selected.

### axolotl — dynamic metadata, pin torch explicitly

```toml
[project]
dependencies = ["axolotl[deepspeed,flash-attn]", "torch==2.6.0"]

[tool.uv.extra-build-dependencies]
axolotl    = ["torch==2.6.0"]
deepspeed  = ["torch==2.6.0"]
flash-attn = ["torch==2.6.0"]
```

### cchardet — no-build-isolation with two-pass sync (build deps in optional group)

```toml
[project]
dependencies = ["cchardet"]

[project.optional-dependencies]
build = ["setuptools", "cython"]

[tool.uv]
no-build-isolation-package = ["cchardet"]
```

```bash
uv sync --extra build   # install cchardet + build deps
uv sync                 # remove build-only deps (cython, setuptools)
```

### flash-attn — dependency-metadata to skip build during resolution

```toml
[project]
dependencies = ["flash-attn"]

[tool.uv.sources]
flash-attn = { git = "https://github.com/Dao-AILab/flash-attention", tag = "v2.6.3" }

[[tool.uv.dependency-metadata]]
name = "flash-attn"
version = "2.6.3"
requires-dist = ["torch", "einops"]
```

## Caveats / Common Mistakes

- `match-runtime = true` requires the package to expose **static metadata**. For packages with
  dynamic metadata (e.g. `axolotl`), pin the build dep version explicitly instead of using
  `match-runtime`.
- `no-build-isolation-package` requires build deps to be present in the environment _before_ the
  non-isolated build runs. Declare them as project deps or in an optional group; do not rely on
  them being incidentally present.
- `tool.uv.extra-build-dependencies` and `tool.uv.extra-build-variables` are tracked in the uv
  cache — changing them triggers a rebuild/reinstall of affected packages, which is the intended
  behavior.
- `tool.uv.dependency-metadata` is not verified against the package index. Providing incorrect
  metadata will produce a valid lockfile that fails at runtime.
- The `version` key in `[[tool.uv.dependency-metadata]]` is optional for registry packages but
  **required** for Git and direct URL dependencies.
- When `FLASH_ATTENTION_SKIP_CUDA_BUILD = "TRUE"` is set and no compatible pre-built wheel exists
  for the target PyTorch / GPU / platform combination, the install will fail. Only set this
  variable when a compatible wheel is known to exist.

## See Also

- dep-add
- config-build-settings
- concept-resolution
- ts-build-failure
- dep-groups
