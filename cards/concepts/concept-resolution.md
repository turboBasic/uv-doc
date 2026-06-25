---
id: concept-resolution
title: "Dependency resolution: how uv resolves packages"
category: concepts
tags: [resolution, dependency, lockfile, config, performance]
source: https://docs.astral.sh/uv/concepts/resolution/
related: [concept-lockfile, concept-universal-resolution, config-resolution-settings, dep-overrides-constraints, ts-resolution-conflict]
---

## Summary

uv's resolver takes a set of requirements and finds package versions that satisfy all
constraints — including transitive dependencies — across every supported platform and
Python version. Understanding how it picks versions, handles pre-releases, and
reproduces resolutions is essential for predictable builds.

## Details

### Direct vs transitive dependencies

_Direct_ dependencies are those declared by the project itself (e.g., in
`project.dependencies`). _Transitive_ (indirect) dependencies are pulled in by direct
dependencies, and their dependencies in turn. The resolver must satisfy all of them
simultaneously.

### Resolution strategy

By default uv selects the **latest** compatible version of every package. Two
alternative strategies exist:

| Strategy | Behaviour |
|---|---|
| `latest` (default) | Highest compatible version for all packages |
| `lowest` | Lowest compatible version for all packages (direct and transitive) |
| `lowest-direct` | Lowest compatible version for direct deps; latest for transitive deps |

The strategy is set via `--resolution <strategy>` or `tool.uv.resolution` in
`pyproject.toml`/`uv.toml`. Build dependencies always use the latest version regardless
of strategy.

`lowest` and `lowest-direct` are primarily useful in CI to verify that declared lower
bounds are actually correct.

### Dependency preferences from existing lockfile / installed packages

If a `uv.lock` or `requirements.txt` output file already exists, uv _prefers_ the
versions recorded there. Likewise, if a package is already installed in the target
environment, uv prefers the installed version. Versions only change when a constraint
makes the current version incompatible, or when an explicit upgrade is requested with
`--upgrade` / `--upgrade-package`.

### Pre-release handling

Pre-release versions are accepted only in two cases:

1. A direct dependency's version specifier explicitly includes a pre-release marker
   (e.g., `flask>=2.0.0rc1`).
2. All published versions of a package are pre-releases.

If a transitive dependency requires a pre-release, uv errors and suggests
`--prerelease allow`. Alternatively, add the transitive package as a direct dependency
with an explicit pre-release specifier, which opts it in without opening pre-releases
globally.

### Lower bounds importance

`uv add` automatically adds lower bounds to every dependency it writes. When bounds are
absent the resolver may backtrack all the way to ancient package versions during
conflict resolution: those old versions often fail to build, or silently drop a
conflicting transitive dependency instead of reporting an error. For libraries in
particular, correct lower bounds are critical — validate them by running the test suite
with `--resolution lowest` or `--resolution lowest-direct` in CI.

### Reproducibility with `--exclude-newer`

`--exclude-newer <date-or-duration>` limits resolution to distributions uploaded before
a given timestamp (RFC 3339, e.g., `2024-01-15T00:00:00Z`) or a local date
(`2024-01-15`). Comparison is against the per-artifact upload time recorded by the
index (PyPI exposes this via PEP 700). If an index does not publish `upload-time`, those
distributions are treated as unavailable unless opted out.

The same option accepts a _duration_ (e.g., `"7 days"`, `"30 days"`, `"PT24H"`,
`"P30D"`), which implements a **dependency cooldown**: packages uploaded more recently
than the duration are ignored, giving the community time to vet new releases before they
enter your builds. Calendar units (months, years) are not allowed; a day is always
treated as 86 400 seconds.

Both the absolute timestamp and the cooldown duration can be set in `pyproject.toml`:

```toml
[tool.uv]
exclude-newer = "2024-01-15T00:00:00Z"   # absolute cutoff
# or
exclude-newer = "7 days"                  # rolling cooldown
```

Per-package overrides are available via `exclude-newer-package`:

```toml
[tool.uv]
exclude-newer = "7 days"
exclude-newer-package = { setuptools = "30 days", boto3 = false }
```

Setting a package to `false` opts it out of the restriction entirely, which is useful
for indexes that do not publish upload times.

Per-index overrides are also supported:

```toml
[[tool.uv.index]]
name = "internal"
url = "https://internal.example.com/simple"
exclude-newer = false
```

When using a lockfile with a cooldown, the resolved timestamp is stored in `uv.lock` and
is only updated when a new resolution is triggered (e.g., with `--upgrade`).

To disable a cutoff inherited from a lower-priority config, pass `--exclude-newer false`
or set `UV_EXCLUDE_NEWER=false`.

## Examples

```bash
# Default: install latest compatible versions
uv pip install flask>=2.0.0

# Resolve using lowest compatible versions (good for library CI)
uv pip compile requirements.in --resolution lowest -o requirements-lowest.txt

# Resolve using lowest for direct deps, latest for transitive
uv pip compile requirements.in --resolution lowest-direct -o requirements.txt

# Allow pre-release versions globally
uv pip install --prerelease allow flask

# Reproducible install: ignore packages uploaded after a specific date
uv pip install flask --exclude-newer 2024-01-15

# Apply a 7-day cooldown to all packages in the project
# pyproject.toml:
# [tool.uv]
# exclude-newer = "7 days"

# Upgrade everything despite the cooldown
uv lock --upgrade
```

## Caveats / Common Mistakes

- The default `latest` strategy does not verify lower bound correctness. A project may
  declare `flask>=2.0.0` but only ever test against Flask 3.x; `--resolution lowest`
  catches this.
- `--exclude-newer` compares against artifact _upload time_, not package release date.
  If an index does not provide `upload-time` (PEP 700), affected distributions are
  treated as unavailable — not silently included.
- When using a cooldown duration in a lockfile, the timestamp is not recalculated on
  every `uv sync`. It is recalculated only when a new resolution occurs (e.g., `uv lock
  --upgrade`), so the cooldown window is anchored to the last resolution, not the
  current time.
- Durations do not observe DST or calendar irregularities; a day is always 86 400 s.
- Setting `exclude-newer` in persistent config does not allow local datetimes — use UTC
  ISO 8601 (`Z` suffix or `+00:00`).

## See Also

- concept-lockfile
- concept-universal-resolution
- config-resolution-settings
- dep-overrides-constraints
- ts-resolution-conflict
