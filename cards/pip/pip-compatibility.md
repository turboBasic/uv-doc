---
id: pip-compatibility
title: uv pip compatibility with pip and pip-tools — known differences
category: pip
tags: [pip, installation, resolution, index, config, venv, troubleshooting]
source: https://docs.astral.sh/uv/pip/compatibility/
related: [pip-install, pip-compile, config-env-vars, concept-indexes, pip-environments]
---

## Summary

uv is designed as a drop-in replacement for common `pip` and `pip-tools` workflows, but it
is not an exact clone. This card documents the known, intentional behavioral differences
so you can anticipate where a straight substitution may fail.

## Details

### Configuration files and environment variables

uv does not read `pip.conf` or any `PIP_*` environment variables (e.g., `PIP_INDEX_URL`).
Use the uv equivalents instead: `UV_INDEX_URL`, `UV_EXTRA_INDEX_URL`, etc., or set
persistent options in `uv.toml` / `[tool.uv.pip]` in `pyproject.toml`.

### Pre-release handling

uv accepts pre-release versions only when:

1. The package is a **direct** dependency and its version specifier includes a pre-release
   marker (e.g., `flask>=2.0.0rc1`).
2. All published versions of a package are pre-releases.

uv will **not** automatically accept pre-releases for transitive dependencies the way pip
does (prior to pip 26.0, pip's behavior was inconsistent). To allow pre-releases globally,
pass `--prerelease allow`. To allow them for a specific transitive package, add it as a
direct dependency with a pre-release specifier.

### Multi-index strategy

When multiple indexes are configured, uv defaults to `--index-strategy first-index`:
it iterates indexes in order (extra-index-url first, then default) and stops at the first
index that contains the package. pip combines candidates from all indexes and picks the
best version (`unsafe-best-match`), with no guaranteed ordering.

uv's default prevents dependency-confusion attacks. To replicate pip behavior, pass
`--index-strategy unsafe-best-match` (or set `UV_INDEX_STRATEGY=unsafe-best-match`), but
be aware of the security implications.

Available strategies:

- `first-index` (default): candidates from first matching index only
- `unsafe-first-match`: prefer first index with a compatible version
- `unsafe-best-match`: combine all indexes (closest to pip)

### PEP 517 build isolation

uv enables PEP 517 build isolation by default (equivalent to `pip install --use-pep517`).
pip still defaults to legacy behavior for some packages. If a package fails to build due
to missing build-time dependencies, preinstall those dependencies and use
`--no-build-isolation`:

```bash
uv pip install wheel && uv pip install --no-build-isolation biopython==1.77
```

### Virtual environments required by default

`uv pip install` and `uv pip sync` require a virtual environment. uv looks for, in order:

1. An active virtualenv (`VIRTUAL_ENV`)
2. An active Conda environment (`CONDA_PREFIX`)
3. A `.venv` directory in the current or any parent directory

If none is found, uv exits with an error. pip, by contrast, installs into the system
Python when no venv is active. To replicate pip's behavior, pass `--system` (installs
into the first Python on `PATH`) or `--python /path/to/python`.

### `--user` not supported

uv does not implement `--user` or the user install scheme. Use virtual environments
instead. uv also does not fall back to a user install when lacking write permissions to
the target directory (unlike pip).

### `--only-binary` enforcement for direct URLs

When `--only-binary :all:` is set, pip skips the restriction for direct URL dependencies
and will still build source distributions from them. uv enforces `--only-binary` for
direct URL dependencies as well, with one exception: if uv cannot infer the package name
ahead of time from the URL, it will build the sdist to read metadata.

### `--no-binary` enforcement

When `--no-binary` is provided, uv refuses to install pre-built wheels from registries,
but **will** reuse wheels already present in the local cache. Unlike pip, uv's resolver
still reads metadata from cached wheels during resolution even when `--no-binary` is set.

### Bytecode compilation off by default

uv does **not** compile `.py` files to `.pyc` / `__pycache__` during installation, unlike
pip. Enable it with `--compile-bytecode` (or `UV_COMPILE_BYTECODE=1`). Skipping bytecode
compilation may expose `SyntaxWarning` or `DeprecationWarning` messages that pip normally
suppresses.

### `egg` support limitations

