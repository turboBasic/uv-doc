---
id: ts-cache-issues
title: "Cache problems: stale data, corruption, and disk/filesystem issues"
category: troubleshooting
tags: [troubleshooting, cache, performance, ci, config]
source: https://docs.astral.sh/uv/concepts/cache/
related: [concept-cache, cmd-cache, integration-github-actions, config-env-vars, ts-dynamic-metadata-cache]
---

## Summary

uv's cache is aggressive and append-only — most slowdowns or unexpected installs trace back to
stale entries, a cross-filesystem cache location, or a bucket-version mismatch after a uv upgrade.
This card covers the escape hatches for each symptom and the preferred fix for each scenario.

## Syntax / Usage

```bash
# Revalidate all cached data this run (writes updated entries back)
uv sync --refresh
uv pip install --refresh <package>

# Revalidate a single package only
uv sync --refresh-package <package>
uv pip install --refresh-package <package> <package>

# Wipe the entire cache
uv cache clean

# Wipe cached entries for one package
uv cache clean <package>

# Remove unused/stale entries (safe routine maintenance)
uv cache prune

# CI: evict pre-built wheels before saving the cached directory
uv cache prune --ci

# Disable the persistent cache for a single invocation
uv sync --no-cache
```

## Details

### Stale entries: flat indexes assume immutable filenames

For `--find-links` (flat index) sources, uv caches each file **by name only** and assumes the
contents are immutable. Replacing a wheel under the same filename will not be detected
automatically.

Fix: run `uv cache clean <package>` (or `uv cache clean` for the whole cache) after rebuilding
a wheel in a `--find-links` directory, then re-run the install command.

### Revalidating without a cold start: `--refresh` vs `--no-cache`

`--no-cache` creates a throw-away temporary cache for the duration of the invocation — it does
not update the persistent cache for subsequent runs.

`--refresh` revalidates cached data for all dependencies and writes the fresh results back to the
cache. Use `--refresh` when you want future invocations to benefit from the updated data.
Use `--refresh-package <name>` to target a single package.

`--no-cache` is appropriate only when you want a completely isolated, non-persistent run and do
not intend to repopulate the cache.

### Cache versioning: bucket mismatches after uv upgrades

uv partitions the cache into typed buckets (wheels, source distributions, Git repositories, core
metadata, etc.). Each bucket carries a version number. When a uv release contains a breaking
change to a bucket's format, the bucket version is incremented and uv ignores incompatible
entries rather than misreading them.

Multiple uv versions can safely share the same cache directory. However, entries created under an
old bucket version will be invisible to a newer uv, meaning the cache may be partially or fully
cold after an upgrade. Running `uv cache prune` after upgrading removes these now-unreachable
entries.

Example: uv 0.4.13 bumped the core metadata bucket from v12 to v13. After upgrading, uv 0.4.13
silently ignores v12 entries and fetches fresh metadata; `uv cache prune` cleans up the v12
entries.

### Filesystem mismatch: cross-filesystem cache causes slow copies

For optimal performance, the cache directory must reside on **the same filesystem** as the virtual
environment uv is operating on. When they are on different filesystems, uv cannot use hardlinks and
falls back to full file copies, which is significantly slower.

Symptoms: installs are unexpectedly slow even with a warm cache; no error is raised.

Fix: relocate the cache to the same filesystem as the target `.venv`, either via `--cache-dir`,
the `UV_CACHE_DIR` environment variable, or the `cache-dir` setting in `uv.toml` /
`pyproject.toml`.

```toml
# uv.toml — place cache next to the project's .venv
cache-dir = "./.uv_cache"
```

### CI caching: keeping the saved cache small with `uv cache prune --ci`

uv caches both pre-built (downloaded) wheels and wheels built from source. In CI:

- Pre-built wheels are usually **faster to re-download** than to restore from a remote cache store.
- Source-built wheels (extension modules) are expensive to compile and **worth persisting**.

`uv cache prune --ci` removes pre-built wheels and unzipped source distributions but retains
wheels built from source. Run it at the end of a CI job, just before the cache-save step, to keep
the persisted cache small and dominated by source-built artifacts.

## Examples

Refresh a single stale package without clearing the whole cache:

```bash
uv sync --refresh-package boto3
```

Full cache wipe for a package whose flat-index wheel was rebuilt:

```bash
uv cache clean my-internal-lib
uv pip install my-internal-lib
```

Locate the active cache directory (useful for confirming filesystem placement):

```bash
uv cache dir
```

Relocate the cache via environment variable (e.g., for a shared Docker layer):

```bash
UV_CACHE_DIR=/mnt/cache/uv uv sync
```

GitHub Actions — restore, install, prune before saving:

```yaml
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

Clean up a non-ephemeral self-hosted runner via a post-job hook script:

```sh
#!/usr/bin/env sh
uv cache clean
```

## Caveats / Common Mistakes

- **`--no-cache` still uses a temporary cache.** uv always needs a cache for within-invocation
  sharing. `--no-cache` only prevents reading from and writing to the persistent cache. Prefer
  `--refresh` when you want to update the cache for future runs.
- **Flat index contents are assumed immutable.** Rebuilding a wheel under the same filename in a
  `--find-links` directory will not be detected until the cache is explicitly cleared for that
  package.
- **Never modify the cache by hand.** Deleting files or directories directly inside the cache
  directory can corrupt it. Always use `uv cache clean` or `uv cache prune`.
- **Self-hosted CI runners can grow the cache unbounded.** With non-ephemeral runners the default
  cache directory accumulates entries across runs. Use `UV_CACHE_DIR` to point to a
  workspace-relative path and clean it via a post-job hook, or run `uv cache clean` at job end.
- **`uv cache prune` after a uv upgrade.** Old bucket entries are silently ignored, not removed.
  Run `uv cache prune` after upgrading uv to reclaim disk space occupied by now-unreachable
  entries.

## See Also

- concept-cache
- cmd-cache
- integration-github-actions
- config-env-vars
- ts-dynamic-metadata-cache
