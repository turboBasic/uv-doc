---
id: python-downloads-control
title: Controlling automatic Python downloads
category: python
tags: [python, config, installation, troubleshooting]
source: https://docs.astral.sh/uv/concepts/python-versions/#disabling-automatic-python-downloads
related: [python-install, python-discovery, python-versions, config-python-discovery, integration-docker]
---

## Summary

By default uv downloads managed Python versions automatically whenever a requested version is not
found on the system. This behavior can be restricted or fully disabled via the `python-downloads`
setting, the `--no-python-downloads` flag, and the `UV_PYTHON_DOWNLOADS` environment variable —
which is critical for airgapped or policy-restricted environments.

## Syntax / Usage

```bash
# Disable automatic downloads for a single invocation
uv run --no-python-downloads python -V
uv sync --no-python-downloads

# Prefer or restrict managed vs. system Python for a single invocation
uv run --managed-python script.py      # only use managed Python
uv run --no-managed-python script.py   # only use system Python

# Set a default Python request via environment variable
UV_PYTHON=3.12 uv run python -V

# Disable all downloads via environment variable
UV_PYTHON_DOWNLOADS=0 uv sync
```

## Details

### `python-downloads` setting

The [`python-downloads`](https://docs.astral.sh/uv/reference/settings/#python-downloads) setting
controls whether uv may download managed Python installations. It accepts three values:

| Value | Behavior |
|---|---|
| `automatic` (default) | Download a managed Python when none is found locally |
| `manual` | Never download automatically; downloads only happen via `uv python install` |
| `never` | Never download Python under any circumstance, including `uv python install` |

Set it in `pyproject.toml` or `uv.toml`:

```toml
# pyproject.toml
[tool.uv]
python-downloads = "manual"
```

```toml
# uv.toml
python-downloads = "manual"
```

The setting can also be overridden per-invocation with `--no-python-downloads`, which is equivalent
to setting `python-downloads = "manual"` for that command only.

### `UV_PYTHON_DOWNLOADS` environment variable

`UV_PYTHON_DOWNLOADS=0` disables automatic downloads, equivalent to `python-downloads = "manual"`.
This is the recommended approach for Docker images that use a pre-installed system Python base image
and should never reach out to download an interpreter:

```dockerfile
ENV UV_PYTHON_DOWNLOADS=0
```

### `python-preference` setting

The [`python-preference`](https://docs.astral.sh/uv/reference/settings/#python-preference) setting
controls whether uv prefers managed or system Python when both are available. It is separate from
`python-downloads` and does not control whether downloads happen:

| Value | Behavior |
|---|---|
| `managed` (default) | Prefer managed installs over system installs; downloads if nothing satisfies request |
| `only-managed` | Only use managed installs; never use system Python |
| `system` | Prefer system installs over managed installs |
| `only-system` | Only use system installs; never use managed Python |

```toml
# uv.toml
python-preference = "system"
```

### `--managed-python` and `--no-managed-python` flags

These per-invocation flags are short-circuit equivalents to `python-preference`:

- `--managed-python` (`UV_MANAGED_PYTHON`): equivalent to `python-preference = "only-managed"`.
  uv will not fall back to system Python.
- `--no-managed-python` (`UV_NO_MANAGED_PYTHON`): equivalent to `python-preference = "only-system"`.
  uv will not use managed installs.

### `UV_PYTHON` environment variable

`UV_PYTHON` sets a default Python version request for all commands that accept `--python`. It is
overridden by an explicit `--python` flag and by `--python-version` in commands that have it.
Any [version request format](https://docs.astral.sh/uv/concepts/python-versions/#requesting-a-version)
is accepted (e.g. `UV_PYTHON=3.12`, `UV_PYTHON=cpython@3.11`, `UV_PYTHON=/usr/bin/python3`).

### Fully disabling downloads for airgapped environments

To prevent uv from ever reaching the network to download a Python interpreter:

1. Set `python-downloads = "never"` (or `"manual"`) in `uv.toml`, or
2. Set `UV_PYTHON_DOWNLOADS=0` in the environment.

The `"never"` value additionally blocks `uv python install`, while `"manual"` still permits
explicit installs via that command.

## Examples

```bash
# Persist download restriction in a project config
cat >> uv.toml <<'EOF'
python-downloads = "manual"
EOF

# Block downloads for a single command without changing config
uv sync --no-python-downloads

# Force uv to only consider system Python (ignore managed installs)
uv run --no-managed-python python -V

# Force uv to only consider managed installs (ignore system Python)
uv venv --managed-python

# Use a specific Python version as the default in the current shell
export UV_PYTHON=3.11
uv run python -V   # uses 3.11

# Dockerfile: use the base image's Python; never download
ENV UV_PYTHON_DOWNLOADS=0
RUN uv sync --locked
```

## Caveats / Common Mistakes

- `python-downloads` and `python-preference` are independent knobs. Setting
  `python-preference = "system"` does not prevent downloads — it only changes which installed
  interpreter is preferred. To block downloads, set `python-downloads = "manual"` or `"never"`.
- `--no-python-downloads` is equivalent to `python-downloads = "manual"`, not `"never"`. It still
  allows `uv python install` to download.
- `UV_PYTHON_DOWNLOADS=0` maps to `manual`, not `never`. `uv python install` can still run.
- `UV_PYTHON` sets a default *request*, not a hard constraint. If the requested version is not
  available and downloads are enabled, uv may still download to satisfy it.
- pyenv-managed Pythons are treated as system Python by uv. `--no-managed-python` will still find
  them; `--managed-python` will not.

## See Also

- python-install
- python-discovery
- python-versions
- config-python-discovery
- integration-docker
