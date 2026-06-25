---
id: python-distributions
title: "Managed Python distributions: python-build-standalone, PyPy, Pyodide"
category: python
tags: [python, installation, performance]
source: https://docs.astral.sh/uv/concepts/python-versions/#managed-python-distributions
related: [python-versions, python-install, python-storage, python-request-formats, ts-python-not-found, python-support-matrix]
---

## Summary

uv downloads self-contained CPython builds from `python-build-standalone`, plus PyPy and
Pyodide distributions. Understanding the source, quality trade-offs, and quirks of each
distribution type prevents surprises when working across platforms or alternative runtimes.

## Details

### CPython distributions

Python does not publish official distributable CPython binaries. uv instead uses pre-built
distributions from Astral's
[`python-build-standalone`](https://github.com/astral-sh/python-build-standalone) project —
the same distributions used by Mise and `bazelbuild/rules_python`.

These distributions are:

- **Self-contained** — no preinstalled system dependencies required (unlike building from
  source with `pyenv`).
- **Highly portable** — a single binary runs across a wide range of Linux, macOS, and
  Windows versions.
- **Optimized** — built with PGO (Profile Guided Optimization) and LTO (Link-Time
  Optimization), which produces faster executables than a default source build.

Because portability drives many decisions in `python-build-standalone`, the distributions
have some behavior quirks. See the
[`python-build-standalone` quirks documentation](https://gregoryszorc.com/docs/python-build-standalone/main/quirks.html)
for the full list.

### PyPy distributions

PyPy distributions are sourced directly from the [PyPy project](https://pypy.org). PyPy
versions lag behind CPython; as of current uv releases, managed PyPy supports Python
versions up to 3.11. PyPy upgrades (patch bumps) are not currently supported by
`uv python upgrade`.

### Pyodide distributions

Pyodide distributions are sourced from the [Pyodide project](https://github.com/pyodide/pyodide).
Pyodide is a port of CPython for the WebAssembly / Emscripten platform. It is used when
running Python in browser environments or other WASM runtimes. Pyodide upgrades are also not
currently supported by `uv python upgrade`.

### GraalPy

GraalPy is supported as a Tier 2 implementation. uv can discover and use GraalPy
interpreters, but managed GraalPy installations are not provided by uv — you must install
GraalPy separately. GraalPy upgrades via `uv python upgrade` are not currently supported.

### Available versions are frozen per uv release

The list of downloadable Python versions is bundled with each uv release. If a new CPython
patch or a new PyPy release becomes available upstream, uv cannot download it until uv
itself is upgraded. This is by design — it ensures reproducibility but means you must keep
uv current to access new Python versions.

### Transparent x86_64 emulation on aarch64

Both macOS (via [Rosetta 2](https://support.apple.com/en-gb/102527)) and Windows (via
[Windows on ARM emulation](https://learn.microsoft.com/en-us/windows/arm/apps-on-arm-x86-emulation))
support running x86_64 binaries on aarch64 hardware transparently. As a result:

- An x86_64 uv binary can use an aarch64 Python interpreter, or vice versa.
- A Python interpreter needs packages compiled for **its** architecture — mixing
  architectures in a single virtual environment is not supported.

### Windows registry registration (PEP 514)

On Windows, managed Python installations are registered in the Windows registry per
[PEP 514](https://peps.python.org/pep-0514/). This makes them discoverable by the
`py` launcher. On uninstall, uv removes the registry entry for the target version and cleans
up any broken entries left by prior installs.

## Examples

```bash
# Install the latest CPython (python-build-standalone)
uv python install 3.13

# Install PyPy 3.10 (sourced from pypy.org)
uv python install pypy@3.10

# Install Pyodide (WebAssembly/Emscripten variant)
uv python install pyodide

# List all available managed distributions including other platforms
uv python list --all-platforms

# On Windows: use the py launcher to invoke a uv-managed CPython
uv python install 3.13.1
py -V:Astral/CPython3.13.1

# Reinstall to pick up distribution improvements without a version change
uv python install --reinstall
```

## Caveats / Common Mistakes

- **PyPy version lag:** PyPy managed distributions currently top out at Python 3.11. If
  your project requires PyPy 3.12+, it is not yet available as a managed distribution.
- **`python-build-standalone` quirks:** portability trade-offs mean a small number of
  standard library behaviors differ from a system CPython build. Review the upstream quirks
  documentation before assuming parity.
- **Available versions are frozen:** if you need a freshly released CPython patch that is
  not yet in uv's bundle, upgrade uv first (`uv self update`), then install the new version.
- **Architecture mixing on aarch64:** using an x86_64 Python under Rosetta 2 / WoA
  emulation is possible, but all packages in the virtual environment must target the same
  architecture as the interpreter — not the host architecture.
- **Upgrades not supported for all distributions:** `uv python upgrade` only works for
  CPython managed by uv. PyPy, GraalPy, and Pyodide must be explicitly reinstalled.

## See Also

- python-versions
- python-install
- python-storage
- python-request-formats
- ts-python-not-found
- python-support-matrix
