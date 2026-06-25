---
id: bp-build-backend-module-layout
title: "uv build backend: module layout (module-name, module-root, namespaces, stubs)"
category: build-publish
tags: [build, publish, config, project]
source: https://docs.astral.sh/uv/concepts/build-backend/#modules
related: [bp-uv-build-backend, bp-build-publish, bp-build-backend-file-inclusion, project-structure, config-build-settings]
---

## Summary

The uv build backend locates your Python module using `module-name` and `module-root` settings
under `[tool.uv.build-backend]`. Defaults work for standard src layout; explicit settings are
required for flat layout, namespace packages, multiple-module packages, and type stub packages.

## Syntax / Usage

```toml
[tool.uv.build-backend]
module-name = "my_package"        # str or list[str]
module-root = ""                  # default: "src"
namespace = true                  # default: false
```

## Details

### Default discovery (src layout)

By default the backend looks for `src/<normalized_name>/__init__.py`. The package name is
normalized: lowercased, dots and dashes replaced with underscores (e.g. `Foo-Bar` → `foo_bar`).

### `module-root`

Controls which directory is scanned for the module directory. Two common values:

| Value | Layout |
|-------|--------|
| `"src"` (default) | `src/<module>/__init__.py` |
| `""` | `<module>/__init__.py` (flat layout) |

### `module-name`

Overrides the derived module name. Use when:

- The directory name differs from the normalized package name (e.g. `sklearn` for
  `scikit-learn`).
- The module uses a non-standard casing (`FOO`).
- A dotted name is needed for a namespace sub-package.
- Multiple root modules must be bundled (list form — see below).

Type: `str | list[str]`. Default: `None` (derived from package name).

### Namespace packages

Namespace packages share a top-level directory without an `__init__.py` in it.

**Single namespace sub-module** — use a dotted `module-name`; no `namespace` flag needed:

```toml
[tool.uv.build-backend]
module-name = "foo.bar"
```

The directory `src/foo/` must **not** contain `__init__.py`; only `src/foo/bar/__init__.py`
exists.

**Explicit namespace root with sub-packages** — combine `module-name` with `namespace = true`
to declare the root while allowing multiple child `__init__.py` files:

```toml
[tool.uv.build-backend]
module-name = "foo"
namespace = true
```

**Multiple root modules** — pass a list (not recommended; use a workspace instead):

```toml
[tool.uv.build-backend]
module-name = ["foo", "bar"]
```

**Implicit namespace via `namespace = true`** — disables module-name safety checks and
packages everything found under `module-root`. Use only for legacy projects where listing
every module is impractical.

```toml
[tool.uv.build-backend]
namespace = true
```

### Type stub packages

Packages whose name ends in `-stubs` (e.g. `foo-stubs`) are treated as type stub packages.
The `-` is **not** normalized to `_`. The backend looks for `__init__.pyi` instead of
`__init__.py`. Namespace stubs are also supported (dotted `module-name` ending in `-stubs`).

## Examples

**Flat layout with custom module name:**

```text
pyproject.toml
FOO/
└── __init__.py
```

```toml
[tool.uv.build-backend]
module-name = "FOO"
module-root = ""
```

**src layout namespace sub-package (`foo.bar`):**

```text
pyproject.toml
src/
└── foo/
    └── bar/
        └── __init__.py
```

```toml
[tool.uv.build-backend]
module-name = "foo.bar"
```

**Namespace root with multiple sub-packages:**

```text
pyproject.toml
src/
└── foo/
    ├── bar/
    │   └── __init__.py
    └── baz/
        └── __init__.py
```

```toml
[tool.uv.build-backend]
module-name = "foo"
namespace = true
```

**Type stub package:**

```text
pyproject.toml
src/
└── foo-stubs/
    └── __init__.pyi
```

```toml
[project]
name = "foo-stubs"

[build-system]
requires = ["uv_build>=0.11.24,<0.12"]
build-backend = "uv_build"
```

No additional `[tool.uv.build-backend]` configuration is required; the `-stubs` suffix is
detected automatically.

## Caveats / Common Mistakes

- The `namespace` package in the `src/` directory (`foo/` when `module-name = "foo.bar"`)
  must **not** contain an `__init__.py`; adding one turns it into a regular package and
  breaks namespace semantics.
- `namespace = true` disables safety checks that prevent two packages from claiming the same
  module name. Prefer explicit `module-name` lists or a workspace.
- The `-stubs` suffix is preserved literally; do not use `foo_stubs` as the directory name.
- Multiple root modules bundled in one package (`module-name = ["foo", "bar"]`) is supported
  but discouraged — split them into a workspace instead.
- When `module-root = ""` (flat layout), the module directory sits next to `pyproject.toml`;
  ensure the directory name exactly matches `module-name` (case-sensitive).

## See Also

- bp-uv-build-backend
- bp-build-publish
- bp-build-backend-file-inclusion
- project-structure
- config-build-settings
