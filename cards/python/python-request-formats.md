---
id: python-request-formats
title: Python version request formats
category: python
tags: [python, installation, config]
source: https://docs.astral.sh/uv/concepts/python-versions/#requesting-a-version
related: [python-versions, python-discovery, python-pin, python-variants, python-install, python-support-matrix]
---

## Summary

uv accepts a rich set of version request syntaxes wherever a Python version can be specified —
`--python`, `uv python install`, `uv python find`, `.python-version` files, and more. Knowing
the full syntax prevents unnecessary downloads and lets you pin exactly what you need.

## Syntax / Usage

```
# Bare version number
--python 3
--python 3.12
--python 3.12.3

# PEP 440 version specifier
--python '>=3.12,<3.13'

# Variant suffixes (short and long forms)
--python 3.13t          # free-threaded (short)
--python 3.13+freethreaded  # free-threaded (long)
--python 3.12.0d        # debug (short)
--python 3.12.0+debug   # debug (long)
--python 3.14+gil       # force GIL-enabled build

# Implementation names (long or short, case-insensitive)
--python cpython        # or cp
--python pypy           # or pp
--python graalpy        # or gp
--python pyodide

# Implementation + version
--python cpython@3.12
--python cpython3.12
--python cp312
--python cpython>=3.12,<3.13

# Full platform triplet
--python cpython-3.12.3-macos-aarch64-none

# System interpreter: executable path, name on PATH, or install dir
--python /opt/homebrew/bin/python3
--python mypython3
--python /some/environment/
```

## Details

All formats are accepted by the `--python` flag and by `uv python install`, `uv python find`,
`uv python list`, and `.python-version` files. The only exception is that path-based forms
(executable path, name, install dir) cannot be used with `uv python install` because they
identify a local interpreter rather than a downloadable distribution.

**Bare version numbers** match on the components provided: `3` matches any Python 3.x, `3.12`
matches the latest patch of 3.12, `3.12.3` is an exact patch match.

**Version specifiers** follow PEP 440 syntax and can combine multiple constraints with commas
(`>=3.8,<3.10`). Quote them in the shell to prevent `<` and `>` from being interpreted.

**Implementation names** accept both long and short forms and are case-insensitive. Supported
implementations:

| Implementation | Long form  | Short form |
| -------------- | ---------- | ---------- |
| CPython        | `cpython`  | `cp`       |
| PyPy           | `pypy`     | `pp`       |
| GraalPy        | `graalpy`  | `gp`       |
| Pyodide        | `pyodide`  | —          |

**Variant suffixes** modify the build type:
- `t` / `+freethreaded` — free-threaded CPython (GIL disabled), available in CPython 3.13+.
  For 3.13 this must be requested explicitly. For 3.14+ a free-threaded interpreter on `PATH`
  may be used automatically, but GIL-enabled is still preferred unless you request `3.14t`.
- `d` / `+debug` — debug builds with assertions enabled; slower, not for general use.
- `+gil` — explicitly require the GIL-enabled variant; useful when both free-threaded and
  GIL-enabled 3.14+ interpreters are present and you need to enforce the GIL-enabled one.

**The full platform triplet** form `<impl>-<version>-<os>-<arch>-<libc>` (e.g.
`cpython-3.12.3-macos-aarch64-none`) pins down to a specific binary distribution. This is the
same format used in the managed-install directory names under `UV_PYTHON_INSTALL_DIR`.

**System interpreter forms** bypass discovery and point uv at a concrete interpreter:
- An absolute path to an executable (`/opt/homebrew/bin/python3`)
- An executable name that will be resolved on `PATH` (`mypython3`)
- A directory that is an installed environment (`/some/environment/`)

## Examples

```bash
# Install the latest CPython 3.12 patch
uv python install 3.12

# Install an exact patch version
uv python install 3.12.3

# Install free-threaded Python 3.13
uv python install 3.13t
# or equivalently:
uv python install 3.13+freethreaded

# Install a debug build
uv python install 3.12.0+debug

# Install PyPy
uv python install pypy

# Install GraalPy
uv python install graalpy

# Run a script with Python satisfying a range
uv run --python '>=3.11,<3.13' python -V

# Find a specific implementation + version
uv python find cpython@3.11

# Use short-form implementation + version
uv run --python cp312 python -V

# Pin project to a full triplet (portable, CI-friendly)
uv python pin cpython-3.12.3-macos-aarch64-none

# Use a system interpreter by path
uv run --python /opt/homebrew/bin/python3 python -V

# Force GIL-enabled Python 3.14
uv run --python 3.14+gil python -V
```

## Caveats / Common Mistakes

- Pre-releases are not selected by default. A pre-release is only used when no stable release
  satisfies the request. To force a pre-release, provide the exact version string (e.g. `3.14.0a1`).
- Free-threaded (`t` / `+freethreaded`) and debug (`d` / `+debug`) builds are not selected by
  default — they must be requested explicitly for CPython 3.13 and below.
- Version specifiers must be quoted in the shell (`'>=3.12,<3.13'`) because `<` and `>` are
  shell metacharacters.
- Path-based forms (`/path/to/python`, executable name, install dir) cannot be used with
  `uv python install` — that command only accepts version/implementation requests for
  downloadable distributions.
- The available Python versions are frozen at each uv release. To access new Python versions
  you may need to upgrade uv itself (`uv self update`).

## See Also

- python-versions
- python-discovery
- python-pin
- python-variants
- python-install
- python-support-matrix
