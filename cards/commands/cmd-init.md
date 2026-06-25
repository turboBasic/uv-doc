---
id: cmd-init
title: uv init — create a new project
category: commands
tags: [command, project, build, workspace, python]
source: https://docs.astral.sh/uv/concepts/projects/init/
related: [project-structure, dep-add, cmd-sync, project-workspaces, python-pin]
---

## Summary

`uv init` scaffolds a new Python project by generating a `pyproject.toml` and optional
supporting files. It supports four project shapes — app, packaged app, library, and
extension module — each producing a different file layout.

## Syntax / Usage

```bash
uv init [OPTIONS] [PATH]
```

`PATH` defaults to the current working directory for app/library projects. When omitted,
the project is created in-place. Providing a name (e.g. `uv init myproject`) creates a
subdirectory.

## Details

### Project templates

**Application (default / `--app`)**

No build system; the project is not installed into the environment. Suited for scripts,
CLIs, and web servers that run in-place rather than being distributed as a package.

Generated layout:

```
example-app/
├── .python-version
├── README.md
├── main.py
└── pyproject.toml
```

The `pyproject.toml` has no `[build-system]` table. `main.py` contains a minimal `main()`
function. Note: prior to v0.6.0, uv created `hello.py` instead of `main.py`.

**Packaged application (`--app --package`)**

Adds a `[build-system]` table (uv build backend by default) and a `[project.scripts]`
entry point. Uses a `src/` layout. Appropriate when the app will be distributed via PyPI.

Generated layout:

```
example-pkg/
├── .python-version
├── README.md
├── pyproject.toml
└── src/
    └── example_pkg/
        └── __init__.py
```

**Library (`--lib`)**

Implies `--package`. Uses a `src/` layout and includes a `py.typed` marker file so
consumers can read type information from the library. Intended to be built and published
to PyPI.

Generated layout:

```
example-lib/
├── .python-version
├── README.md
├── pyproject.toml
└── src/
    └── example_lib/
        ├── __init__.py
        └── py.typed
```

**Extension module (`--build-backend maturin` or `--build-backend scikit`)**

Implies `--package`. For projects with compiled extensions (Rust via maturin, C/C++/Cython
via scikit-build-core). Generates language-specific scaffolding alongside Python files.
For maturin: adds `Cargo.toml` and `src/lib.rs`. For scikit-build-core: CMake
configuration and a `main.cpp` file.

### Key flags

| Flag | Description |
|------|-------------|
| `--app`, `--application` | Create an application project (default). |
| `--lib`, `--library` | Create a library project (implies `--package`). |
| `--package` | Add a `[build-system]` table; use `src/` layout. |
| `--no-package` | Suppress the build system (default for `--app`). |
| `--build-backend <backend>` | Choose the build backend: `uv` (default), `hatch`, `flit`, `pdm`, `poetry`, `setuptools`, `maturin`, `scikit`. Implies `--package`. Can also be set via `UV_INIT_BUILD_BACKEND`. |
| `--bare` | Create only a `pyproject.toml`; skip README, `.python-version`, `src/` tree, and VCS init. Can be combined with `--lib` or `--build-backend`. |
| `--no-workspace`, `--no-project` | Do not auto-join a parent workspace even if one is found. |
| `--vcs <vcs>` | VCS to initialize: `git` (default) or `none`. |
| `--python-pin` | Create a `.python-version` file (on by default; use `--no-pin-python` to suppress). |
| `--author-from <source>` | Populate `authors` in `pyproject.toml`: `auto` (default), `git`, or `none`. |
| `--description <text>` | Set the project description field. |
| `--name <name>` | Override the project name (defaults to directory name). |
| `--python`, `-p` | Python interpreter to use when determining the minimum supported version. |
| `--script` | Create a PEP 723 standalone script instead of a project. |

### Workspace auto-detection

When `uv init` is run inside a directory that has a `pyproject.toml` with a
`[tool.uv.workspace]` table anywhere in the parent tree, uv automatically adds the new
project as a workspace member. Pass `--no-workspace` to create a standalone project
instead.

### Lazy initialization

The virtual environment (`.venv`) and lockfile (`uv.lock`) are not created by `uv init`.
They are created lazily on the first `uv sync` or `uv run` invocation.

## Examples

```bash
# Bare application in the current directory
uv init

# Application in a new subdirectory
uv init my-app

# Library with the default (uv) build backend
uv init --lib my-lib

# Packaged app with hatchling as the build backend
uv init --package --build-backend hatch my-cli

# Rust extension module (requires maturin)
uv init --build-backend maturin my-ext

# Minimal pyproject.toml only, no extra files or VCS
uv init --bare my-bare-project

# Bare project, but opt into specific extras
uv init --bare --description "Hello world" --author-from git --vcs git --python-pin my-project

# Initialize inside an existing workspace root — new member added automatically
cd /path/to/workspace
uv init packages/new-service

# Same, but keep it standalone (not a workspace member)
uv init --no-workspace packages/new-service

# PEP 723 script
uv init --script my-script.py
```

## Caveats / Common Mistakes

- If a `pyproject.toml` already exists in the target directory, `uv init` exits with an
  error. Use a fresh directory or remove the existing file first.
- `--lib` always implies `--package`. You cannot create an unpackaged library.
- `--build-backend` implies `--package`, so passing both `--app` and `--build-backend`
  produces a packaged app with a `[project.scripts]` entry point and `src/` layout, not
  a plain app.
- `--bare` skips VCS initialization. If you need Git, pass `--vcs git` explicitly when
  using `--bare`.
- The `.venv` and `uv.lock` are **not** created by `uv init` — they appear on first
  `uv sync` or `uv run`.
- When uv init is run inside an existing workspace it will automatically add the new
  project as a member. This modifies the workspace root's `pyproject.toml`. Use
  `--no-workspace` to prevent this.

## See Also

- project-structure
- dep-add
- cmd-sync
- project-workspaces
- python-pin
