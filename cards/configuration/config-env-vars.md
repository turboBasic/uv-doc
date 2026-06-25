---
id: config-env-vars
title: UV_* environment variables reference
category: configuration
tags: [config, installation, index, authentication, cache, python]
source: https://docs.astral.sh/uv/reference/environment/
related: [config-files, config-index-auth, config-package-indexes, python-storage, concept-cache, config-installation]
---

## Summary

`UV_*` environment variables map to uv settings and override values in `pyproject.toml` or
`uv.toml`. They sit below CLI arguments in the precedence chain and above persistent config files.

## Details

Precedence order (highest to lowest):

1. Command-line arguments
2. Environment variables
3. Project config (`pyproject.toml` / `uv.toml`)
4. User config (`~/.config/uv/uv.toml`)
5. System config (`/etc/uv/uv.toml`)

Most `UV_*` variables correspond directly to a CLI flag or settings key. Boolean toggles accept `1`
or `true` to enable; set to `0`, `false`, or unset to disable.

### Storage-path variables

| Variable | Purpose | Default |
|---|---|---|
| `UV_CACHE_DIR` | Cache directory | `~/.cache/uv` (Linux/macOS) / `%LOCALAPPDATA%\uv\cache` (Windows) |
| `UV_PYTHON_INSTALL_DIR` | Directory for uv-managed Python installations | `~/.local/share/uv/python` |
| `UV_PYTHON_BIN_DIR` | Directory for Python executables (e.g., `python3.13`) | Platform executable dir |
| `UV_PYTHON_CACHE_DIR` | Cache directory for Python installation downloads | Subdirectory of cache |
| `UV_TOOL_DIR` | Directory for `uv tool install` environments | `~/.local/share/uv/tools` |
| `UV_TOOL_BIN_DIR` | Directory for tool executables (e.g., `ruff`) | `~/.local/bin` |
| `UV_INSTALL_DIR` | Install destination for the `uv` binary itself (installer only) | Platform executable dir |
| `UV_PROJECT_ENVIRONMENT` | Path of the project virtual environment (replaces `.venv`) | `.venv` in project/workspace root |

`UV_PYTHON_INSTALL_DIR` affects only new installations; existing virtual environments still point to
the old path and must be recreated manually.

`UV_PROJECT_ENVIRONMENT` accepts relative paths (resolved from the workspace root) or absolute
paths. When an absolute path is shared across multiple projects, each `uv sync` overwrites the
same environment — restrict to single-project CI or Docker use.

### Index variables

| Variable | Purpose | Values / format |
|---|---|---|
| `UV_INDEX` | Add an extra index (appended to `[[tool.uv.index]]`) | `<url>` or `<name>=<url>` |
| `UV_DEFAULT_INDEX` | Replace the default index (PyPI) | `<url>` or `<name>=<url>` |
| `UV_INDEX_STRATEGY` | How to search across multiple indexes | `first-index` (default), `unsafe-first-match`, `unsafe-best-match` |

`UV_INDEX` and `UV_DEFAULT_INDEX` accept the `<name>=<url>` syntax when a named reference is
needed, e.g. `UV_INDEX=pytorch=https://download.pytorch.org/whl/cpu`.

### Authentication variables

| Variable | Purpose | Notes |
|---|---|---|
| `UV_KEYRING_PROVIDER` | Enable keyring-based credential lookup | `disabled` (default) or `subprocess` |
| `UV_NO_HF_TOKEN` | Disable automatic Hugging Face authentication | Set to `1` to disable; uv propagates `HF_TOKEN` to `huggingface.co` requests by default |
| `UV_INDEX_<NAME>_USERNAME` | Username for the named index `<NAME>` | `<NAME>` is the index name uppercased with non-alphanumeric chars replaced by `_` |
| `UV_INDEX_<NAME>_PASSWORD` | Password / token for the named index `<NAME>` | Same naming convention as above |

### Behaviour toggles

| Variable | Purpose | Notes |
|---|---|---|
| `UV_PREVIEW` | Enable all preview features | Equivalent to `--preview` |
| `UV_PREVIEW_FEATURES` | Enable specific preview features | Comma-separated list, e.g. `UV_PREVIEW_FEATURES=native-auth,json-output` |
| `UV_NO_ENV_FILE` | Disable `.env` file loading in `uv run` | Set to `1` |
| `UV_ENV_FILE` | Path(s) to dotenv file(s) for `uv run` | Space-separated for multiple files, e.g. `UV_ENV_FILE="/a/.env /b/.env"` |
| `UV_EXCLUDE_NEWER` | Limit resolution to packages uploaded before a date | RFC 3339 timestamp (`2006-12-02T02:07:43Z`) or local date (`2006-12-02`); set to `false` to disable a lower-priority setting |
| `UV_LOCK_TIMEOUT` | Timeout (seconds) waiting for cache lock | Default is 5 minutes; used by `uv cache` commands |
| `UV_NO_MODIFY_PATH` | Prevent installer from modifying shell `PATH` profiles | Installer-only; also suppresses future `uv self update` path modifications |
| `UV_SYSTEM_CERTS` | Load TLS certificates from the OS native store | Default is bundled Mozilla roots; useful for corporate proxies |

