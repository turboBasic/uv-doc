---
id: concept-constraints-overrides
title: Dependency constraints and overrides
category: concepts
tags: [dependency, resolution, config]
source: https://docs.astral.sh/uv/concepts/resolution/#dependency-constraints
related: [concept-resolution, concept-lockfile, dep-overrides-constraints, ts-resolution-conflict, config-resolution-settings]
---

## Summary

Constraints narrow the set of acceptable versions for a package already pulled in as a
dependency; overrides replace declared requirements entirely to escape erroneous version
bounds. Dependency metadata overrides let you supply static metadata for packages that
cannot provide it themselves.

## Details

### Constraint files and `tool.uv.constraint-dependencies`

A constraint restricts which versions of a package the resolver may choose, but does
**not** add the package as a dependency. The package must already be required — directly
or transitively — for the constraint to take effect.

Constraints are **additive**: they are combined with the requirements declared by
constituent packages, further narrowing the acceptable range.

In the project interface, declare constraints in `pyproject.toml`:

```toml
[tool.uv]
constraint-dependencies = ["grpcio<1.65"]
```

In the pip-compatible interface, pass a constraints file:

```console
$ uv pip compile requirements.in --constraint constraints.txt
```

In `uv lock`, `uv sync`, and `uv run`, uv reads `constraint-dependencies` only from the
workspace root `pyproject.toml`; declarations in other workspace members or `uv.toml`
files are ignored.

### Dependency overrides and `tool.uv.override-dependencies`

An override **replaces** all declared requirements for a package globally. It is
**absolute**: every package's requirement on the overridden package is discarded and
replaced with the override specification.

Overrides do not add a dependency on their own — the package must still be required
elsewhere. They are a last resort for cases where you know a package works with a version
range that its declared metadata forbids, such as an erroneous upper-bound constraint.

Unlike constraints (which can only reduce the acceptable range), overrides can **expand**
it. For example, if a transitive dependency declares `pydantic>=1.0,<2.0` but actually
works with pydantic v2, an override of `pydantic>=1.0,<3` causes the resolver to ignore
the `<2.0` bound entirely.

In the project interface:

```toml
[tool.uv]
override-dependencies = ["werkzeug==2.3.0"]
```

In the pip-compatible interface, pass an overrides file:

```console
$ uv pip compile requirements.in --override overrides.txt
```

Like `constraint-dependencies`, `override-dependencies` is only read from the workspace
root `pyproject.toml`.

If multiple overrides target the same package they must be differentiated with
environment markers. When a package has a marker-conditional dependency and an override
applies, the override replaces it unconditionally regardless of whether the marker
evaluates to true or false.

### Dependency metadata overrides (`tool.uv.dependency-metadata`)

Some packages — particularly those distributed only as source distributions, or those
that require build isolation to be disabled — do not expose static metadata. uv must
build them from source to obtain their dependencies, which is slow and may fail on
platforms where the build is not supported.

`tool.uv.dependency-metadata` lets you supply metadata directly so uv can resolve
without building. Entries follow the [Metadata 2.3](https://packaging.python.org/en/latest/specifications/core-metadata/)
specification; only `name`, `version`, `requires-dist`, `requires-python`, and
`provides-extra` are read.

`version` is optional for registry packages (omitting it applies the metadata to all
versions) but required for direct-URL dependencies such as Git sources.

This mechanism can also correct incorrect or incomplete published metadata, acting on a
specific package version rather than globally (unlike `override-dependencies`).

## Examples

### Cap a transitive dependency version (constraint)

```toml title="pyproject.toml"
[tool.uv]
# Ensure grpcio<1.65 even though it is only a transitive dependency
constraint-dependencies = ["grpcio<1.65"]
```

### Remove an erroneous upper bound (override)

```toml title="pyproject.toml"
[tool.uv]
# A transitive dep requires pydantic>=1.0,<2.0 but works fine with v2;
# replace that bound globally so the resolver can pick pydantic>=2.0.
override-dependencies = ["pydantic>=1.0,<3"]
```

### Pin a package unconditionally (override)

```toml title="pyproject.toml"
[tool.uv]
override-dependencies = ["werkzeug==2.3.0"]
```

### Provide static metadata for a package with no static metadata

```toml title="pyproject.toml"
[[tool.uv.dependency-metadata]]
name = "chumpy"
version = "0.70"
requires-dist = ["numpy>=1.8.1", "scipy>=0.13.0", "six>=1.11.0"]
```

### Provide static metadata for a Git dependency

```toml title="pyproject.toml"
[project]
dependencies = ["flash-attn"]

[tool.uv.sources]
flash-attn = { git = "https://github.com/Dao-AILab/flash-attention", tag = "v2.6.3" }

[[tool.uv.dependency-metadata]]
name = "flash-attn"
version = "2.6.3"  # required for direct-URL deps
requires-dist = ["torch", "einops"]
```

### Constraint file for `uv pip compile`

```text title="constraints.txt"
pydantic<2.0
```

```console
$ uv pip compile requirements.in --constraint constraints.txt
```

## Caveats / Common Mistakes

- **Overrides bypass correctness checks.** If a package genuinely does not support the
  overridden version, you will get a runtime error rather than a resolution error.
- **Both constraints and overrides are no-ops unless the package is already required.**
  Listing a package in either setting does not pull it into the environment on its own.
- **Workspace scoping.** Both `constraint-dependencies` and `override-dependencies` are
  read only from the workspace root `pyproject.toml`. Setting them in a workspace member
  or in `uv.toml` has no effect.
- **Multiple overrides require markers.** If you define two overrides for the same
  package (e.g., for different platforms), they must use distinct environment markers or
  uv will error.
- **`dependency-metadata` version field.** For registry packages the `version` field is
  optional; for direct-URL (Git, path) dependencies it is required.

## See Also

- concept-resolution
- concept-lockfile
- dep-overrides-constraints
- ts-resolution-conflict
- config-resolution-settings
