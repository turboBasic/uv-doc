---
id: config-pip-settings
title: "[tool.uv.pip] settings — pip-interface-only configuration"
category: configuration
tags: [config, pip, index, installation]
source: https://docs.astral.sh/uv/concepts/configuration-files/#configuring-the-pip-interface
related: [config-files, pip-install, pip-compile, pip-compatibility, config-package-indexes]
---

## Summary

The `[tool.uv.pip]` table holds settings that apply exclusively to `uv pip` subcommands.
Settings in this table are silently ignored by `uv sync`, `uv lock`, `uv run`, and all other
project-interface commands.

## Syntax / Usage

In `pyproject.toml`:

```toml
[tool.uv.pip]
index-url = "https://private.example.com/simple"
extra-index-url = ["https://download.pytorch.org/whl/cpu"]
find-links = ["/local/wheels"]
no-build-isolation = false
no-binary = ["numpy"]
only-binary = [":all:"]
strict = true
```

In `uv.toml` (drop the `tool.uv` prefix):

```toml
[pip]
index-url = "https://private.example.com/simple"
no-build-isolation = false
```

## Details

### Purpose and scope

`[tool.uv.pip]` is a dedicated sub-table designed to support pip-compatible workflows while
keeping the global `[tool.uv]` table free for the project interface. Any setting placed here
affects only commands in the `uv pip` namespace (`uv pip install`, `uv pip compile`,
`uv pip sync`, `uv pip uninstall`, etc.).

### Relationship to top-level `[tool.uv]` settings

Many `[tool.uv.pip]` settings have counterparts in the top-level `[tool.uv]` table. The
top-level value applies to both the project interface and the pip interface unless a value
is explicitly set in `[tool.uv.pip]`, in which case the `[tool.uv.pip]` value takes
precedence for pip commands. For example, if `[tool.uv]` sets an index and `[tool.uv.pip]`
also sets `index-url`, the pip interface uses the `[tool.uv.pip]` value.

The `[tool.uv.pip]` settings are intentionally designed to mirror pip's own CLI flags and
naming conventions, allowing for closer compatibility while letting the global settings use
uv-native designs (e.g., `[[tool.uv.index]]` vs `index-url`).

### Why `pip.conf` and `PIP_INDEX_URL` are not read

uv does not read `pip.conf`, `~/.pip/pip.conf`, or environment variables like
`PIP_INDEX_URL`. The reasons documented in the uv compatibility guide include: requiring
bug-for-bug compatibility with pip's config parser, being locked to pip's format evolution,
and potential user confusion. Instead, use `UV_INDEX_URL` (environment variable) or
`[tool.uv.pip].index-url` (persistent config).

### Key settings reference

| Setting | Type | Default | Description |
|---|---|---|---|
| `index-url` | `str` | `"https://pypi.org/simple"` | Base index URL (lower priority than `extra-index-url`) |
| `extra-index-url` | `list[str]` | `[]` | Additional indexes; earlier entries take priority over `index-url` |
| `find-links` | `list[str]` | `[]` | Local directories or HTML pages with flat package lists |
| `no-build-isolation` | `bool` | `false` | Disable PEP 518 build isolation; assumes build deps are pre-installed |
| `no-build-isolation-package` | `list[str]` | `[]` | Disable build isolation for specific packages only |
| `no-binary` | `list[str]` | `[]` | Force source builds; use `:all:` for all packages |
| `only-binary` | `list[str]` | `[]` | Refuse to build source distributions; use `:all:` for all packages |
| `no-build` | `bool` | `false` | Alias for `only-binary = [":all:"]` |
| `strict` | `bool` | `false` | Validate environment for missing dependencies after install |
| `index-strategy` | `str` | `"first-index"` | Multi-index resolution strategy |
| `prerelease` | `str` | `"if-necessary-or-explicit"` | Pre-release version acceptance policy |
| `require-hashes` | `bool` | `false` | Require hash verification for all packages |
| `system` | `bool` | `false` | Install into system Python instead of a virtual environment |
| `python` | `str` | `None` | Target Python executable or version |
| `upgrade` | `bool` | `false` | Allow upgrading already-installed packages |
| `compile-bytecode` | `bool` | `false` | Compile `.py` files to `.pyc` after installation |
| `resolution` | `str` | — | Resolution strategy (`highest`, `lowest`, `lowest-direct`) |

The full list of available `[pip]` settings is documented at
`https://docs.astral.sh/uv/reference/settings/#pip`.

## Examples

Redirect `uv pip` commands to a private index while leaving `uv sync` unchanged:

```toml
# pyproject.toml
[tool.uv.pip]
index-url = "https://private.corp.example/simple"
extra-index-url = ["https://pypi.org/simple"]
```

Legacy packages that require pre-installed build tools (e.g. some scientific packages):

```toml
[tool.uv.pip]
no-build-isolation-package = ["biopython", "numpy"]
```

Offline / air-gapped environment from a local wheel cache:

```toml
[tool.uv.pip]
find-links = ["/mnt/wheels"]
no-index = true
```

Equivalent `uv.toml` form (user-level config at `~/.config/uv/uv.toml`):

```toml
[pip]
index-url = "https://private.corp.example/simple"
strict = true
```

## Caveats / Common Mistakes

- Settings in `[tool.uv.pip]` have **no effect** on `uv sync`, `uv lock`, `uv run`, or
  `uv add`. If you expect a private index to be used during `uv sync`, configure it under
  `[[tool.uv.index]]` in the top-level table, not under `[tool.uv.pip]`.
- `PIP_INDEX_URL` and `pip.conf` are **not read** by uv. Migrate those values to
  `UV_INDEX_URL` (env var) or `[tool.uv.pip].index-url` (persistent config).
- `no-build-isolation = true` assumes PEP 518 build dependencies are already installed in
  the target environment; if they are not, builds will fail with obscure import errors.
- `no-binary` still allows the resolver to **read** metadata from pre-built wheels; it only
  prevents installation of binary wheels. `only-binary` prevents builds entirely (cached
  wheels are reused but new source builds exit with an error).
- User- and system-level config files must use `uv.toml` format with a `[pip]` table, not
  `pyproject.toml` format.

## See Also

- config-files
- pip-install
- pip-compile
- pip-compatibility
- config-package-indexes