`UV_PREVIEW` takes effect before configuration files are loaded; features listed in
`UV_PREVIEW_FEATURES` that don't exist emit a warning rather than an error.

### SSL / TLS variables

These are standard environment variable names (not `UV_`-prefixed) that uv respects:

| Variable | Purpose | Notes |
|---|---|---|
| `SSL_CERT_FILE` | Path to PEM-encoded certificate bundle (single file or multi-cert bundle) | Overrides bundled Mozilla roots entirely |
| `SSL_CERT_DIR` | Path(s) to directories containing PEM certificates | Multiple paths separated by `:` (Unix) or `;` (Windows) |
| `SSL_CLIENT_CERT` | Path to PEM file containing client certificate followed by private key | Used for mTLS / client certificate authentication |

When `SSL_CERT_FILE` or `SSL_CERT_DIR` is set, **only** the provided certificates are trusted —
the default Mozilla bundle is not merged in. DER-encoded files are not supported.

## Examples

```bash
# Use a custom cache directory
UV_CACHE_DIR=/mnt/shared/uv-cache uv sync

# Redirect the project venv to a named Docker layer path
UV_PROJECT_ENVIRONMENT=/app/.venv uv sync --frozen

# Add a secondary index for PyTorch without editing pyproject.toml
UV_INDEX=pytorch=https://download.pytorch.org/whl/cpu uv lock

# Replace the default index
UV_DEFAULT_INDEX=https://my-mirror.example.com/simple uv pip install requests

# Use first-index strategy (default) explicitly; switch to unsafe-best-match
UV_INDEX_STRATEGY=unsafe-best-match uv lock

# Provide credentials for an index named "internal-proxy"
export UV_INDEX_INTERNAL_PROXY_USERNAME=ci-user
export UV_INDEX_INTERNAL_PROXY_PASSWORD=s3cr3t
uv sync

# Use subprocess keyring provider
UV_KEYRING_PROVIDER=subprocess uv sync

# Disable Hugging Face auto-auth
UV_NO_HF_TOKEN=1 uv run my_script.py

# Enable all preview features
UV_PREVIEW=1 uv run --preview-features foo script.py

# Enable specific preview features
UV_PREVIEW_FEATURES=native-auth,json-output uv sync

# Load a custom dotenv file in uv run
UV_ENV_FILE=.env.production uv run app.py

# Pin resolution to packages available before a specific date
UV_EXCLUDE_NEWER=2024-01-01 uv lock

# Install uv to a custom path (installer only)
curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="$HOME/.local/uv" sh

# Install uv without modifying shell profiles (CI)
curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh

# Use OS certificate store (e.g., corporate proxy with custom CA)
UV_SYSTEM_CERTS=1 uv sync

# Trust a custom CA bundle
SSL_CERT_FILE=/etc/ssl/corporate-ca.pem uv sync

# Use client certificate for mTLS
SSL_CLIENT_CERT=/etc/ssl/client.pem uv sync

# Cache Python installation downloads (useful in Docker with BuildKit cache mounts)
ENV UV_PYTHON_CACHE_DIR=/root/.cache/uv/python
```

## Caveats / Common Mistakes

- `UV_INSTALL_DIR` only controls where the `uv` binary is placed by the installer script. It has no
  effect on cache, Python installations, or tool directories — those have their own variables.
- `UV_NO_MODIFY_PATH` is an installer-level flag. Setting it after installation has no effect on
  shell profiles that have already been modified.
- When `SSL_CERT_FILE` or `SSL_CERT_DIR` is set, the Mozilla bundle is entirely replaced. If the
  custom store is incomplete, connections to PyPI and other indexes may fail.
- `UV_PROJECT_ENVIRONMENT` set to an absolute path shared across multiple projects will cause each
  `uv sync` to overwrite the environment; only safe for single-project use.
- Multiple dotenv files in `UV_ENV_FILE` must be space-separated; later files override earlier ones
  for duplicate keys.
- Setting `UV_EXCLUDE_NEWER=false` in a higher-priority config (or via env var) disables a cutoff
  set at a lower priority level — this is the intended escape hatch.

## See Also

- config-files
- config-index-auth
- config-package-indexes
- python-storage
- concept-cache
- config-installation
