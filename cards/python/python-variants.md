---
id: python-variants
title: Python build variants: free-threaded and debug
category: python
tags: [python, installation, troubleshooting]
source: https://docs.astral.sh/uv/concepts/python-versions/#free-threaded-python
related: [python-versions, python-install, python-request-formats, python-pin, python-downloads-control, python-support-matrix]
---

## Summary

uv supports two non-standard CPython build variants — free-threaded (no GIL) and debug (assertions
enabled) — plus pre-release interpreters. Each has distinct selection rules: free-threaded is
opt-in for 3.13 but relaxed for 3.14+, debug is always a fallback unless explicitly requested,
and pre-releases are only used when no stable match exists.

## Syntax / Usage

```bash
# Free-threaded (short form / long form)
uv python install 3.13t
uv python install 3.13+freethreaded

# Force GIL-enabled build when free-threaded might be selected
uv python install 3.14+gil

# Debug build (short form / long form)
uv python install 3.13d
uv python install 3.13+debug

# Pre-release (must use specifier or explicit version)
uv python install 3.14.0a1
uv python install 'cpython>=3.14.0a1'
```

## Details

### Free-threaded Python (3.13t / `+freethreaded`)

CPython 3.13 shipped an experimental free-threaded build that removes the Global Interpreter Lock
(GIL). uv supports discovering and installing these builds.

**Python 3.13 — strict opt-in.** Free-threaded builds are never selected by default. They are used
only when explicitly requested via `3.13t`, `3.13+freethreaded`, or an equivalent form.

**Python 3.14+ — relaxed auto-selection.** For 3.14 and later, uv will allow a free-threaded
interpreter to satisfy a generic request (e.g., `uv python install 3.14`) if it is the first
compatible interpreter found — for example, if it appears before a GIL-enabled build on `PATH`.
The GIL-enabled build is still preferred when both are available.

**Forcing the GIL-enabled build.** When both variants are present and you want to guarantee the
GIL-enabled interpreter, use the `+gil` variant specifier: `3.14+gil`.

### Debug builds (3.13d / `+debug`)

Debug builds of CPython have debug assertions enabled and symbols not stripped. They are slower
and not appropriate for general use, but can be valuable when debugging Python processes with a
C-level debugger.

Debug builds are treated as fallbacks: uv will use a debug build only if no other available
installation satisfies the request. To request one explicitly, use `3.13d` or `3.13+debug`.

Note: standard uv-managed CPython builds have debug symbols stripped for smaller distribution
size. Debug builds specifically retain those symbols.

### Python pre-releases

Pre-release interpreters (alpha, beta, release candidates) are not selected by default. uv will
use a pre-release only when:

- No stable version matches the request, or
- A pre-release is the only available installation for the requested version, or
- The path to a pre-release executable is given directly.

If a pre-release matches the request and is available, uv will not download a stable version in
its place.

## Examples

```bash
# Install and use a free-threaded 3.13 interpreter
uv python install 3.13t
uv run --python 3.13t python -c "import sys; print(sys._is_gil_enabled())"

# Install a free-threaded 3.14 interpreter (long form)
uv python install 3.14+freethreaded

# When 3.14 free-threaded is on PATH but you need the GIL-enabled build
uv python install 3.14+gil
uv venv --python 3.14+gil

# Install and verify a debug build
uv python install 3.13d
uv run --python 3.13d python -c "import sys; print(sys.version)"

# Use a pre-release explicitly
uv run --python 3.14.0a1 python -V

# List all variants including free-threaded and debug
uv python list --all-versions
```

## Caveats / Common Mistakes

- For Python 3.13, a request for `3.13` will never resolve to `3.13t`. You must use `3.13t` or
  `3.13+freethreaded` explicitly.
- For Python 3.14+, a generic `3.14` request may resolve to the free-threaded build if it appears
  first on `PATH`. Use `3.14+gil` to pin the GIL-enabled build in projects where the GIL is
  required.
- Debug builds are significantly slower — do not use them in production or performance-sensitive
  environments.
- Pre-release interpreters are not automatically downloaded; if you need one, request it
  explicitly or set `python-downloads = "automatic"` in your config.
- Available Python variants are frozen per uv release. If a new variant (e.g., a newer 3.13t
  patch) is not available, upgrade uv first.

## See Also

- python-versions
- python-install
- python-request-formats
- python-pin
- python-downloads-control
- python-support-matrix
