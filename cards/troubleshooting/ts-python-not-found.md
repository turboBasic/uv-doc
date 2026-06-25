---
id: ts-python-not-found
title: Python interpreter not found or wrong interpreter selected
category: troubleshooting
tags: [troubleshooting, python, config, installation]
source: https://docs.astral.sh/uv/concepts/python-versions/
related: [python-discovery, python-downloads-control, config-python-discovery, config-python-version-file, python-install]
---

## Summary

uv fails to find a Python interpreter, picks an unexpected version, or reaches out to
download one you did not expect. The root cause is almost always one of: an active
virtual environment or `.python-version` file taking precedence, a `requires-python`
constraint filtering out available interpreters, a missing managed-install directory on
PATH, or the available-version list being stale because uv itself is outdated.

## Syntax / Usage

```bash
uv python find              # show which interpreter uv would use right now
uv python find --system     # skip venvs; show system/managed interpreter
uv python list              # list all installed and downloadable versions
uv python list --only-installed  # list only installed versions
uv python list 3.12         # filter by version
```

## Details

### Discovery order (highest priority first)

1. **Active virtual environment** — `VIRTUAL_ENV` env var (activated venv) or
   `CONDA_PREFIX` env var (activated Conda environment; pip interface only), then a
   `.venv` directory in the working directory or any parent. The venv's interpreter is
   checked for compatibility with the request before the search below runs.

2. **Managed Python installations** in `UV_PYTHON_INSTALL_DIR` — versions installed by
   `uv python install`. uv prefers the **newest compatible** managed version.

3. **System Python on PATH** — `python`, `python3`, or `python3.x` on macOS/Linux;
   `python.exe` on Windows. uv takes the **first compatible** match, not the newest.

4. **Windows registry and Microsoft Store** — Windows only; interpreters registered per
   PEP 514, visible via `py --list-paths`.

5. **Managed download** — if automatic downloads are enabled and nothing above matches,
   uv downloads a suitable managed Python version from the network.

### Why uv picked an unexpected interpreter

| Reason | Symptom | Fix |
|---|---|---|
| `VIRTUAL_ENV` set in shell | `uv python find` points inside a venv | `unset VIRTUAL_ENV` or use `--system` |
| `CONDA_PREFIX` set in shell | pip commands use Conda environment | deactivate Conda or use `--system` |
| `.python-version` file in a parent dir | uv uses a version you did not request | Check `cat .python-version`; remove or update the file |
| `requires-python` in `pyproject.toml` | uv skips compatible-looking interpreters | Tighten or widen `requires-python` to match what is installed |
| `python-preference = "managed"` default | Managed install overshadows a newer system Python | Set `python-preference = "system"` if you want system Python preferred |

### `.python-version` file interaction

uv searches the working directory and each parent for a `.python-version` file (stopping
at project/workspace boundaries), then falls back to the user configuration directory.
The file takes precedence over any installed version when selecting an interpreter.
Disable file discovery for a single command with `--no-config`.

### `requires-python` filtering

For project commands (`uv run`, `uv sync`), uv filters discovered interpreters by the
`requires-python` constraint in `pyproject.toml`. If the constraint is too narrow or too
broad, uv may skip locally installed interpreters that look correct to you.

### Disabling automatic downloads

By default uv downloads a managed Python when no local match is found. To prevent silent
network downloads, set `python-downloads = "manual"` in `uv.toml` or pass
`--no-python-downloads` on the command line.

```toml
# uv.toml
python-downloads = "manual"
```

With `"manual"`, downloads are only allowed via `uv python install`. With `"never"`,
downloads are blocked entirely including `uv python install`.

### Managed vs. system preference (`python-preference`)

| Value | Behavior |
|---|---|
| `managed` (default) | Prefer managed installs; fall back to system; download only as last resort |
| `only-managed` | Ignore system Python entirely (equivalent to `--managed-python`) |
| `system` | Prefer system Python; managed installs are the fallback |
| `only-system` | Ignore managed installs entirely (equivalent to `--no-managed-python`) |

### Available Python list is frozen per uv release

The list of downloadable managed Python versions is bundled with each uv release. If the
Python version you need is not shown by `uv python list`, upgrade uv first — the version
may have been added in a newer release.

### PATH missing `~/.local/bin`

On Unix, `uv python install` writes executables (e.g., `python3.12`) into `~/.local/bin`.
If that directory is not on your `PATH`, the executables are unreachable from the shell.
Fix it by running:

```bash
uv python update-shell
```

This updates your shell profile to include `~/.local/bin`.

## Examples

```bash
# Diagnose which interpreter would be used and why
uv python find
uv python find --system   # ignoring venvs

# List all installed versions; check which ones are actually present
uv python list --only-installed

# Temporarily bypass a .python-version file or project config
uv run --no-config python -V

# Stop uv from downloading Python silently
uv sync --no-python-downloads

# Persist that restriction in config
echo 'python-downloads = "manual"' >> uv.toml

# Force system Python only (ignore managed installs)
uv run --no-managed-python python -V

# Force managed Python only (ignore system Python)
uv venv --managed-python

# After uv python install, expose executables to the shell
uv python update-shell

# Upgrade uv to unlock newer downloadable Python versions
uv self update
```

## Caveats / Common Mistakes

- `uv python find` includes the active virtual environment by default. Always run
  `uv python find --system` when you want to know what is on the host system.
- pyenv-managed Pythons are treated as **system** Python by uv, not managed installs.
  `--managed-python` will not find them; `--no-managed-python` will.
- `python-preference` and `python-downloads` are independent settings. Setting
  `python-preference = "system"` does not prevent downloads — it only changes which
  installed interpreter is preferred. To block downloads, set `python-downloads`.
- uv prefers the **newest** managed version but the **first compatible** system version.
  Adding a newer system Python earlier on PATH will not override a managed install.
- If `UV_PYTHON_INSTALL_DIR` was changed after creating virtual environments, those
  environments reference the old path and must be recreated.
- The available Python list is **frozen per uv release**. If `uv python list` does not
  show the version you need, run `uv self update` before filing a bug.

## See Also

- python-discovery
- python-downloads-control
- config-python-discovery
- config-python-version-file
- python-install
