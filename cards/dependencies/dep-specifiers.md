---
id: dep-specifiers
title: Version specifiers and dependency specifier syntax
category: dependencies
tags: [dependency, project, config, resolution]
source: https://docs.astral.sh/uv/concepts/projects/dependencies/#dependency-specifiers
related: [dep-add, dep-platform-environments, dep-optional, dep-groups, ts-resolution-conflict]
---

## Summary

Dependency specifiers (PEP 508 / PEP 440) are the string format used in `pyproject.toml`
`project.dependencies`, `[project.optional-dependencies]`, and `[dependency-groups]`, and
accepted verbatim by `uv add`. They encode the package name, optional extras, version
constraints, and optional environment markers.

## Syntax / Usage

```
name[extra1,extra2] operator version, ... ; marker_expr
```

All parts after `name` are optional. Parts must appear in this order: name → extras → version
specifiers → marker.

## Details

### Version operators

| Operator | Meaning |
|----------|---------|
| `>=1.2`  | at least 1.2 |
| `<=1.2`  | at most 1.2 |
| `>1.2`   | strictly greater than 1.2 |
| `<2`     | strictly less than 2 |
| `==1.2.3` | exact match |
| `==1.2.*` | any release in the 1.2 series (star on last digit) |
| `!=1.4.0` | exclude this version |
| `~=1.2`  | compatible release: `>=1.2,<2` |
| `~=1.2.3` | compatible release: `>=1.2.3,<1.3` |

Multiple specifiers are comma-separated and all must be satisfied simultaneously, e.g.
`foo >=1.2.3,<2,!=1.4.0`.

Specifiers are zero-padded when compared: `foo ==2` matches `foo 2.0.0`.

### Extras in specifiers

Extras are comma-separated inside square brackets between the name and the version:

```
transformers[torch] >=4.39.3,<5
pandas[excel,plot] ==2.2
```

Whitespace between extra names is ignored.

### Environment markers

Markers restrict when a dependency applies. Common marker variables:

| Variable | Example value | Use case |
|----------|---------------|----------|
| `sys_platform` | `'linux'`, `'darwin'`, `'win32'` | OS |
| `platform_system` | `'Linux'`, `'Darwin'`, `'Windows'` | OS (title-cased) |
| `platform_machine` | `'x86_64'`, `'aarch64'` | CPU arch |
| `python_version` | `'3.11'` | major.minor only |
| `python_full_version` | `'3.11.2'` | exact interpreter version |
| `implementation_name` | `'cpython'`, `'pypy'` | interpreter impl |
| `os_name` | `'posix'`, `'nt'` | POSIX vs Windows |

Operators for markers: `==`, `!=`, `<`, `<=`, `>`, `>=`, `in`, `not in`.

Markers are combined with `and`, `or`, and parentheses. The marker expression follows a
semicolon (`;`) at the end of the specifier.

### Quoting rules

Versions **within** markers must be **quoted**; versions **outside** markers must **not** be quoted:

```
# correct
"importlib-metadata >=7.1.0,<8; python_version < '3.10'"

# correct
"colorama >=0.4.6,<5; platform_system == \"Windows\""

# wrong — quoted version outside marker
"httpx >='0.27'"
```

## Examples

```toml
# pyproject.toml — project.dependencies examples

[project]
dependencies = [
  # Simple lower bound (uv adds this automatically via `uv add httpx`)
  "httpx >=0.27.2",

  # Exact version
  "torch ==2.2.2",

  # Compatible release: >=1.2,<2
  "attrs ~=1.2",

  # Upper and lower bound, excluding a bad release
  "tqdm >=4.66.2,<5,!=4.66.3",

  # Extras + version range
  "transformers[torch] >=4.39.3,<5",

  # Linux-only
  "jax; sys_platform == 'linux'",

  # Python version backport
  "importlib-metadata >=7.1.0,<8; python_version < '3.10'",

  # Windows-only colorama
  "colorama >=0.4.6,<5; platform_system == 'Windows'",

  # Combined markers with and/or and parentheses
  "aiohttp >=3.7.4,<4; (sys_platform != 'win32' or implementation_name != 'pypy') and python_version >= '3.10'",
]
```

`uv add` accepts the same specifier strings on the command line:

```bash
uv add "httpx>=0.27"
uv add "jax; sys_platform == 'linux'"
uv add "numpy; python_version >= '3.11'"
uv add "transformers[torch]>=4.39.3,<5"
```

## Caveats / Common Mistakes

- Versions inside marker expressions must be **quoted** (`python_version < '3.10'`), but
  versions in the main specifier must **not** be quoted (`httpx >=0.27`). Mixing these up
  silently produces wrong results or parse errors.
- `python_version` is major.minor only (`'3.11'`). Use `python_full_version` for patch-level
  comparisons.
- `sys_platform` and `platform_system` are different variables with different casing conventions
  (`'linux'` vs `'Linux'`). Always check which one a recipe uses before copying it.
- `~=` requires at least two components: `~=1` is invalid; `~=1.2` is the minimum form.
- The wildcard `*` is only valid with `==` (and `!=`), on the last position: `==2.1.*` is
  valid; `>=2.1.*` is not.

## See Also

- dep-add
- dep-platform-environments
- dep-optional
- dep-groups
- ts-resolution-conflict
