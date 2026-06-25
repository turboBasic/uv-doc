---
id: script-python-version
title: Python version selection for scripts
category: scripts
tags: [script, python, command, config]
source: https://docs.astral.sh/uv/guides/scripts/
related: [script-inline-metadata, python-versions, python-request-formats, python-downloads-control, cmd-run]
---

## Summary

When running a standalone script with `uv run`, the Python interpreter is chosen by
`requires-python` in the script's PEP 723 metadata block, overridable per-invocation
with `--python`. uv downloads a matching interpreter automatically if none is found
locally. This is independent of any project-level Python pin.

## Syntax / Usage

```bash
# Let requires-python in the script drive selection
uv run example.py

# Override the interpreter for this invocation
uv run --python 3.11 example.py
uv run --python 'cpython>=3.12,<3.13' example.py

# Scaffold a script with a Python version baked in
uv init --script example.py --python 3.12
```

## Details

### requires-python in inline metadata

A `requires-python` field in the PEP 723 `# /// script` block specifies the minimum
(or range of) Python version(s) the script needs. When `uv run` executes the script,
it selects the first interpreter that satisfies the constraint. If no matching
interpreter is installed, uv downloads one automatically (unless automatic downloads
are disabled).

```python
# /// script
# requires-python = ">=3.12"
# dependencies = ["rich"]
# ///
```

`requires-python` accepts PEP 440 version specifiers (`>=3.12`, `>=3.11,<3.13`, etc.).

### --python flag

`--python` (short: `-p`) accepts all standard uv version request formats — bare
versions (`3.11`), specifiers (`>=3.12`), implementation tags (`cpython@3.12`,
`pypy`), full tuples (`cpython-3.12.3-macos-aarch64-none`), or paths to an interpreter
binary. The `UV_PYTHON` environment variable sets the same default.

When both `requires-python` in metadata and `--python` are present, `--python` is
applied as the interpreter to use for the run environment; if the flag satisfies the
`requires-python` constraint the run proceeds, otherwise uv reports an error.

### Automatic Python downloads

By default (`python-downloads = "automatic"`) uv downloads a managed CPython build
when no installed interpreter satisfies the request. To restrict downloads to explicit
`uv python install` calls, set `python-downloads = "manual"` in `uv.toml` /
`pyproject.toml`, or pass `--no-python-downloads` per command.

### How script Python selection differs from project Python pinning

In a project, the Python version is driven by `requires-python` in `pyproject.toml`
plus the `.python-version` file (written by `uv python pin`). Scripts bypass all of
that: even when `uv run` is invoked inside a project directory, a script with inline
metadata is executed in an isolated environment using the interpreter chosen by the
script's own `requires-python` or the `--python` flag — the project's pinned version
and the project's dependencies are both ignored.

If the script has no inline metadata and no `--python` flag, uv uses the first
available interpreter from the standard discovery chain (managed installs, `PATH`,
Windows registry) without consulting any `.python-version` file for script execution.

## Examples

```python
# example.py — requires Python 3.12+
# /// script
# requires-python = ">=3.12"
# dependencies = ["httpx"]
# ///

import sys, httpx
print(sys.version)
print(httpx.get("https://example.com").status_code)
```

```bash
# uv selects (or downloads) a Python >=3.12 interpreter automatically
uv run example.py

# Force a specific version for this run
uv run --python 3.11 example.py

# Force a PyPy interpreter
uv run --python pypy3.10 example.py

# Disable automatic downloads — fail if no matching interpreter is installed
uv run --no-python-downloads example.py

# Scaffold a new script pre-filled with the inline metadata block
uv init --script new_script.py --python 3.12
```

## Caveats / Common Mistakes

- `requires-python` constrains which interpreter is selected; `--python` names the
  interpreter to use. Passing a `--python` value that does not satisfy the script's
  `requires-python` causes an error — it does not silently override the constraint.
- Scripts with inline metadata ignore project-level `.python-version` pins and
  `requires-python` in `pyproject.toml`. Do not rely on the surrounding project to
  control the interpreter for a standalone script.
- Without inline metadata, uv does not search for a `.python-version` file when running
  a standalone script outside a project context; the version is whatever the discovery
  chain returns first.
- Automatic interpreter downloads require network access. In air-gapped or CI
  environments, pre-install the required versions with `uv python install` and set
  `python-downloads = "manual"`.

## See Also

- script-inline-metadata
- python-versions
- python-request-formats
- python-downloads-control
- cmd-run
