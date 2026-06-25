---
id: config-python-discovery
title: Python discovery and preference settings
category: configuration
tags: [config, python, installation]
source: https://docs.astral.sh/uv/concepts/python-versions/#adjusting-python-version-preferences
related: [config-files, python-versions, python-discovery, python-downloads-control, config-project-env-settings]
---

## Summary

uv exposes a small set of settings — `python-preference`, `python-downloads`, `python-install-mirror`, and the `UV_PYTHON_INSTALL_DIR` / `UV_PYTHON` environment variables — that control which Python interpreters are found, how they are ranked, and whether managed installs may be downloaded automatically.

## Syntax / Usage

```toml
# pyproject.toml or uv.toml
[tool.uv]
python-preference = "managed"   # managed | only-managed | system | only-system
python-downloads  = "automatic" # automatic | manual | never
python-install-mirror = "https://github.com/astral-sh/python-build-standalone/releases/download"
```

```bash
# Per-invocation override
uv run --python 3.12 script.py
UV_PYTHON=3.11 uv sync
```

## Details

### python-preference

Determines which class of Python interpreter (managed vs. system) uv ranks first.

| Value | Behaviour |
|---|---|
| `managed` (default) | Prefer managed installs; fall back to system. Still prefers an already-present system interpreter over downloading a new managed one. |
| `only-managed` | Ignore system interpreters entirely. Equivalent to `--managed-python`. |
| `system` | Prefer system interpreters; managed installs are the fallback. |
| `only-system` | Ignore managed installs entirely. Equivalent to `--no-managed-python`. |

### python-downloads

Controls whether uv may fetch a managed Python distribution from the network.

| Value | Behaviour |
|---|---|
| `automatic` (default) | Download silently when no compatible interpreter is found. |
| `manual` | Downloads only permitted via `uv python install`; all other commands fail if no compatible interpreter is present. |
| `never` | Downloads are prohibited entirely; equivalent to passing `--no-python-downloads`. |

The `--no-python-downloads` CLI flag is a per-invocation shortcut for `python-downloads = "manual"`.

### python-install-mirror

Replaces the base URL `https://github.com/astral-sh/python-build-standalone/releases/download` when downloading CPython distributions. Use a `file://` URL to source distributions from a local directory (useful in air-gapped environments).

### UV_PYTHON_INSTALL_DIR

Environment variable that overrides the directory where uv stores managed Python installs (default: `~/.local/share/uv/python` on Linux/macOS). If you change this after creating virtual environments, those environments will continue to reference the old location and must be recreated.

### Discovery search order

When uv needs a Python interpreter, it searches in this order:

1. **Virtual environment in scope** — for `uv pip` commands: `VIRTUAL_ENV` env var, then `CONDA_PREFIX`, then a `.venv` directory walking up from the current directory.
2. **Project environment** — for project commands (`uv run`, `uv sync`, etc.): the path in `UV_PROJECT_ENVIRONMENT` (default `.venv` at the workspace root). Note: uv does not read `VIRTUAL_ENV` during project operations by default; pass `--active` to opt in.
3. **Managed installs** — entries in `UV_PYTHON_INSTALL_DIR`, newest version first.
4. **System PATH** — `python`, `python3`, or `python3.x` on macOS/Linux; `python.exe` on Windows; first compatible version wins (not the newest).
5. **Windows registry / Microsoft Store** — Windows only.

### --python / UV_PYTHON

Any command that accepts `--python` (or its env var equivalent `UV_PYTHON`) bypasses the above ranking and uses the specified interpreter directly. All [request formats](https://docs.astral.sh/uv/concepts/python-versions/#requesting-a-version) are accepted: bare version (`3.12`), specifier (`>=3.11`), implementation (`pypy`), or absolute path.

## Examples

```toml
# uv.toml — air-gapped CI: use only system Python, never download
python-preference = "only-system"
python-downloads  = "never"
```

```toml
# uv.toml — internal mirror for managed CPython downloads
python-install-mirror = "https://mirror.corp.example.com/python-build-standalone"
```

```bash
# Disable auto-downloads for a single command
uv sync --no-python-downloads

# Pin to a specific interpreter for this invocation only
uv run --python /opt/homebrew/bin/python3.12 script.py

# Use UV_PYTHON env var (e.g. in a CI matrix)
UV_PYTHON=3.11 uv pip install -r requirements.txt
```

```bash
# Relocate managed installs (set before first use)
export UV_PYTHON_INSTALL_DIR=/opt/uv/python
uv python install 3.12
```

## Caveats / Common Mistakes

- Changing `UV_PYTHON_INSTALL_DIR` after creating virtual environments does not migrate those environments; they must be recreated manually.
- `python-preference = "only-managed"` combined with `python-downloads = "never"` will fail on any machine that has not pre-installed the required version via `uv python install`.
- `VIRTUAL_ENV` is ignored by project commands (`uv run`, `uv sync`, etc.) unless `--active` is passed; only `uv pip` commands respect it automatically.
- If an absolute path is used for `UV_PROJECT_ENVIRONMENT` across multiple projects, each `uv sync` overwrites the same environment — only safe for single-project CI or Docker builds.

## See Also

- config-files
- python-versions
- python-discovery
- python-downloads-control
- config-project-env-settings
