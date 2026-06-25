---
id: bp-build-backend-file-inclusion
title: "uv build backend: file inclusion and exclusion (source-include, source-exclude, wheel-exclude, data)"
category: build-publish
tags: [build, publish, config]
source: https://docs.astral.sh/uv/concepts/build-backend/#file-inclusion-and-exclusion
related: [bp-uv-build-backend, bp-build-backend-module-layout, bp-build-system-config, bp-build-publish, bp-uv-build-options]
---

## Summary

The uv build backend controls which files enter sdists and wheels through a set of include and
exclude settings in `[tool.uv.build-backend]`. Exclusions always win over inclusions.

## Syntax / Usage

```toml
[tool.uv.build-backend]
source-include   = ["<glob>", ...]   # extra files added to sdist only
source-exclude   = ["<glob>", ...]   # removed from sdist and wheel
wheel-exclude    = ["<glob>", ...]   # removed from wheel only (in addition to source-exclude)
default-excludes = true              # set false to keep __pycache__, *.pyc, *.pyo
data             = { scripts = "bin", headers = "include/headers" }
```

## Details

### sdist defaults

When building a source distribution the backend includes:

- `pyproject.toml`
- The module directory under `tool.uv.build-backend.module-root`
- Files referenced by `project.license-files` and `project.readme`
- All directories listed under `tool.uv.build-backend.data`
- All files matching `tool.uv.build-backend.source-include`

`source-exclude` and the default excludes are then removed.

### wheel defaults

When building a wheel the backend includes:

- The module directory
- `project.license-files` (copied into `.dist-info`)
- `project.readme` (copied into project metadata)
- All `tool.uv.build-backend.data` directories (copied into `.data`)

`source-exclude`, `wheel-exclude`, and the default excludes are then removed.
`source-exclude` is also applied to wheels so that a wheel built directly from the source tree
matches one built from a source distribution.

There are no extra wheel includes: all Python files must be under the module root, and all data
files must be under the module root or in a `data` directory.

### Default excludes

`__pycache__` directories, `*.pyc` files, and `*.pyo` files are excluded by default. Set
`default-excludes = false` to disable this.

### data directories

`data` maps wheel data category names to source directories. Upon installation each category is
placed at the matching install path:

| Key       | Install location                          |
| --------- | ----------------------------------------- |
| `scripts` | `<venv>/bin` (Unix) or `<venv>\Scripts` (Windows), added to `PATH` |
| `headers` | The include directory (for C extension build requirements) |
| `data`    | The virtualenv root (can override existing files) |
| `purelib` / `platlib` | `site-packages` (not recommended; prefer placing files in the module) |

For small data files, placing them inside the Python module root is simpler and does not require
the `data` setting.

### Include and exclude glob syntax

All patterns use the reduced portable glob syntax from
[PEP 639](https://peps.python.org/pep-0639/#add-license-FILES-key), with backslash escaping.

**Includes are anchored**: `pyproject.toml` matches only `<root>/pyproject.toml`, not nested
occurrences. Use a `/**` suffix to match recursively: `src/**` includes everything under `src/`.
Recursive patterns are also anchored: `assets/**/sample.csv` only matches under `<root>/assets/`.

**Excludes are unanchored**: `__pycache__` matches any directory with that name at any depth.
Prefix with `/` to anchor: `/dist` excludes only `<root>/dist`. All children of an excluded
directory are also excluded.

## Examples

Include tests in the sdist but not the wheel; exclude compiled binaries everywhere:

```toml
[tool.uv.build-backend]
source-include  = ["tests/**", "docs/**"]
source-exclude  = ["*.bin"]
wheel-exclude   = ["tests/**"]
```

Ship a CLI binary and C headers via the wheel data directory:

```toml
[tool.uv.build-backend]
data = { scripts = "bin", headers = "include/headers" }
```

Disable default excludes (e.g., to inspect compiled artifacts):

```toml
[tool.uv.build-backend]
default-excludes = false
```

Anchor a top-level directory exclusion (exclude only `<root>/dist`, not nested `dist/`):

```toml
[tool.uv.build-backend]
source-exclude = ["/dist"]
```

## Caveats / Common Mistakes

- `source-exclude` applies to both sdist and wheel. Use `wheel-exclude` when you want a file in
  the sdist (e.g. tests) but not the wheel.
- Include globs are anchored; avoid unanchored patterns like `**/sample.csv` as the docs note
  these hurt performance and reproducibility.
- The `data` key is only for wheel installation paths. It does not affect which files appear in
  the sdist.
- `data = { data = "..." }` installs files over the virtualenv root and can silently overwrite
  existing files.

## See Also

- bp-uv-build-backend
- bp-build-backend-module-layout
- bp-build-system-config
- bp-build-publish
- bp-uv-build-options
