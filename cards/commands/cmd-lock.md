---
id: cmd-lock
title: uv lock — create or update the project lockfile
category: commands
tags: [command, project, lockfile, resolution]
source: https://docs.astral.sh/uv/reference/cli/#uv-lock
related: [concept-lockfile, project-sync-lock, cmd-sync, cmd-run, cmd-export]
---

## Summary

`uv lock` creates or updates `uv.lock`, the project's universal lockfile. It resolves all
dependencies across every platform and Python version the project supports, writing the result
to disk without installing anything.

## Syntax / Usage

```bash
uv lock [OPTIONS]
```

## Details

`uv lock` reads `pyproject.toml` and resolves the full dependency graph. The output is
`uv.lock`, a human-readable TOML file placed next to `pyproject.toml`. The lockfile is
cross-platform: it captures resolved versions for all possible OS, architecture, and Python
version combinations covered by the project's `requires-python` range, not just the current
machine.

**Existing locked versions as preferences.** When a `uv.lock` already exists, uv uses the
currently locked versions as preferences during resolution. Package versions only change if the
project's dependency constraints exclude the previous locked version. New upstream releases do
not trigger upgrades automatically.

**Staleness semantics.** uv considers the lockfile outdated when it no longer matches the
project metadata — for example, when a new dependency is added or a version constraint is
tightened such that the locked version is excluded. Relaxing a constraint that still includes
the locked version does not mark the lockfile as outdated.

**Automated locking.** `uv lock` does not need to be called manually for day-to-day work.
`uv run`, `uv sync`, and `uv tree` all re-lock automatically when the lockfile is stale. Use
`uv lock` explicitly when you want to pre-generate or update the lockfile without running or
syncing.

Key flags:

- `--check` — assert that the lockfile is up-to-date; exit with an error if it is missing or
  would change. Equivalent to `--locked` on other commands. Use in CI to verify the committed
  lockfile is current.
- `--check-exists` / `--frozen` — assert that a `uv.lock` file exists without checking whether
  it is up-to-date. Exits with an error only if the file is absent. Equivalent to `--frozen`
  on other commands.
- `--upgrade` / `-U` — ignore the previously locked versions for all packages and resolve to
  the latest versions permitted by the project's constraints. Implies `--refresh`.
- `--upgrade-package <pkg>` / `-P <pkg>` — upgrade a single package to the latest version
  permitted by its constraints, while keeping all other packages at their locked versions.
  Accepts a version specifier to pin to a specific version (e.g., `requests==2.32.0`).
- `--upgrade-group <group>` — upgrade all packages in a named dependency group.
- `--dry-run` — resolve and report changes without writing the lockfile to disk.
- `--script <path>` — lock a PEP 723 inline-metadata script rather than the current project.
  The lockfile is written adjacent to the script as `<script>.lock`.

## Examples

```bash
# Create or refresh the lockfile (no-op if already current)
uv lock

# CI: fail if the committed lockfile is stale
uv lock --check

# CI: skip staleness check, just ensure a lockfile exists
uv lock --check-exists

# Upgrade all packages to their latest allowed versions
uv lock --upgrade

# Upgrade only requests, keep everything else pinned
uv lock --upgrade-package requests

# Pin requests to an exact version, keep everything else pinned
uv lock --upgrade-package requests==2.32.0

# Preview what would change without writing to disk
uv lock --dry-run

# Lock a standalone script (writes script.py.lock beside the script)
uv lock --script script.py
```

## Caveats / Common Mistakes

- `uv lock` does **not** install anything. To update both the lockfile and the environment in
  one step, use `uv sync` (or pass `--upgrade` / `--upgrade-package` to `uv sync` or `uv run`).
- Upgrading is bounded by the project's dependency constraints. An upper bound in
  `pyproject.toml` will prevent `--upgrade` from going beyond that version.
- Git dependencies reference a specific commit SHA in the lockfile. The `--upgrade` /
  `--upgrade-package` flags are required to re-resolve to the latest commit on a branch.
- The lockfile format is uv-specific and cannot be consumed directly by other tools. Use
  `uv export` to produce a `requirements.txt` or `pylock.toml` for external tooling.

## See Also

- concept-lockfile
- project-sync-lock
- cmd-sync
- cmd-run
- cmd-export
