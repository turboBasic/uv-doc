---
id: ts-lockfile-errors
title: Lockfile staleness, --locked failures, and --frozen usage
category: troubleshooting
tags: [troubleshooting, lockfile, ci, resolution, dependency]
source: https://docs.astral.sh/uv/concepts/projects/sync/
related: [concept-lockfile, cmd-lock, cmd-sync, project-sync-lock, ts-resolution-conflict]
---

## Summary

`uv sync --locked` and `uv run --locked` fail with an error when the lockfile is out of
date with `pyproject.toml`. Understanding when uv considers a lockfile stale — and the
difference between `--locked`, `--frozen`, and `uv lock --check` — prevents spurious CI
failures and accidental environment drift.

## Syntax / Usage

```bash
uv lock --check                           # exit non-zero if lockfile needs updating
uv sync --locked                          # sync, error if lockfile would change
uv run --locked <cmd>                     # run cmd, error if lockfile would change
uv sync --frozen                          # sync using lockfile as-is, skip freshness check
uv run --frozen <cmd>                     # run cmd using lockfile as-is
uv lock --upgrade                         # re-resolve all packages to latest allowed
uv lock --upgrade-package <pkg>           # upgrade one package, keep others pinned
uv lock --upgrade-package <pkg>==<ver>    # pin one package to a specific version
```

## Details

### What makes a lockfile outdated

uv checks the lockfile against the current project metadata. The lockfile is considered
outdated when:

- A dependency is added, removed, or its version constraints change such that the
  previously locked version is **excluded** by the new constraint.
- The `pyproject.toml` changes in any way that affects resolution (e.g. `requires-python`
  is narrowed).

The lockfile is **not** considered outdated merely because a newer release of a locked
package has been published on PyPI. Locked versions persist until you explicitly upgrade
them — this is intentional, not a bug.

### --locked

`--locked` (env: `UV_LOCKED`) asserts that the lockfile is up-to-date. If the lockfile is
missing or would be changed by a fresh resolution, uv exits with an error instead of
updating it. This is the recommended flag for CI `uv sync` invocations: it catches
uncommitted lockfile changes before they cause environment drift.

`uv lock --check` is the standalone equivalent: it runs the check without performing a
sync, and exits non-zero if the lockfile needs updating.

### --frozen

`--frozen` (env: `UV_FROZEN`) skips the freshness check entirely and uses the lockfile
as the source of truth. If the lockfile is missing, uv exits with an error. If
`pyproject.toml` has dependency changes not yet reflected in the lockfile, those packages
will be absent from the environment — no warning is emitted. Use `--frozen` when you want
maximum speed and know the lockfile is already correct (e.g. after a `--locked` step has
already passed).

On `uv lock`, the equivalent flag is `--check-exists` (alias `--frozen`): it asserts that
a `uv.lock` exists without checking if it is up-to-date.

### Upgrading locked versions

Because locked versions do not change automatically, you must explicitly upgrade:

```bash
uv lock --upgrade                          # re-resolve everything within constraints
uv lock --upgrade-package requests         # re-resolve requests only
uv lock --upgrade-package "requests==2.32.3"  # pin requests to exactly 2.32.3
```

Upgrades are always bounded by the project's declared dependency constraints. An upper
bound in `pyproject.toml` will prevent an upgrade beyond that version.

`--upgrade` and `--upgrade-package` can also be passed directly to `uv sync` or `uv run`
to update the lockfile and environment in a single step.

### Malware check (preview)

During sync, uv can check locked packages against the OSV malware advisory database. If a
locked dependency matches a known malware advisory, the sync is terminated with an error.
Enable with `UV_MALWARE_CHECK=1`. This feature is in preview and subject to change.

## Examples

CI job that fails if the lockfile was not committed after a dependency change:

```bash
uv sync --locked
```

Fast Docker image build layer that skips freshness check after a prior `--locked` step:

```bash
# Stage 1: verify lockfile is committed
uv sync --locked --no-install-project

# Stage 2: install project on top of already-verified deps (frozen = no re-check)
uv sync --frozen
```

Upgrade a single transitive dependency to the latest version within constraints:

```bash
uv lock --upgrade-package httpx
```

Check lockfile freshness in CI without syncing:

```bash
uv lock --check
```

Enable malware scanning on sync:

```bash
UV_MALWARE_CHECK=1 uv sync
```

## Caveats / Common Mistakes

- **Newer release != stale lockfile.** If `requests 2.32.4` ships while your lockfile
  pins `2.32.3`, uv will not flag the lockfile as outdated. Run `uv lock --upgrade-package
  requests` explicitly when you want to pull in new releases.
- **--frozen silently ignores pyproject.toml changes.** If you add a dependency to
  `pyproject.toml` but run `uv sync --frozen`, the new package will not appear in the
  environment and no error is raised. Only use `--frozen` when lockfile correctness has
  already been verified.
- **Constraint tightening vs. exclusion.** Narrowing a constraint that still includes the
  currently locked version does not make the lockfile stale. Only a constraint change that
  *excludes* the locked version triggers a re-lock.
- **`uv lock --check` is the CI-safe way to assert freshness** without also performing
  environment sync; prefer it over `uv sync --locked` when you want to separate the check
  from the install step.

## See Also

- concept-lockfile
- cmd-lock
- cmd-sync
- project-sync-lock
- ts-resolution-conflict
