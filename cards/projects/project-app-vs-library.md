---
id: project-app-vs-library
title: Applications vs libraries: project types in uv
category: projects
tags: [project, build, config, command]
source: https://docs.astral.sh/uv/concepts/projects/init/
related: [project-structure, cmd-init, project-packaging, bp-build-publish, dep-add]
---

## Summary

`uv init` supports three project types — plain application, packaged application, and library —
distinguished primarily by whether a build system is declared. The presence of a `[build-system]`
table controls whether uv builds and installs the project itself into its environment.

## Syntax / Usage

```bash
uv init my-app                         # plain application (default, --app implied)
uv init --package my-pkg               # packaged application (build system added)
uv init --lib my-lib                   # library (build system + src layout + py.typed)
uv init --build-backend maturin my-ext # extension module project (implies --package)
uv init --bare my-minimal              # pyproject.toml only, no extra files
```

## Details

### Plain application (default / `--app`)

The default template. Suitable for web servers, scripts, and CLIs that will not be
distributed as a package.

- Generates `pyproject.toml`, `main.py`, `README.md`, `.python-version`.
- **No `[build-system]` table.** uv does not build or install the project itself; only
  its dependencies are installed into the environment.
- Flat layout — source files sit at the project root alongside `pyproject.toml`.

```toml
# pyproject.toml produced by uv init my-app
[project]
name = "my-app"
version = "0.1.0"
description = "Add your description here"
readme = "README.md"
requires-python = ">=3.11"
dependencies = []
```

### Packaged application (`--package`)

Use when you need entry points (console scripts), a `src`/`tests` layout, or plan to
publish to PyPI.

- Generates a `src/<name>/` directory with `__init__.py`.
- Adds a `[build-system]` block (defaults to `uv_build`; override with `--build-backend`).
- Includes a `[project.scripts]` entry so the package name becomes a runnable command.
- uv builds and installs the project package into the environment on `uv sync` / `uv run`.

### Library (`--lib`)

For code intended to be imported by other projects and distributed. `--lib` implies
`--package`.

- Same `src` layout as a packaged application.
- Adds `py.typed` marker file, signalling to type checkers that the library ships inline
  type information.
- No `[project.scripts]` entry by default (libraries expose an API, not a CLI).
- The `src` layout isolates the installed package from any bare `python` invocations in
  the project root — important for avoiding subtle import shadowing during development.

### Extension modules (`--build-backend maturin|scikit-build-core`)

For projects with native code (Rust, C, C++, FORTRAN, Cython). `--build-backend` implies
`--package`. Supported backends:

| Backend            | Language(s)              |
| ------------------ | ------------------------ |
| `maturin`          | Rust                     |
| `scikit-build-core`| C, C++, FORTRAN, Cython  |

maturin projects also include `Cargo.toml` and `src/lib.rs`. scikit-build-core projects
include CMake configuration and a `main.cpp`. Both configure `tool.uv.cache-keys` to
track source file changes for cache invalidation.

### Bare (`--bare`)

Skips all generated files (README, `.python-version`, source directories, git init)
and omits extra metadata fields (`description`, `authors`) from `pyproject.toml`.
Produces the smallest possible scaffold. Can be combined with `--lib`, `--package`, or
`--build-backend` — in those cases a build system is still configured but no source tree
is created.

### Overriding packaging behavior

Even after project creation, the packaging behavior can be forced on or off:

- `tool.uv.package = true` — force the project to be built and installed even without a
  `[build-system]` table (uv falls back to setuptools legacy).
- `tool.uv.package = false` — prevent uv from building/installing the project even when
  a `[build-system]` table is present.

## Examples

```bash
# Plain application — run a script directly
uv init my-app
cd my-app
uv run main.py

# Packaged application — run via the declared entry point
uv init --package my-pkg
cd my-pkg
uv run my-pkg

# Library — import it in a REPL
uv init --lib my-lib
cd my-lib
uv run python -c "import my_lib; print(my_lib.hello())"

# Extension module with Rust
uv init --build-backend maturin my-ext
cd my-ext
uv run my-ext

# Packaged application with hatchling instead of uv_build
uv init --package --build-backend hatchling my-pkg-hatch

# Bare library scaffold (CI / templating)
uv init --lib --bare my-lib-minimal
```

Resulting directory structures:

```text
# plain application
my-app/
├── .python-version
├── README.md
├── main.py
└── pyproject.toml

# packaged application / library
my-pkg/                     my-lib/
├── .python-version         ├── .python-version
├── README.md               ├── README.md
├── pyproject.toml          ├── pyproject.toml
└── src/                    └── src/
    └── my_pkg/                 └── my_lib/
        └── __init__.py             ├── py.typed
                                    └── __init__.py
```

## Caveats / Common Mistakes

- **`--lib` always implies `--package`.** Libraries always require a build system; you
  cannot create an unpackaged library.
- **`--build-backend` always implies `--package`.** Specifying an alternative backend
  automatically opts you in to a packaged project.
- **Extension module cache invalidation.** maturin and scikit-build-core projects use
  `tool.uv.cache-keys` to detect changed source files. If you change files outside those
  keys, run with `--reinstall` to force a rebuild.
- **`main.py` vs `hello.py`.** Prior to uv v0.6.0, the generated entrypoint was named
  `hello.py`, not `main.py`. Scripts that rely on the old filename will need updating.
- **Choosing `--bare` + `--lib` together** configures the build system in `pyproject.toml`
  but does not create any source files — you must create `src/<name>/__init__.py` manually.

## See Also

- project-structure
- cmd-init
- project-packaging
- bp-build-publish
- dep-add
