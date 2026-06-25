---
id: concept-cache
title: The global cache: caching model, invalidation, and maintenance
category: concepts
tags: [cache, performance, ci, config]
source: https://docs.astral.sh/uv/concepts/cache/
related: [cmd-cache, ts-cache-issues, ts-dynamic-metadata-cache, integration-github-actions, config-env-vars]
---

## Summary

uv maintains a global, append-only disk cache shared across all projects and environments. It caches
downloaded wheels, built wheels, source distributions, and Git repositories to avoid redundant
network and build work. Cache semantics vary by dependency type; for local directory dependencies,
custom cache keys can be configured via `tool.uv.cache-keys`.

## Details

### Cache location

uv resolves the cache directory in this order:

1. A temporary directory when `--no-cache` is passed (a temp cache is still used within that invocation).
2. The path from `--cache-dir`, the `UV_CACHE_DIR` environment variable, or `tool.uv.cache-dir` in `uv.toml` / `pyproject.toml`.
3. A platform-appropriate default:
   - Unix: `$XDG_CACHE_HOME/uv` or `~/.cache/uv`
   - Windows: `%LOCALAPPDATA%\uv\cache`

Run `uv cache dir` to print the active cache path.

For best performance, the cache directory must reside on the same filesystem as the virtual
environments uv operates on. Cross-filesystem access falls back to slow copy operations instead of
hardlinks.

### Caching semantics per dependency type

| Dependency type | Cache key |
|---|---|
| Registry (PyPI, etc.) | HTTP caching headers (`ETag`, `Last-Modified`) |
| Direct URL | HTTP caching headers + the URL itself |
| Git | Fully-resolved commit hash |
| Local archive (`.whl`, `.tar.gz`) | Last-modified time of the file |
| Local directory | Last-modified time of `pyproject.toml`, `setup.py`, or `setup.cfg`; presence/absence of `src/` |
| Flat index (`--find-links`) | Filename only (contents assumed immutable) |

### Dynamic metadata cache keys (`tool.uv.cache-keys`)

The default heuristic for local directory dependencies (watch `pyproject.toml` et al.) is not
sufficient for projects that compute metadata dynamically — for example, using `setuptools-scm` to
derive the version from Git, or reading dependencies from a `requirements.txt`. The
`tool.uv.cache-keys` setting replaces the default heuristic with an explicit list of cache key
components.

Supported key types:

- `{ file = "<path>" }` — invalidate when the file's content changes; supports glob patterns.
- `{ git = { commit = true } }` — invalidate when the HEAD commit changes.
- `{ git = { commit = true, tags = true } }` — also invalidate when Git tags change.
- `{ env = "<VAR>" }` — invalidate when the environment variable's value changes.
- `{ dir = "<path>" }` — invalidate when the directory is created or removed (not on contents changes).

Setting `cache-keys` replaces the defaults entirely, so include `{ file = "pyproject.toml" }` in
the list if that file is still relevant.

As an escape hatch when dynamic metadata cannot be expressed with cache keys, add the package to
`tool.uv.reinstall-package` to force a rebuild on every run regardless of cache state.

### Cache safety and concurrency

The cache is designed to be thread-safe and append-only. Multiple uv processes can read and write
the cache concurrently. uv uses a file-based lock on the target virtual environment when installing
to prevent concurrent environment modifications. Direct manual modifications to the cache (removing
files or directories by hand) are never safe.

### Cache versioning

The cache is divided into typed buckets (wheels, source distributions, Git repos, core metadata,
etc.). Each bucket carries a version number. When a uv release changes a bucket's format, the
version is incremented and uv will not read from or write to incompatible entries. Multiple uv
versions can safely share the same cache directory; they may produce duplicate entries in buckets
where the version changed, but will not corrupt each other.

### Clearing and pruning

| Command | Effect |
|---|---|
| `uv cache clean` | Remove all entries from the cache directory |
| `uv cache clean <package>` | Remove all entries for a specific package |
| `uv cache prune` | Remove unused entries (e.g., from older uv versions) — safe to run periodically |
| `uv cache prune --ci` | Remove pre-built wheels and unzipped source distributions; retain source-built wheels |

Cache-modifying commands block while other uv processes are running. The default wait timeout is
5 minutes, configurable with `UV_LOCK_TIMEOUT`. Pass `--force` to skip the lock when no other uv
processes are active.

### Per-operation cache control flags

