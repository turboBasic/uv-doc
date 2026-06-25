---
id: cmd-cache
title: uv cache — manage the uv cache
category: commands
tags: [command, cache, performance, ci]
source: https://docs.astral.sh/uv/concepts/cache/
related: [concept-cache, integration-github-actions, ts-cache-issues, config-env-vars, cmd-sync]
---

## Summary

`uv cache` provides subcommands to inspect, clean, and optimise uv's on-disk cache.
The cache stores downloaded wheels, source distributions, and built artifacts so subsequent
installs avoid redundant network requests and rebuilds.

## Syntax / Usage

```bash
uv cache <SUBCOMMAND> [OPTIONS]

uv cache clean [PACKAGE]...   # remove all entries, or only those for named packages
uv cache prune [--ci]         # remove unreachable entries (pre-built wheels in CI mode)
uv cache dir                  # print the resolved cache directory path
uv cache size [--human]       # print total cache disk usage
```

## Details

### Subcommands

**`uv cache clean [PACKAGE]...`**

Removes entries from the cache. With no arguments, clears the entire cache directory.
When one or more package names are given, only entries for those packages are removed.

**`uv cache prune`**

Removes all _unreachable_ cache entries — for example, entries created by a previous
version of uv that are no longer compatible with the current cache format. Safe to run
periodically as routine maintenance.

The `--ci` flag optimises for continuous integration: it removes all pre-built wheels and
unzipped source distributions but retains wheels that were _built from source_. Re-downloading
pre-built wheels each run is often faster than persisting them in a CI cache; built-from-source
wheels are worth keeping because compilation is expensive. Run `uv cache prune --ci` at the
end of a CI job to keep the persisted cache lean.

**`uv cache dir`**

Prints the resolved path of the cache directory. Useful for configuring CI cache actions or
diagnosing which directory uv is actually using.

**`uv cache size [--human]`**

Shows the total disk usage of the cache directory. By default outputs raw bytes; pass
`--human` (or `--human-readable` / `-H`) for a human-readable value such as `1.2 GiB`.

### Cache directory resolution

uv selects the cache directory in this order:

1. A temporary directory when `--no-cache` is passed (discarded on exit).
2. The value of `--cache-dir`, `UV_CACHE_DIR`, or `tool.uv.cache-dir` in config.
3. The platform default: `$XDG_CACHE_HOME/uv` or `~/.cache/uv` on Unix;
   `%LOCALAPPDATA%\uv\cache` on Windows.

For best performance, the cache directory should be on the same filesystem as the target
Python environment. Cross-filesystem installs fall back to slow copy operations instead of
hard links.

### Escape hatches for stale cache data

- `--refresh` (on any install/sync command) — revalidate cached data for all dependencies
  without clearing the cache.
- `--refresh-package <name>` — revalidate only the named package.

These are safer alternatives to `uv cache clean` when you want subsequent operations to
repopulate the cache rather than start cold.

### Concurrency and locking

The cache is thread-safe and append-only. Multiple uv processes can read and write
concurrently. Cache-modifying operations (`clean`, `prune`) wait for other uv processes
to release the cache lock before proceeding. The default timeout for this wait is **5 minutes**
and can be changed via `UV_LOCK_TIMEOUT`. Pass `--force` to skip the lock check when it is
known no other uv process is active.

### Cache versioning

The cache is divided into versioned buckets (wheels, source distributions, Git repos, etc.).
When a uv release changes the cache format for a bucket, the bucket version is incremented and
the old entries are ignored rather than misread. Multiple uv versions can safely share the
same cache directory, though they may maintain separate entries for incompatible bucket versions.

## Examples

```bash
# Remove the entire cache
uv cache clean

# Remove cached entries for a single package
uv cache clean ruff

# Remove unreachable/stale entries (routine maintenance)
uv cache prune

# CI: prune pre-built wheels before persisting the cache
uv cache prune --ci

# Check where the cache lives
uv cache dir

# Show cache size in human-readable form
uv cache size --human

# Revalidate all packages without clearing (safer than clean)
uv sync --refresh

# Revalidate one package only
uv pip install --refresh-package requests requests
```

GitHub Actions example — restore, install, then prune before saving:

```yaml
- name: Restore uv cache
  uses: actions/cache@v5
  with:
    path: /tmp/.uv-cache
    key: uv-${{ runner.os }}-${{ hashFiles('uv.lock') }}
    restore-keys: uv-${{ runner.os }}

- name: Install dependencies
  run: uv sync --locked
  env:
    UV_CACHE_DIR: /tmp/.uv-cache

- name: Minimize uv cache
  run: uv cache prune --ci
```

## Caveats / Common Mistakes

- **Directly modifying the cache is unsafe.** Deleting files or directories inside the cache
  manually can corrupt it. Always use `uv cache clean` or `uv cache prune`.
- **`--no-cache` does not skip caching entirely** — uv still uses a temporary cache for
  the duration of that single invocation. Use `--refresh` when you want the cache updated
  but not read from.
- **Symlink link mode creates cache coupling.** If `UV_LINK_MODE=symlink` is set, running
  `uv cache clean` will break installed packages because the symlink targets are removed.
  Use symlinks only when you are certain the cache will not be cleared while environments
  depend on it.
- **Lock timeout errors in CI.** If concurrent uv processes hit the 5-minute lock timeout
  you will see: `Timeout when waiting for lock on <CACHE_DIR>/.lock`. Increase
  `UV_LOCK_TIMEOUT` or serialise uv invocations.
- **Cross-filesystem cache.** If the cache is on a different filesystem than `.venv`, uv
  copies files instead of hard-linking, which is significantly slower. Place the cache on the
  same volume as the environment.

## See Also

- concept-cache
- ts-cache-issues
- integration-github-actions
- config-env-vars
- cmd-sync
