---
id: python-versions
title: Managing Python versions with uv
category: python
tags: [python, command, installation, config]
source: https://docs.astral.sh/uv/concepts/python-versions/
related: [project-structure, cmd-run, tool-run, integration-docker, python-support-matrix]
---

## Summary

uv installs and manages standalone Python interpreters, so projects can pin and use a
specific version without a separate tool like pyenv. The `.python-version` file records
the project's chosen version.

## Syntax / Usage

```bash
uv python install <request>
uv python pin <version>
uv python list
uv python find <request>
```

## Details

uv downloads self-contained CPython builds (Astral's `python-build-standalone`), plus
PyPy and Pyodide. Requests accept many forms: `3`, `3.12`, `3.12.3`, specifiers like
`>=3.12,<3.13`, implementation tags (`cpython`, `pypy`, `pp`), combined forms
(`pypy@3.10`), and variants such as `3.13t` (free-threaded) or `3.13d` (debug).

`uv python pin <version>` writes a `.python-version` file in the current directory
(`--global` writes it to the user config dir). uv searches the working directory and
parents for `.python-version`, then the user config; `--no-config` disables this.

Interpreter discovery order: uv-managed installs in `UV_PYTHON_INSTALL_DIR` → `python`
on `PATH` → Windows registry / Store → a compatible managed download if none found. For
managed versions uv prefers the newest; for system versions it takes the first
compatible one, not the newest.

By default uv downloads missing versions automatically. Restrict this with
`--no-python-downloads`, the `python-downloads = "manual"` setting, `--managed-python`
(managed only), or `--no-managed-python` (system only). `UV_PYTHON` sets a default
request via environment.

## Examples

```bash
# Install specific versions
uv python install 3.12.3
uv python install 3.11 3.12 3.13

# Pin this project to 3.12 (writes .python-version)
uv python pin 3.12

# List and locate interpreters
uv python list
uv python find '>=3.11'

# Free-threaded build
uv python install 3.13t

# Use a version for a single run
uv run --python 3.11 python -V
```

## Caveats / Common Mistakes

- Pre-releases and debug/free-threaded builds are not selected by default — request them
  explicitly (e.g. `3.13t`, or a pre-release specifier).
- In restricted environments, set `python-downloads = "manual"` (or `UV_PYTHON_DOWNLOADS=0`)
  so uv never reaches out to download an interpreter unexpectedly.

## See Also

- project-structure
- cmd-run
- tool-run
- integration-docker
- python-support-matrix
