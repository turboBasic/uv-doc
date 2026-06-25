---
id: concept-build-isolation
title: Build isolation and PEP 517 build environments
category: concepts
tags: [build, config, installation, troubleshooting]
source: https://docs.astral.sh/uv/concepts/projects/config/#build-isolation
related: [ts-build-failure, dep-build-isolation, config-build-settings, integration-pytorch, pip-install]
---

## Summary

By default, uv builds every package in an isolated virtual environment per PEP 517, containing only
declared build dependencies. Some packages (e.g., `flash-attn`, `deepspeed`, `cchardet`) fail or
misbehave under this model; uv provides two targeted escape hatches to address this without
abandoning isolation wholesale.

## Details

### Why isolation exists

PEP 517 mandates that each build runs in a fresh environment populated with the package's
`build-system.requires`. This prevents build-time leakage between packages and makes builds
reproducible. uv always uses this mode by default, equivalent to `pip install --use-pep517`.

### When packages break under isolation

Two patterns account for most real-world failures:

1. **Version coupling** — packages like `flash-attn` and `deepspeed` compile C/CUDA extensions
   against a specific version of PyTorch. When built in isolation, a different (or no) version of
   PyTorch may be resolved for the build environment, producing a binary incompatible with the
   runtime environment.

2. **Missing build dependency declarations** — packages like `cchardet` require `cython` at build
   time but do not list it in `build-system.requires`. The isolated environment therefore lacks it,
   and the build fails with a module import error.

### Approach 1: Augment build dependencies (`extra-build-dependencies`)

This is the **preferred approach**. It keeps isolation active but injects additional packages into
the build environment for named packages.

```toml
[tool.uv.extra-build-dependencies]
cchardet = ["cython"]
```

For version-coupled packages, use `match-runtime = true` to guarantee the build environment
receives the same version of a dependency that will be installed in the project environment:

```toml
[tool.uv.extra-build-dependencies]
deepspeed = [{ requirement = "torch", match-runtime = true }]
```

`match-runtime = true` requires the package to declare **static metadata**. For packages with
dynamic metadata (e.g., `axolotl`), pin the dependency version explicitly instead:

```toml
[tool.uv.extra-build-dependencies]
axolotl = ["torch==2.6.0"]
```

Use `extra-build-variables` alongside `extra-build-dependencies` to pass environment variables
into the build process:

```toml
[tool.uv.extra-build-variables]
flash-attn = { FLASH_ATTENTION_SKIP_CUDA_BUILD = "TRUE" }
```

Both `extra-build-dependencies` and `extra-build-variables` are tracked in the uv cache. When
either changes (for example, upgrading `torch`), affected packages are automatically rebuilt.

### Approach 2: Disable isolation per package (`no-build-isolation-package`)

This approach disables the isolated environment for the named package entirely. The package's build
backend runs against whatever is installed in the project environment at the time.

```toml
[tool.uv]
no-build-isolation-package = ["cchardet"]
```

uv then performs a **two-phase install**: first it installs all packages that support isolation
(resolving and satisfying normal dependencies), then it installs the no-isolation packages using the
already-populated environment as the build context. This means build dependencies only need to be
listed as regular project dependencies — uv guarantees they are present before the second phase.

Downsides of disabling isolation:

- Build-only dependencies (like `cython` for `cchardet`) end up in the project environment unless
  extra steps are taken to remove them.
- Reproducing the environment elsewhere requires awareness of the installation order.
- Some packages also need build dependencies present during the **resolution** phase, which
  precedes both install phases; in that case, build dependencies must be pre-installed with
  `uv pip install` before running `uv lock` or `uv sync`.

## Examples

### Augmenting build deps for `cchardet` (missing cython declaration)

```toml
[project]
name = "project"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = ["cchardet"]

[tool.uv.extra-build-dependencies]
cchardet = ["cython"]
```

### Building `flash-attn` against the runtime `torch` version

```toml
[project]
name = "project"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = ["flash-attn", "torch"]

[tool.uv.extra-build-dependencies]
flash-attn = [{ requirement = "torch", match-runtime = true }]

[tool.uv.extra-build-variables]
flash-attn = { FLASH_ATTENTION_SKIP_CUDA_BUILD = "TRUE" }
```

### Disabling isolation for `flash-attn` (alternative)

```toml
[project]
name = "project"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = ["flash-attn", "torch"]

[tool.uv]
no-build-isolation-package = ["flash-attn"]
```

```console
$ uv sync
# Phase 1: installs torch (and other normal deps)
# Phase 2: builds and installs flash-attn without isolation, using the installed torch
```

### Keeping build deps out of the runtime env (optional-dep group)

```toml
[project]
name = "project"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = ["cchardet"]

[project.optional-dependencies]
build = ["setuptools", "cython"]

[tool.uv]
no-build-isolation-package = ["cchardet"]
```

```console
$ uv sync --extra build   # installs cchardet + build tools
$ uv sync                 # removes build tools, keeps cchardet
```

### Pre-installing build deps when needed at resolution time

```console
$ uv venv
$ uv pip install torch setuptools
$ uv sync
```

## Caveats / Common Mistakes

- `match-runtime = true` only works when the target package declares **static metadata**. Packages
  with dynamic metadata (e.g., `axolotl`) require the exact version to be pinned explicitly in
  `extra-build-dependencies`.
- Setting `FLASH_ATTENTION_SKIP_CUDA_BUILD = "TRUE"` prevents source builds; if no compatible
  pre-built wheel exists for your PyTorch version and platform, the install will fail. Omit this
  variable when the CUDA toolkit is available.
- When using `no-build-isolation-package`, if the package's build backend needs its dependencies
  during resolution (not just installation), pre-install those dependencies with `uv pip install`
  before running `uv lock` or `uv sync`.
- Disabling isolation means build-only dependencies land in the project environment unless isolated
  via an optional dependency group and a two-step sync.
- The `extra-build-dependencies` setting became stable in uv 0.10.

## See Also

- ts-build-failure
- dep-build-isolation
- config-build-settings
- integration-pytorch
- pip-install
