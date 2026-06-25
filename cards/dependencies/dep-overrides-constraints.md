---
id: dep-overrides-constraints
title: Override dependencies and constraint dependencies
category: dependencies
tags: [dependency, resolution, config, pip]
source: https://docs.astral.sh/uv/concepts/resolution/#dependency-overrides
related: [concept-resolution, config-resolution-settings, ts-resolution-conflict, dep-specifiers, pip-compile]
---

## Summary

Constraints narrow the acceptable version range for a dependency already pulled in elsewhere;
overrides replace declared requirements entirely, making them an escape hatch for wrong or
over-restrictive metadata. Both mechanisms avoid adding the package as a new dependency on their own.

## Syntax / Usage

**Project interface (`pyproject.toml`)**

```toml
[tool.uv]
constraint-dependencies  = ["<requirement-specifier>", ...]
override-dependencies    = ["<requirement-specifier>", ...]
build-constraint-dependencies = ["<requirement-specifier>", ...]
```

**pip interface (file-based)**

```console
# constraints
uv pip compile requirements.in --constraint constraints.txt
uv pip install -r requirements.txt --constraint constraints.txt   # -c is the short flag

# overrides
uv pip compile requirements.in --override overrides.txt
uv pip install -r requirements.txt --override overrides.txt

# build constraints
uv pip compile requirements.in --build-constraints build-constraints.txt   # -b is the short flag
```

## Details

### Constraints (`tool.uv.constraint-dependencies`)

Constraints are **additive**: they are combined with the requirements already declared by any
package. A constraint entry narrows the set of acceptable versions but does not cause the package
to be installed — the package must already be a direct or transitive dependency for the constraint
to have any effect.

Use constraints to restrict a transitive dependency to a known-good version range, e.g. to avoid
a release that introduced a regression.

In `uv lock`, `uv sync`, and `uv run`, uv reads `constraint-dependencies` only from the
`pyproject.toml` at the workspace root; declarations in other workspace members or in `uv.toml`
files are ignored.

In the pip interface, the equivalent CLI flags are `--constraint` / `--constraints` / `-c`, which
accept a `requirements.txt`-style file. The env var `UV_CONSTRAINT` is also supported.

### Overrides (`tool.uv.override-dependencies`)

Overrides are **absolute**: uv discards all declared requirements for the named package from every
constituent package and replaces them with the override specifier. This can both expand and narrow
the acceptable version range and can even force a specific pinned version.

Overrides are the appropriate last resort when a transitive package has an erroneous upper bound
that prevents a valid resolution. For example, if a transitive dependency declares
`pydantic>=1.0,<2.0` but actually works with pydantic 2.x, adding `pydantic>=1.0,<3` as an
override causes uv to ignore the `<2.0` bound entirely.

Like constraints, an override does not cause the package to be installed on its own; the package
must already appear in the direct or transitive dependency graph.

If multiple overrides are provided for the same package, they must be differentiated with
environment markers. When a package dependency has a marker, the override replaces it
unconditionally regardless of whether the marker evaluates to true or false.

In `uv lock`, `uv sync`, and `uv run`, uv reads `override-dependencies` only from the workspace
root `pyproject.toml`.

In the pip interface, the equivalent CLI flags are `--override` / `--overrides`, which accept a
`requirements.txt`-style file. The env var `UV_OVERRIDE` is also supported.

### Build constraints (`tool.uv.build-constraint-dependencies`)

Build constraints apply only when packages are built from source during resolution or installation.
They narrow the version of build-time dependencies (e.g. `setuptools`, `wheel`) selected for each
package's build environment. Including a package as a build constraint does not install it; it only
takes effect when the package is already required as a direct or transitive build dependency.

In `uv lock`, `uv sync`, and `uv run`, uv reads `build-constraint-dependencies` only from the
workspace root `pyproject.toml`.

In the pip interface, the equivalent CLI flag is `--build-constraints` / `--build-constraint` /
`-b`. The env var `UV_BUILD_CONSTRAINT` is also supported.

### Constraints vs overrides — key distinction

| Property | Constraints | Overrides |
|---|---|---|
| Combined with existing requirements | Yes (additive) | No (replaces entirely) |
| Can expand acceptable versions | No | Yes |
| Can narrow acceptable versions | Yes | Yes |
| Installs the package on its own | No | No |
| Typical use case | Avoid a bad release of a transitive dep | Remove wrong upper bounds |

## Examples

**Constrain a transitive dependency (project interface)**

```toml title="pyproject.toml"
[tool.uv]
# Ensure grpcio stays below 1.65, whatever transitive packages request.
constraint-dependencies = ["grpcio<1.65"]
```

**Override an erroneous upper bound (project interface)**

```toml title="pyproject.toml"
[tool.uv]
# A transitive dep declares pydantic>=1.0,<2.0 but works with pydantic 2.x.
# Replace that requirement globally so the resolver can pick pydantic 2.
override-dependencies = ["pydantic>=1.0,<3"]
```

**Pin the build backend version across all packages (project interface)**

```toml title="pyproject.toml"
[tool.uv]
build-constraint-dependencies = ["setuptools==60.0.0"]
```

**Use a constraints file with the pip interface**

```text title="constraints.txt"
pydantic<2.0
```

```console
$ uv pip compile requirements.in --constraint constraints.txt -o requirements.txt
```

**Use an overrides file with the pip interface**

```text title="overrides.txt"
c>=2.0
```

```console
$ uv pip compile requirements.in --override overrides.txt -o requirements.txt
```

**Multiple overrides with markers**

```toml title="pyproject.toml"
[tool.uv]
override-dependencies = [
    "numpy>=1.24; python_version < '3.10'",
    "numpy>=2.0; python_version >= '3.10'",
]
```

## Caveats / Common Mistakes

- Overrides bypass the resolver's correctness guarantees. If the package truly does not support
  the overridden version range, runtime errors will occur. Use overrides only when you have
  verified compatibility independently.
- Neither constraints nor overrides pull in a package on their own. If the package does not appear
  anywhere in the dependency graph, the entry is silently a no-op.
- `constraint-dependencies`, `override-dependencies`, and `build-constraint-dependencies` are all
  read **only from the workspace root** `pyproject.toml`. Placing them in a non-root member's
  `pyproject.toml` or in a `uv.toml` file has no effect.
- Multiple overrides for the same package without markers will cause a resolution error; always
  use environment markers to differentiate them.

## See Also

- concept-resolution
- config-resolution-settings
- ts-resolution-conflict
- dep-specifiers
- pip-compile
