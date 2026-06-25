---
id: ts-dynamic-metadata-cache
title: Editable installs and dynamic metadata not reflecting changes
category: troubleshooting
tags: [troubleshooting, cache, installation, build, project, config]
source: https://docs.astral.sh/uv/concepts/cache/#dynamic-metadata
related: [concept-cache, dep-editable, cmd-sync, integration-docker, cmd-cache]
---

## Summary

uv only rebuilds local directory dependencies (editable installs) when
`pyproject.toml`, `setup.py`, or `setup.cfg` changes, or when a `src` directory
is added or removed. If your build metadata is driven by other files, environment
variables, or Git state, you must extend the cache key — or force a reinstall.

## Syntax / Usage

```toml
# pyproject.toml — extend the cache key
[tool.uv]
cache-keys = [{ file = "pyproject.toml" }, { git = { commit = true } }]
```

```toml
# pyproject.toml — always force rebuild for this package
[tool.uv]
reinstall-package = ["my-package"]
```

```bash
# CLI — force reinstall of all packages for this run
uv sync --reinstall

# CLI — force reinstall of one package
uv sync --reinstall-package my-package

# CLI — install as non-editable (Docker multi-stage builds)
uv sync --locked --no-editable
```

## Details

### Default heuristic

By default, uv treats a local directory dependency as unchanged — and skips
rebuilding it — unless one of these conditions is true:

- `pyproject.toml`, `setup.py`, or `setup.cfg` in the directory root changed.
- A `src` directory was added or removed.

This is equivalent to the implicit default:

```toml
cache-keys = [
    { file = "pyproject.toml" },
    { file = "setup.py" },
    { file = "setup.cfg" },
    { dir = "src" },
]
```

### `tool.uv.cache-keys`

`cache-keys` replaces the default key list entirely, so always include the files
you still need (e.g. `pyproject.toml`) alongside any additions. Supported key
types:

| Key form | Invalidation trigger |
|---|---|
| `{ file = "path/or/glob" }` | File content changes (glob-aware) |
| `{ git = { commit = true } }` | Current HEAD commit SHA changes |
| `{ git = { commit = true, tags = true } }` | HEAD SHA or any tag pointer changes |
| `{ env = "VAR_NAME" }` | Environment variable value changes |
| `{ dir = "path" }` | Directory is created or removed (not contents) |

File globs follow the [`glob`](https://docs.rs/glob/0.3.1/glob/struct.Pattern.html)
crate syntax. Glob patterns can be expensive because uv may need to walk the
filesystem.

### `tool.uv.reinstall-package`

When no cache-key combination can capture the relevant change (e.g. metadata is
fully dynamic at build time), add the package name to `reinstall-package`. uv
will always rebuild and reinstall it, regardless of what changed. This implies
`refresh-package` for that package.

### `--reinstall` / `--reinstall-package`

Pass `--reinstall` to any installation command to force reinstallation of all
packages in that run. Pass `--reinstall-package <name>` to target a single
package. Both flags imply `--refresh` (cache revalidation) for the affected
packages.

### `--no-editable`

By default `uv sync` and `uv run` install the project and workspace members as
editable packages. `--no-editable` converts them to regular (non-editable)
installs, severing the dependency on source code at runtime. The env var
`UV_NO_EDITABLE=1` has the same effect.

## Examples

**`setuptools-scm` version derived from Git commit:**

```toml
[tool.uv]
cache-keys = [{ file = "pyproject.toml" }, { git = { commit = true } }]
```

**Dependencies read from `requirements.txt`:**

```toml
[tool.uv]
cache-keys = [{ file = "pyproject.toml" }, { file = "requirements.txt" }]
```

**Any `.toml` file in the tree triggers a rebuild:**

```toml
[tool.uv]
cache-keys = [{ file = "**/*.toml" }]
```

**Invalidate on an environment variable (e.g. deployment target):**

```toml
[tool.uv]
cache-keys = [{ file = "pyproject.toml" }, { env = "MACOSX_DEPLOYMENT_TARGET" }]
```

**Always rebuild a package whose metadata is fully runtime-dynamic:**

```toml
[tool.uv]
reinstall-package = ["my-package"]
```

**Docker multi-stage build — copy venv without source code:**

```dockerfile
FROM python:3.12-slim AS builder
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /app

RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --locked --no-install-project --no-editable

COPY . /app

RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked --no-editable

FROM python:3.12-slim
COPY --from=builder /app/.venv /app/.venv
CMD ["/app/.venv/bin/hello"]
```

## Caveats / Common Mistakes

- Setting `tool.uv.cache-keys` **replaces** the default key list; re-include
  `pyproject.toml` (or any other files you still rely on) or they will no longer
  trigger a rebuild.
- The `dir` key tracks only the presence/absence of the directory, not changes to
  files inside it. Use a `file` glob to watch directory contents.
- `tool.uv.reinstall-package` forces a rebuild on **every** run — use it only as
  a last resort when no static cache key can capture the invalidation signal.
- `--reinstall` implies `--refresh`, which revalidates remote registry metadata
  too; avoid it in locked/reproducible build contexts unless intentional.
- Packages passed explicitly on the command line (e.g. `uv pip install .`) are
  always rebuilt and reinstalled, bypassing the cache heuristic entirely.

## See Also

- concept-cache
- dep-editable
- cmd-sync
- integration-docker
- cmd-cache
