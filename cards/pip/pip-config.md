---
id: pip-config
title: "[tool.uv.pip] — persistent configuration for the pip interface"
category: pip
tags: [pip, config, index, installation, resolution]
source: https://docs.astral.sh/uv/reference/settings/#pip
related: [config-pip-settings, pip-install, pip-compile, pip-compatibility, config-files]
---

## Summary

`[tool.uv.pip]` (in `pyproject.toml`) or `[pip]` (in `uv.toml`) is the dedicated
configuration sub-table for the `uv pip` command namespace. Every setting placed here
applies **only** to `uv pip` subcommands and is silently ignored by the project interface
(`uv sync`, `uv lock`, `uv run`, `uv add`).

## Syntax / Usage

```toml
# pyproject.toml
[tool.uv.pip]
index-url = "https://private.example.com/simple"
extra-index-url = ["https://pypi.org/simple"]
no-binary = ["numpy"]
compile-bytecode = true
```

```toml
# uv.toml — identical settings but without the [tool.uv] prefix
[pip]
index-url = "https://private.example.com/simple"
compile-bytecode = true
```

## Details

### Scope

Settings in `[tool.uv.pip]` are read for `uv pip install`, `uv pip compile`,
`uv pip sync`, `uv pip uninstall`, and all other `uv pip *` commands. They are not
read by `uv sync`, `uv lock`, `uv run`, `uv add`, or `uvx`.

### Relationship to `[tool.uv]`

Top-level `[tool.uv]` settings that have pip-interface equivalents apply to both
interfaces unless `[tool.uv.pip]` also sets that value, in which case the `[tool.uv.pip]`
value takes precedence for pip commands. This allows pip-specific index routing or
resolution policies while keeping the project interface unchanged.

The `[tool.uv.pip]` naming intentionally mirrors pip CLI flags (e.g., `index-url`,
`extra-index-url`) to ease migration, while the global `[tool.uv]` table uses uv-native
designs (e.g., `[[tool.uv.index]]`).

### Configuration precedence

Within the pip interface, precedence is (highest to lowest):

1. CLI flags (e.g., `--index-url`)
2. Environment variables (e.g., `UV_INDEX_URL`)
3. `[tool.uv.pip]` / `[pip]` in the nearest project config
4. User-level `~/.config/uv/uv.toml` `[pip]` table
5. System-level `/etc/uv/uv.toml` `[pip]` table

### Why `pip.conf` and `PIP_INDEX_URL` are not read

uv does not read `pip.conf` or `PIP_INDEX_URL`. Instead, use `UV_INDEX_URL` as the
equivalent environment variable, or `[tool.uv.pip].index-url` for persistent config.

### Full settings reference

**Index / source settings**

| Setting | Type | Default | Description |
|---|---|---|---|
| `index-url` | `str` | `"https://pypi.org/simple"` | Base index (lowest priority) |
| `extra-index-url` | `list[str]` | `[]` | Additional indexes; earlier entries take priority |
| `find-links` | `list[str]` | `[]` | Local dirs or flat HTML pages with wheel/sdist files |
| `index-strategy` | `str` | `"first-index"` | `first-index`, `unsafe-first-match`, `unsafe-best-match` |
| `no-index` | `bool` | `false` | Ignore all registry indexes; use only `find-links` |
| `keyring-provider` | `str` | `"disabled"` | Keyring auth; only `"subprocess"` is supported |

**Build settings**

| Setting | Type | Default | Description |
|---|---|---|---|
| `no-build` | `bool` | `false` | Alias for `only-binary = [":all:"]` |
| `no-build-isolation` | `bool` | `false` | Disable PEP 518 build isolation globally |
| `no-build-isolation-package` | `list[str]` | `[]` | Disable build isolation for specific packages |
| `no-binary` | `list[str]` | `[]` | Force source builds; `:all:` for all packages |
| `only-binary` | `list[str]` | `[]` | Refuse source builds; `:all:` for all packages |
| `config-settings` | `dict` | `{}` | PEP 517 build-backend `KEY=VALUE` pairs |
| `config-settings-package` | `dict` | `{}` | Per-package PEP 517 build settings |
| `extra-build-dependencies` | `dict` | `{}` | Extra packages injected into build environments |
| `extra-build-variables` | `dict` | `{}` | Extra env vars set when building specific packages |

**Python / environment settings**

| Setting | Type | Default | Description |
|---|---|---|---|
| `python` | `str` | `None` | Target interpreter (version string, binary name, or path) |
| `python-version` | `str` | `None` | Minimum Python version for resolution (e.g., `"3.8"`) |
| `python-platform` | `str` | `None` | Target platform triple for cross-platform resolution |
| `system` | `bool` | `false` | Install into the first Python on `PATH` instead of a venv |
| `break-system-packages` | `bool` | `false` | Allow modifying an `EXTERNALLY-MANAGED` Python |
| `target` | `str` | `None` | Install into this directory's top-level (like `pip --target`) |
| `prefix` | `str` | `None` | Install into `lib/`, `bin/` under this directory |
| `compile-bytecode` | `bool` | `false` | Compile `.py` to `.pyc` after installation |
| `link-mode` | `str` | platform default | `clone`, `copy`, `hardlink`, or `symlink` |

**Resolution settings**

