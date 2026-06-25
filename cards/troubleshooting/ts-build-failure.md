---
id: ts-build-failure
title: Diagnosing and fixing package build failures
category: troubleshooting
tags: [troubleshooting, build, dependency, config, installation]
source: https://docs.astral.sh/uv/reference/troubleshooting/build-failures/
related: [dep-build-isolation, concept-build-isolation, dep-platform-environments, config-build-settings, ts-resolution-conflict]
---

## Summary

When no compatible pre-built wheel exists, uv builds the package from source. Build failures are
almost always caused by missing system tools, headers, or package/build-dep version mismatches —
not by uv itself. The error always starts with "The build backend returned an error".

## Syntax / Usage

```bash
uv pip install <package>            # triggers a build if no wheel exists
uv sync                             # same during project sync
uv pip install <package> --no-build-isolation-package <package>
```

## Details

### Recognizing a build failure

Every build failure is prefaced by "The build backend returned an error". The `[stderr]` and
`[stdout]` blocks below it come from the build backend (e.g. setuptools), not from uv. uv may
append a `hint:` line for well-known failure patterns.

### Why uv builds a package

uv builds from source when no compatible wheel is available in the index. During resolution it
tries to avoid builds by using any existing wheel or reading static metadata from the source
distribution. It only falls back to a full build if static metadata is unavailable. During
installation it must have a wheel for the current platform.

### Confirming whether the failure is uv-specific

Reproduce the failure with pip using `--use-pep517` (which enforces the same build-isolation
semantics as uv). If pip also fails, the root cause is the system or the build backend, not uv:

```console
$ uv venv -p 3.13 --seed
$ source .venv/bin/activate
$ pip install --use-pep517 --no-cache --force-reinstall '<package>==<version>'
```

### Common causes and fixes

**Missing compiler (e.g. `gcc`)**
The build log will mention `error: command 'gcc' failed: No such file or directory`. Install the
compiler with your system package manager. On Debian/Ubuntu, `build-essential` covers most
common build dependencies. When using uv-managed Python versions, `clang` is often needed
instead of `gcc`.

**Missing header or library (`.h` file missing)**
The build log will show a `fatal error: some/header.h: No such file or directory`. Install the
development package for the library with your system package manager (e.g. `libgraphviz-dev`
for `pygraphviz`). Note: the runtime package alone is not sufficient; you need the `-dev` or
`-devel` variant. To fix a missing `Python.h`, install `python3-dev`.

**Missing module at build time (undeclared build dependency)**
If the error is `ModuleNotFoundError: No module named 'pip'` or similar, the package does not
declare all its build dependencies. The preferred fix is to augment the isolated build
environment using `extra-build-dependencies` in `pyproject.toml`. Alternatively, disable build
isolation for that package with `no-build-isolation-package`.

**`distutils` removed in Python 3.12+**
Old packages that rely on `import distutils` will fail on Python 3.12+. The fix is to add a
lower-bound constraint to avoid building that version, or to upgrade to a newer release of the
package.

**Old package version selected by the resolver**
uv's resolver may select an unexpectedly old version due to algorithmic limitations. Add a
lower-bound constraint (e.g. `numpy>=1.17`) to steer the resolver away from unbuildable old
versions.

**Old build dependency selected**
Use `build-constraint-dependencies` to pin build-time dependencies to known-good versions
without affecting runtime dependencies.

**Package only needed for an unused platform**
Constrain resolution to your supported platforms using `[tool.uv] environments` to avoid
building packages that are unnecessary for your targets.

**Package only usable on a specific platform**
Use `dependency-metadata` to supply the package's metadata manually, skipping the build
entirely. uv cannot verify this information, so correctness is the author's responsibility.

## Examples

Install system build dependencies (Debian/Ubuntu):

```console
$ apt install build-essential        # covers gcc, make, and friends
$ apt install libgraphviz-dev        # for pygraphviz specifically
$ apt install python3-dev            # if Python.h is missing
```

Augment build dependencies for a package that does not declare them:

```toml
# pyproject.toml
[tool.uv.extra-build-dependencies]
cchardet = ["cython"]
```

Augment with a build dependency that must match the runtime version:

```toml
# pyproject.toml
[tool.uv.extra-build-dependencies]
deepspeed = [{ requirement = "torch", match-runtime = true }]
```

Disable build isolation for a specific package:

```toml
# pyproject.toml
[project]
dependencies = ["cchardet", "cython", "setuptools"]

[tool.uv]
no-build-isolation-package = ["cchardet"]
```

Constrain a build dependency to avoid a broken version:

```toml
# pyproject.toml
[tool.uv]
build-constraint-dependencies = ["setuptools!=72.0.0"]
```

Add a lower-bound constraint to avoid old unbuildable versions:

```toml
# pyproject.toml
[tool.uv]
constraint-dependencies = ["apache-beam>2.30.0"]
```

Skip building a platform-specific package by providing its metadata manually:

```toml
# pyproject.toml
[[tool.uv.dependency-metadata]]
name = "flash-attn"
version = "2.6.3"
requires-dist = ["torch", "einops"]
```

## Caveats / Common Mistakes

- `no-build-isolation-package` requires that the package's build dependencies are already present
  in the environment *before* the build. uv performs a two-phase install automatically when the
  build deps are listed as project dependencies, but if they are only needed at resolution time
  you must pre-install them via `uv pip install` first.
- Prefer `extra-build-dependencies` over `no-build-isolation-package` when possible. Disabling
  isolation entirely forces build deps into the project environment and complicates reproduction.
- `match-runtime = true` in `extra-build-dependencies` only works when the package declares
  static metadata. For packages with dynamic metadata (e.g. `axolotl`), pin the build dep
  version explicitly instead.
- Installing the runtime package (e.g. `graphviz`) is not sufficient when headers are missing;
  you need the development package (e.g. `libgraphviz-dev`).
- When using uv-managed Python on Linux, prefer `clang` over `gcc` for C extension builds.

## See Also

- dep-build-isolation
- concept-build-isolation
- dep-platform-environments
- config-build-settings
- ts-resolution-conflict
