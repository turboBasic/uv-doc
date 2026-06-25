---
id: pip-dependencies
title: Declaring dependencies for pip workflows — pyproject.toml and requirements.in
category: pip
tags: [pip, dependency, config, resolution]
source: https://docs.astral.sh/uv/pip/dependencies/
related: [pip-compile, pip-install, dep-overrides-constraints, concept-constraints-overrides, dep-optional]
---

## Summary

In pip-style workflows, dependencies are declared in a static file — either `pyproject.toml`
or a `requirements.in` file — and then locked with `uv pip compile` before installation.
Constraints and overrides files provide additional control over transitive dependency versions
without modifying the primary dependency declarations.

## Syntax / Usage

```bash
# Compile from pyproject.toml (with optional extras)
uv pip compile pyproject.toml -o requirements.txt
uv pip compile pyproject.toml --extra <name> -o requirements.txt
uv pip compile pyproject.toml --all-extras -o requirements.txt

# Compile from requirements.in
uv pip compile requirements.in -o requirements.txt

# Compile with constraints and/or overrides
uv pip compile requirements.in --constraint constraints.txt -o requirements.txt
uv pip compile requirements.in --override overrides.txt -o requirements.txt
uv pip compile requirements.in --build-constraint build-constraints.txt -o requirements.txt

# Install directly from a declaration file
uv pip install -r pyproject.toml --extra <name>
uv pip install -r requirements.in
```

## Details

### `pyproject.toml`

The standard Python project file. Declare runtime dependencies in `[project.dependencies]`
using PEP 508 specifiers, and optional dependency groups (extras) in
`[project.optional-dependencies]`:

```toml
[project]
dependencies = [
  "httpx",
  "ruff>=0.3.0",
]

[project.optional-dependencies]
cli = [
  "rich",
  "click",
]
```

Each key under `[project.optional-dependencies]` is an "extra". Extras are enabled with
`--extra <name>` or `--all-extras` when calling `uv pip compile` or `uv pip install -r`.

### `requirements.in`

A plain requirements-file-format file, conventionally named `requirements.in` to
distinguish it from the locked `requirements.txt`. One specifier per line:

```text
httpx
ruff>=0.3.0
```

Optional dependency groups are not supported in this format. When you need extras,
use `pyproject.toml` instead.

### From declaration to lockfile

Both formats feed into `uv pip compile`, which resolves the full dependency tree and
writes pinned versions to `requirements.txt`. From there, `uv pip install -r requirements.txt`
or `uv pip sync requirements.txt` installs the exact locked environment.

### Dependency groups

`pyproject.toml` also supports PEP 735 dependency groups (under `[dependency-groups]`).
These are compiled and installed with `--group <name>` rather than `--extra`.

### Constraints (`--constraint`)

A constraints file is a `requirements.txt`-like file that adds version bounds to packages
without triggering their installation. Use constraints to cap transitive dependencies that
your direct dependencies do not pin themselves:

```text
# constraints.txt
pydantic<2.0
```

```bash
uv pip compile requirements.in --constraint constraints.txt -o requirements.txt
```

Constraints are additive — they are combined with the requirements of constituent packages.
uv also reads `constraint-dependencies` from `pyproject.toml` at the workspace root,
appending them to any file-based constraints.

### Build constraints (`--build-constraint`)

Like `--constraint`, but scoped to build-time dependencies (those required to build
sdists or wheels for runtime packages). A build constraint does not install the package;
it only restricts the version used when the package is required as a build dependency:

```text
# build-constraints.txt
setuptools==75.0.0
```

```bash
uv pip compile requirements.in --build-constraint build-constraints.txt -o requirements.txt
```

uv also reads `build-constraint-dependencies` from `pyproject.toml` at the workspace root.

### Overrides (`--override`)

Overrides are absolute — they replace the version requirements of constituent packages
entirely, even if the result would otherwise be an invalid resolution. They are most often
used to remove upper bounds on transitive dependencies:

```text
# overrides.txt
c>=2.0
```

```bash
uv pip compile requirements.in --override overrides.txt -o requirements.txt
```

While constraints narrow the resolution space, overrides bypass it. Using an override that
contradicts a package's tested range can cause runtime errors.

## Examples

```bash
# 1. Declare in pyproject.toml, compile all extras, then sync
uv pip compile pyproject.toml --all-extras -o requirements.txt
uv pip sync requirements.txt

# 2. Declare in requirements.in, cap a transitive dep with a constraint
uv pip compile requirements.in \
  --constraint constraints.txt \
  -o requirements.txt

# 3. Remove an incompatible upper bound via override
uv pip compile requirements.in \
  --override overrides.txt \
  -o requirements.txt

# 4. Install extras directly without a separate compile step
uv pip install -r pyproject.toml --extra cli

# 5. Compile a dependency group alongside regular deps
uv pip compile pyproject.toml --group dev -o requirements-dev.txt
```

## Caveats / Common Mistakes

- Extras (`[project.optional-dependencies]`) are only available when using `pyproject.toml`
  as the input. The `requirements.in` format does not support extras.
- `--group` flags source groups from the `pyproject.toml` in the current working directory,
  not from any path passed to `-r`. Passing `uv pip compile some/path/pyproject.toml --group foo`
  still reads group `foo` from `./pyproject.toml`.
- Overrides bypass resolution validity checks. If the overridden version is genuinely
  incompatible with a package's code, a runtime error will occur even though resolution succeeds.
- Constraints do not install packages — they only restrict versions. A package listed only
  in a constraints file will not appear in the resolved environment unless also declared as
  a direct dependency.

## See Also

- pip-compile
- pip-install
- dep-overrides-constraints
- concept-constraints-overrides
- dep-optional