| Setting | Type | Default | Description |
|---|---|---|---|
| `resolution` | `str` | `"highest"` | `highest`, `lowest`, `lowest-direct` |
| `prerelease` | `str` | `"if-necessary-or-explicit"` | Pre-release version acceptance policy |
| `fork-strategy` | `str` | `"requires-python"` | `requires-python` or `fewest` |
| `exclude-newer` | `str\|false` | `None` | Ignore packages uploaded after this timestamp |
| `exclude-newer-package` | `dict` | `None` | Per-package `exclude-newer` overrides |
| `upgrade` | `bool` | `false` | Ignore pinned versions in output files |
| `upgrade-package` | `list[str]` | `[]` | Allow upgrades for specific packages |
| `reinstall` | `bool` | `false` | Reinstall all packages regardless of install state |
| `reinstall-package` | `list[str]` | `[]` | Reinstall specific packages |
| `dependency-metadata` | `list[dict]` | `[]` | Static metadata to bypass registry/build queries |
| `no-sources` | `bool` | `false` | Ignore `tool.uv.sources` when resolving |
| `no-sources-package` | `list[str]` | `[]` | Ignore `tool.uv.sources` for specific packages |
| `no-deps` | `bool` | `false` | Ignore transitive deps; only add explicitly listed packages |

**Hash / verification settings**

| Setting | Type | Default | Description |
|---|---|---|---|
| `require-hashes` | `bool` | `false` | Require a matching hash for every requirement |
| `verify-hashes` | `bool` | `true` | Verify hashes for requirements that declare them |
| `generate-hashes` | `bool` | `false` | Emit distribution hashes in `uv pip compile` output |

**`uv pip compile`-specific output settings**

| Setting | Type | Default | Description |
|---|---|---|---|
| `output-file` | `str` | `None` | Path for `uv pip compile` output |
| `custom-compile-command` | `str` | `None` | Header comment showing the invoking command |
| `annotation-style` | `str` | `"split"` | `"line"` or `"split"` for source annotations |
| `no-annotate` | `bool` | `false` | Omit source annotation comments |
| `no-header` | `bool` | `false` | Omit the comment header |
| `emit-index-url` | `bool` | `false` | Include `--index-url` lines in output |
| `emit-find-links` | `bool` | `false` | Include `--find-links` lines in output |
| `emit-build-options` | `bool` | `false` | Include `--no-binary` / `--only-binary` in output |
| `emit-index-annotation` | `bool` | `false` | Comment each package with its source index |
| `emit-marker-expression` | `bool` | `false` | Emit a marker string for the resolution's validity |
| `no-strip-extras` | `bool` | `false` | Preserve extras in output (incompatible with constraints use) |
| `no-strip-markers` | `bool` | `false` | Preserve environment markers in output |
| `no-emit-package` | `list[str]` | `[]` | Omit specific packages from output (their deps are retained) |
| `universal` | `bool` | `false` | Universal resolution compatible with all platforms |

**Extras / groups**

| Setting | Type | Default | Description |
|---|---|---|---|
| `all-extras` | `bool` | `false` | Include all optional dependencies |
| `extra` | `list[str]` | `[]` | Include specific extras |
| `no-extra` | `list[str]` | `[]` | Exclude extras when `all-extras` is set |
| `group` | `list[str]` | `[]` | Include dependency groups |

**Validation**

| Setting | Type | Default | Description |
|---|---|---|---|
| `strict` | `bool` | `false` | Validate environment for missing dependencies after install |
| `allow-empty-requirements` | `bool` | `false` | Allow `uv pip sync` with an empty requirements set |

**Preview settings**

| Setting | Type | Default | Description |
|---|---|---|---|
| `torch-backend` | `str` | `null` | PyTorch index backend (`auto`, `cpu`, `cu126`, etc.) — preview |

## Examples

Redirect `uv pip` to a private index while the project interface uses the default:

```toml
# pyproject.toml
[tool.uv.pip]
index-url = "https://private.corp.example/simple"
extra-index-url = ["https://pypi.org/simple"]
```

Force source builds for a specific package and enable hash verification:

```toml
[tool.uv.pip]
no-binary = ["numpy"]
require-hashes = true
```

Compile bytecode and use offline wheels from a local cache:

```toml
[tool.uv.pip]
find-links = ["/mnt/local-wheels"]
no-index = true
compile-bytecode = true
```

Write `uv pip compile` output to a file and include index URLs for reproducibility:

```toml
[tool.uv.pip]
output-file = "requirements.txt"
emit-index-url = true
generate-hashes = true
```

User-level config in `~/.config/uv/uv.toml` (must use `uv.toml` format):

```toml
[pip]
index-url = "https://private.corp.example/simple"
strict = true
```

## Caveats / Common Mistakes

- Settings in `[tool.uv.pip]` have **no effect** on `uv sync`, `uv lock`, `uv run`, or
  `uv add`. A private index set here will not be used by `uv sync`; configure it under
  `[[tool.uv.index]]` in the top-level table instead.
- `PIP_INDEX_URL` and `pip.conf` are **not read** by uv. Migrate to `UV_INDEX_URL` or
  `[tool.uv.pip].index-url`.
- `no-strip-extras = true` in `[tool.uv.pip]` makes the compiled output unusable as a
  constraints file in `uv pip install -c`.
- User- and system-level configuration must use `uv.toml` with a `[pip]` table. The
  `pyproject.toml` format with `[tool.uv.pip]` is only valid at the project level.
- `uv.toml` takes precedence over `pyproject.toml` in the same directory; if both exist,
  the `[tool.uv.pip]` table in `pyproject.toml` is ignored.

## See Also

- config-pip-settings
- pip-install
- pip-compile
- pip-compatibility
- config-files