uv does not support installing new `.egg`-style or `.egg-info`-style distributions.
However, it will **respect** existing `.egg-info` and legacy editable `.egg-link`
distributions found in an environment: it lists them with `uv pip list` / `uv pip freeze`
and removes them with `uv pip uninstall`.

### Resolution strategy differences

uv and pip can produce different (but equally valid) resolutions for the same input. uv
gives priority to the user-provided package ordering; pip has additional tie-breaking
priorities. Swapping the order of packages on the command line or in a requirements file
can change the uv resolution more than it would change pip's.

### `requires-python` upper bounds ignored

uv ignores upper bounds on `requires-python` (e.g., `>=3.8,<4` is treated as `>=3.8`).
Respecting upper bounds frequently causes resolvers to backtrack to very old versions of
packages, producing formally correct but practically wrong results.

### `pip compile` output defaults

Differences from `pip-compile` defaults:

| Behavior | `pip-compile` default | `uv pip compile` default |
|---|---|---|
| Output file | stdout | must pass `-o`/`--output-file` explicitly |
| Extras in output | `--no-strip-extras` | `--strip-extras` |
| Index URLs in output | emitted if non-default | not emitted (pass `--emit-index-url`) |

### Wheel filename validation

uv rejects wheels whose filename is inconsistent with the metadata inside the wheel (e.g.,
name says `1.0.0` but metadata says `1.0.1`). pip accepts such wheels. To override:
`UV_SKIP_WHEEL_FILENAME_CHECK=1`.

### Package name normalization

uv normalizes package names to their
[PEP 503](https://peps.python.org/pep-0503/) canonical forms in all output (e.g.,
`docstring-parser`, `jaraco-classes`, `pymupdfb`). pip preserves the verbatim name as
published (e.g., `docstring_parser`, `jaraco.classes`, `PyMuPDFb`). This matters when
diffing `pip list` output against `uv pip list` output.

### Build constraints

`--constraint` (and `UV_CONSTRAINT`) is **not** applied to build dependencies. Use the
dedicated `--build-constraint` (or `UV_BUILD_CONSTRAINT`) for that. pip applies
`PIP_CONSTRAINT` to build deps but not `--constraint` on the CLI — so the behavior
differs in which direction the asymmetry runs.

## Examples

```bash
# Use UV_* instead of PIP_* — pip.conf is not read
export UV_INDEX_URL=https://my-registry.example.com/simple
uv pip install my-private-package

# Allow pre-releases globally
uv pip install --prerelease allow "black>=24.0.0b1"

# Replicate pip's unsafe multi-index behavior
uv pip install --index-strategy unsafe-best-match requests

# Install without build isolation (legacy packages)
uv pip install wheel
uv pip install --no-build-isolation biopython==1.77

# Compile with output file and index URL in output
uv pip compile requirements.in -o requirements.txt --emit-index-url

# Enable bytecode compilation (recommended in Docker)
uv pip install --compile-bytecode -r requirements.txt

# Use system Python instead of requiring a venv
uv pip install --system requests

# Skip wheel filename validation for a misbehaving wheel
UV_SKIP_WHEEL_FILENAME_CHECK=1 uv pip install ./broken-wheel.whl
```

## Caveats / Common Mistakes

- Setting `PIP_INDEX_URL` or `PIP_EXTRA_INDEX_URL` has **no effect** on uv. The
  environment variables must be named `UV_INDEX_URL` / `UV_EXTRA_INDEX_URL`.
- `uv pip install` will fail if no virtual environment exists and `--system` is not
  passed. Create one first with `uv venv`.
- The default `first-index` multi-index strategy means that a package found on an
  extra-index will never fall through to PyPI for newer versions. If you expect pip's
  "best version wins" behavior, you must opt in explicitly with `--index-strategy
  unsafe-best-match`.
- Bytecode compilation is disabled by default; set `UV_COMPILE_BYTECODE=1` in Docker
  builds or other performance-sensitive environments.
- Pre-release versions of transitive dependencies are **not** automatically accepted —
  you must add the transitive package as a direct dependency with a pre-release specifier,
  or pass `--prerelease allow`.
- `uv pip compile` does not write to stdout by default; always pass `-o <file>`.

## See Also

- pip-install
- pip-compile
- config-env-vars
- concept-indexes
- pip-environments