- `--refresh` — revalidate cached data for all dependencies in this invocation.
- `--refresh-package <name>` — revalidate cached data for a specific package.
- `--reinstall` — ignore installed versions and reinstall; combine with `uv cache clean <name>` to
  ensure a fully clean reinstall.
- `--no-cache` — use a temporary cache for this invocation only; `--refresh` is usually preferable.

### CI caching strategy

uv caches both pre-built (downloaded) wheels and source-built wheels. In CI, pre-built wheels are
often faster to re-download than to restore from a remote cache; source-built wheels (extension
modules) are expensive and worth caching. The recommended pattern is:

1. Restore the cache at the start of the job, keyed on `uv.lock`.
2. Run the workflow normally.
3. Run `uv cache prune --ci` at the end to evict pre-built wheels before saving, keeping the saved
   cache small and dominated by source-built artifacts.

## Examples

```toml
# pyproject.toml — setuptools-scm project: rebuild when pyproject.toml or commit changes
[tool.uv]
cache-keys = [{ file = "pyproject.toml" }, { git = { commit = true } }]
```

```toml
# pyproject.toml — additional deps from requirements.txt
[tool.uv]
cache-keys = [{ file = "pyproject.toml" }, { file = "requirements.txt" }]
```

```toml
# pyproject.toml — glob: invalidate on any .toml change in the tree
[tool.uv]
cache-keys = [{ file = "**/*.toml" }]
```

```toml
# pyproject.toml — environment variable affects build output
[tool.uv]
cache-keys = [{ file = "pyproject.toml" }, { env = "MACOSX_DEPLOYMENT_TARGET" }]
```

```toml
# pyproject.toml — force unconditional rebuild (escape hatch)
[tool.uv]
reinstall-package = ["my-package"]
```

```bash
# Show the active cache directory
uv cache dir

# Force revalidation of all packages this run
uv sync --refresh

# Revalidate one package
uv sync --refresh-package requests

# Wipe the entire cache
uv cache clean

# Remove only ruff's cache entries
uv cache clean ruff

# Remove stale/unused entries (safe periodic maintenance)
uv cache prune

# CI: evict pre-built wheels before saving the cache
uv cache prune --ci
```

```yaml
# GitHub Actions: manual cache with uv.lock as key
jobs:
  install_job:
    env:
      UV_CACHE_DIR: /tmp/.uv-cache
    steps:
      - name: Restore uv cache
        uses: actions/cache@v5
        with:
          path: /tmp/.uv-cache
          key: uv-${{ runner.os }}-${{ hashFiles('uv.lock') }}
          restore-keys: |
            uv-${{ runner.os }}-${{ hashFiles('uv.lock') }}
            uv-${{ runner.os }}

      - name: Install project
        run: uv sync --locked

      - name: Minimize uv cache
        run: uv cache prune --ci
```

## Caveats / Common Mistakes

- **Flat index contents assumed immutable.** Replacing a wheel file in a `--find-links` directory
  under the same filename will not be detected. Run `uv cache clean` to force re-fetch.
- **`tool.uv.cache-keys` replaces defaults.** Omitting `{ file = "pyproject.toml" }` from a custom
  `cache-keys` list means changes to `pyproject.toml` will no longer trigger a rebuild.
- **`--no-cache` still uses a temporary cache.** It prevents reading from the persistent cache, but
  uv always needs some cache for within-invocation sharing. Use `--refresh` when you want to
  update the cache for future runs.
- **Cross-filesystem cache.** Placing the cache on a different filesystem (e.g., a network share or
  a different partition) disables hardlinking and slows installation significantly. Keep the cache
  on the same filesystem as `.venv`.
- **Never modify the cache by hand.** Removing files or directories from the cache directory
  directly can corrupt it. Use `uv cache clean` or `uv cache prune` instead.
- **Self-hosted CI runners with non-ephemeral caches.** The cache can grow unbounded. Either run
  `uv cache clean` after each job or set `UV_CACHE_DIR` to a workspace-relative path that is
  cleaned up via a post-job hook.
- **Glob traversal cost.** Using `{ file = "**/*.toml" }` in `cache-keys` causes uv to walk the
  filesystem on every run; avoid broad globs in large or deeply nested trees.

## See Also

- cmd-cache
- ts-cache-issues
- ts-dynamic-metadata-cache
- integration-github-actions
- config-env-vars
