---
id: concept-indexes
title: "Package indexes: PyPI, alternative indexes, and index priority"
category: concepts
tags: [index, resolution, config, authentication]
source: https://docs.astral.sh/uv/concepts/indexes/
related: [config-package-indexes, config-index-auth, dep-sources, concept-resolution, integration-private-indexes]
---

## Summary

uv resolves packages against one or more package indexes. PyPI is the built-in default;
additional indexes are declared via `[[tool.uv.index]]` and consulted in priority order,
with the default index always treated as lowest priority regardless of position.

## Details

### Default index

PyPI is the implicit default index. It is used when a package is not found on any other
configured index. To replace PyPI with a different default, set `default = true` on a
`[[tool.uv.index]]` entry (or use `--default-index` on the CLI). The default index is
always lowest priority — its position in the configuration list does not matter.

### Defining additional indexes

```toml
[[tool.uv.index]]
name = "pytorch"
url = "https://download.pytorch.org/whl/cpu"
```

Index names must be ASCII alphanumeric, dashes, underscores, or periods. The `name`
field is optional in the file but required when the index is referenced by
`tool.uv.sources`.

### Priority ordering

Indexes are consulted in declaration order: the first entry in `pyproject.toml` is
highest priority. CLI flags (`--index`) take precedence over file-level declarations.
The default index (PyPI or a `default = true` entry) is always consulted last.

### Index search strategy

The default strategy is `first-index`: uv stops at the first index that contains a
given package and uses only versions from that index. This prevents dependency-confusion
attacks. Alternative strategies are available via `--index-strategy` or
`UV_INDEX_STRATEGY`:

| Strategy | Behavior |
|---|---|
| `first-index` (default) | Use only versions from the first index that has the package |
| `unsafe-first-match` | Prefer the first index with a compatible version |
| `unsafe-best-match` | Pick the best version across all indexes (pip-like, unsafe) |

### Explicit indexes

Mark an index `explicit = true` to prevent it from serving packages that have not been
explicitly pinned to it via `tool.uv.sources`. All other packages still resolve from
non-explicit indexes.

### Pinning a package to an index

Use `tool.uv.sources` to route a specific package to a named index:

```toml
[tool.uv.sources]
torch = { index = "pytorch" }

[[tool.uv.index]]
name = "pytorch"
url = "https://download.pytorch.org/whl/cpu"
```

Named indexes referenced in `tool.uv.sources` must be declared in the project's own
`pyproject.toml`. Indexes from CLI flags, environment variables, or user-level config
are not recognized here.

### Flat indexes (find-links equivalent)

Flat indexes are local directories or HTML pages with a flat list of wheels/sdists —
the pip `--find-links` equivalent. Enable with `format = "flat"`:

```toml
[[tool.uv.index]]
name = "local-wheels"
url = "/path/to/directory"
format = "flat"
```

### Per-index `exclude-newer`

When using `exclude-newer` for reproducible resolutions, you can override the cutoff
for a specific index:

```toml
[[tool.uv.index]]
name = "internal"
url = "https://internal.example.com/simple"
exclude-newer = "7 days"
```

Set `exclude-newer = false` to disable the cutoff for an index that does not provide
upload-time metadata. Package-specific `exclude-newer-package` overrides take
precedence over index-level values.

### Authentication

Credentials can be supplied as:

- Per-index environment variables: `UV_INDEX_<NAME>_USERNAME` /
  `UV_INDEX_<NAME>_PASSWORD`, where `<NAME>` is the uppercase index name with
  non-alphanumeric characters replaced by underscores.
- Embedded in the URL: `https://user:pass@host/simple` (avoid for shared files).
- Via `netrc` or `keyring` credential providers.

The `authenticate` setting controls credential lookup behavior:

| Value | Behavior |
|---|---|
| (default) | Try unauthenticated first; search on failure |
| `always` | Eagerly search for credentials; error if not found |
| `never` | Never search; error if credentials are present |

Credentials are never stored in `uv.lock`.

### Legacy pip-style flags

`--index-url` and `--extra-index-url` are supported for pip compatibility.
`--index-url` maps to `--default-index`; `--extra-index-url` maps to `--index`.

## Examples

```toml
# pyproject.toml

# Replace PyPI with an internal registry as the default
[[tool.uv.index]]
name = "corp"
url = "https://pypi.corp.dev/simple"
default = true

# Add pytorch as an explicit extra index
[[tool.uv.index]]
name = "pytorch"
url = "https://download.pytorch.org/whl/cpu"
explicit = true

# Pin torch to the pytorch index; everything else resolves from corp
[tool.uv.sources]
torch = { index = "pytorch" }
```

```bash
# Provide an extra index on the CLI
uv lock --index pytorch=https://download.pytorch.org/whl/cpu

# Change the default index via CLI
uv sync --default-index https://pypi.corp.dev/simple

# Set indexes via environment variables
UV_INDEX=pytorch=https://download.pytorch.org/whl/cpu uv lock
UV_DEFAULT_INDEX=https://pypi.corp.dev/simple uv sync
```

```toml
# Per-platform index pinning with environment markers
[tool.uv.sources]
torch = [
  { index = "pytorch-cpu", marker = "sys_platform == 'darwin'" },
  { index = "pytorch-cu130", marker = "sys_platform != 'darwin'" },
]

[[tool.uv.index]]
name = "pytorch-cpu"
url = "https://download.pytorch.org/whl/cpu"

[[tool.uv.index]]
name = "pytorch-cu130"
url = "https://download.pytorch.org/whl/cu130"
```

## Caveats / Common Mistakes

- The default index is always lowest priority regardless of where it appears in the
  `[[tool.uv.index]]` list. Moving it higher does not increase its priority.
- Named indexes in `tool.uv.sources` must be declared in the project's own
  `pyproject.toml`. Indexes from CLI flags, environment variables, or user-level
  `uv.toml` are invisible to `tool.uv.sources` resolution.
- `unsafe-best-match` mirrors pip's behavior but exposes projects to dependency-
  confusion attacks; avoid it on projects that use private indexes.
- Some indexes (e.g., GitLab) forward unauthenticated requests to PyPI, causing uv
  to skip credential lookup. Use `authenticate = "always"` to force credential search
  for those indexes.
- When `first-index` strategy is active, uv stops searching if it receives HTTP 401 or
  403 from an index (except the `pytorch` index, which returns 403 for missing
  packages). Use `ignore-error-codes` to adjust per-index behavior.

## See Also

- config-package-indexes
- config-index-auth
- dep-sources
- concept-resolution
- integration-private-indexes
