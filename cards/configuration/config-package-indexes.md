---
id: config-package-indexes
title: Package indexes — defining, prioritizing, and pinning
category: configuration
tags: [config, index, resolution, authentication]
source: https://docs.astral.sh/uv/concepts/indexes/
related: [dep-sources, config-index-auth, concept-indexes, config-resolution-settings, integration-private-indexes]
---

## Summary

`[[tool.uv.index]]` is the canonical way to configure package indexes in uv — replacing
the legacy `--index-url` / `--extra-index-url` pattern — with support for named indexes,
explicit pinning, flat (find-links) layouts, and a configurable multi-index search strategy.

## Syntax / Usage

```toml
# pyproject.toml
[[tool.uv.index]]
name = "pytorch"
url  = "https://download.pytorch.org/whl/cpu"

# uv.toml (no tool.uv prefix)
[[index]]
name = "pytorch"
url  = "https://download.pytorch.org/whl/cpu"
```

Command-line equivalents: `--index <url>`, `--default-index <url>`.

Environment variables: `UV_INDEX`, `UV_DEFAULT_INDEX`, `UV_INDEX_STRATEGY`.

## Details

### Defining and ordering indexes

Each `[[tool.uv.index]]` entry requires a `url` field; `name` is optional but required
for per-package pinning. Names must be ASCII and may only contain alphanumeric characters,
dashes, underscores, and periods.

Indexes are consulted in the order they appear in the file. Command-line `--index` flags
take precedence over file-level entries. The **default index** (PyPI by default) is always
lowest priority regardless of its position in the list.

### Default vs extra index

Exactly one index may be marked `default = true` — this replaces PyPI as the fallback.
All other entries are "extra" indexes searched before the default.

```toml
[[tool.uv.index]]
name = "internal"
url  = "https://pypi.internal.example.com/simple"
default = true
```

### Explicit indexes

Marking an index `explicit = true` prevents uv from sourcing any package from it unless
that package is explicitly pinned to it via `tool.uv.sources`. The index will still
remove PyPI as the default if `default = true` is also set.

```toml
[[tool.uv.index]]
name    = "pytorch"
url     = "https://download.pytorch.org/whl/cpu"
explicit = true
```

### Per-package index pinning

Use `tool.uv.sources` to bind a package to a named index. The named index must be
defined in the same `pyproject.toml`; user-level or CLI-provided index names are not
recognized here.

```toml
[tool.uv.sources]
torch = { index = "pytorch" }
```

Platform-conditional pinning is also supported via environment markers:

```toml
[tool.uv.sources]
torch = [
  { index = "pytorch-cpu", marker = "sys_platform == 'darwin'" },
  { index = "pytorch-gpu", marker = "sys_platform != 'darwin'" },
]
```

### Flat indexes (find-links replacement)

`format = "flat"` treats the URL as a flat directory or HTML page of wheels/sdists,
equivalent to pip's `--find-links`. All other `[[tool.uv.index]]` features apply
(explicit, per-package pinning, etc.).

```toml
[[tool.uv.index]]
name   = "local-wheels"
url    = "/path/to/wheel-dir"
format = "flat"
```

### Index search strategy

By default uv uses `first-index`: once a package is found on any index, only versions
from that index are considered. This guards against dependency-confusion attacks.
Override with `--index-strategy` or `UV_INDEX_STRATEGY`:

| Value | Behavior |
|---|---|
| `first-index` (default) | Limit candidates to the first index that has the package |
| `unsafe-first-match` | Prefer first index with a compatible version; ignore newer versions elsewhere |
| `unsafe-best-match` | Combine candidates from all indexes; select the best version (pip-like) |

### Legacy compatibility

`--index-url` and `--extra-index-url` (and their env vars `UV_INDEX_URL`,
`UV_EXTRA_INDEX_URL`) are supported for compatibility but deprecated. They behave
identically to unnamed `[[tool.uv.index]]` entries: `--index-url` maps to
`--default-index`, `--extra-index-url` maps to `--index`.

### Environment variables

| Variable | Equivalent |
|---|---|
| `UV_DEFAULT_INDEX` | `--default-index` (replaces deprecated `UV_INDEX_URL`) |
| `UV_INDEX` | space-separated `--index` list (replaces deprecated `UV_EXTRA_INDEX_URL`) |
| `UV_INDEX_STRATEGY` | `--index-strategy` |

Named indexes on the command line or via env vars use the `<name>=<url>` syntax:

```sh
UV_INDEX=pytorch=https://download.pytorch.org/whl/cpu uv lock
```

## Examples

**Private index as default, PyPI disabled:**

```toml
[[tool.uv.index]]
name    = "internal"
url     = "https://pypi.corp.example.com/simple"
default = true
```

**PyTorch from its own index, everything else from PyPI:**

```toml
[project]
dependencies = ["torch"]

[tool.uv.sources]
torch = { index = "pytorch" }

[[tool.uv.index]]
name     = "pytorch"
url      = "https://download.pytorch.org/whl/cpu"
explicit = true
```

**Local flat index alongside PyPI:**

```toml
[[tool.uv.index]]
name   = "local"
url    = "./dist"
format = "flat"
```

**Override index strategy for a CI run:**

```sh
UV_INDEX_STRATEGY=unsafe-best-match uv sync
```

## Caveats / Common Mistakes

- The default index is always lowest priority, even if listed first. There is no way
  to put the default index ahead of extra indexes.
- Named indexes referenced in `tool.uv.sources` must be defined in the project's own
  `pyproject.toml`. Indexes from CLI flags, env vars, or user/system config are not
  visible to `tool.uv.sources`.
- `unsafe-best-match` matches pip behavior but exposes the project to dependency
  confusion attacks where a maliciously named public package shadows an internal one.
- `UV_INDEX_URL` and `UV_EXTRA_INDEX_URL` are deprecated; prefer `UV_DEFAULT_INDEX`
  and `UV_INDEX`.
- Setting an index as both `default = true` and `explicit = true` is valid: PyPI is
  removed as default, and the index is only usable via `tool.uv.sources`.

## See Also

- dep-sources
- config-index-auth
- concept-indexes
- config-resolution-settings
- integration-private-indexes
