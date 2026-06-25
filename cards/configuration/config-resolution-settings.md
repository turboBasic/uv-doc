---
id: config-resolution-settings
title: Resolution settings — strategy, pre-releases, constraints, and overrides
category: configuration
tags: [config, resolution, dependency, lockfile]
source: https://docs.astral.sh/uv/concepts/resolution/
related: [concept-resolution, dep-overrides-constraints, dep-platform-environments, cmd-lock, ts-resolution-conflict]
---

## Summary

uv exposes a set of `[tool.uv]` settings that control every aspect of how the resolver
picks package versions: the version selection strategy, pre-release handling, multi-version
forking, constraints and overrides, static dependency metadata, platform environment
filtering, and time-based reproducibility cutoffs.

## Syntax / Usage

```toml
# pyproject.toml — all keys live under [tool.uv]
[tool.uv]
resolution            = "highest" | "lowest" | "lowest-direct"
prerelease            = "if-necessary-or-explicit" | "allow" | "disallow" | "if-necessary" | "explicit"
fork-strategy         = "requires-python" | "fewest"
constraint-dependencies = ["pkg>=x,<y", ...]
override-dependencies   = ["pkg==pinned", ...]
environments          = ["sys_platform == 'linux'", ...]
required-environments = ["sys_platform == 'darwin' and platform_machine == 'arm64'", ...]
exclude-newer         = "2025-01-01T00:00:00Z"  # or a duration: "7 days"
exclude-newer-package = { setuptools = "30 days", mypackage = false }

[[tool.uv.dependency-metadata]]
name = "some-package"
version = "1.2.3"
requires-dist = ["dep-a>=1.0"]
```

Corresponding environment variables: `UV_RESOLUTION`, `UV_PRERELEASE`, `UV_FORK_STRATEGY`,
`UV_EXCLUDE_NEWER`.

## Details

### Resolution strategy (`resolution`)

Controls which compatible version is selected when multiple satisfy the requirements.

| Value | Behaviour |
|---|---|
| `highest` (default) | Latest compatible version of every package |
| `lowest` | Lowest compatible version of every package (direct and transitive) |
| `lowest-direct` | Lowest compatible version of direct deps; latest for transitive deps |

Build dependencies always use the latest version regardless of this setting.

Use `lowest` or `lowest-direct` in CI to verify declared lower bounds are correct.

### Pre-release handling (`prerelease`)

| Value | Behaviour |
|---|---|
| `if-necessary-or-explicit` (default) | Accept pre-releases only when all published versions are pre-releases, or when the specifier explicitly includes a pre-release marker |
| `allow` | Accept pre-releases for all packages |
| `disallow` | Reject all pre-releases |
| `if-necessary` | Accept pre-releases only when all versions of a package are pre-releases |
| `explicit` | Accept pre-releases only when a first-party specifier includes an explicit pre-release marker |

When a transitive dependency triggers a pre-release requirement, uv will fail and suggest
`--prerelease allow`. The alternative is to add the transitive package as a direct
dependency or constraint with an explicit pre-release specifier.

### Fork strategy (`fork-strategy`)

During universal resolution, a package may appear with different versions for different
Python versions or platforms. `fork-strategy` controls the trade-off:

| Value | Behaviour |
|---|---|
| `requires-python` (default) | Select the latest version for each supported Python version; minimise forks across platforms |
| `fewest` | Minimise the total number of selected versions; older versions compatible with a wider range are preferred |

### Constraint dependencies (`constraint-dependencies`)

Narrows the acceptable version range for packages that are already pulled in elsewhere.
Adding a package as a constraint does not install it — the package must be required by
another dependency. Constraints are additive: the constraint is intersected with the
existing requirements.

```toml
[tool.uv]
constraint-dependencies = ["grpcio<1.65"]
```

`constraint-dependencies` is read only from the workspace root `pyproject.toml`; it is
ignored in member `pyproject.toml` files and in `uv.toml`.

### Override dependencies (`override-dependencies`)

Completely replaces all declared requirements for the named package, regardless of what any
dependency declares. Overrides can expand acceptable version ranges, making them useful when
an upstream package has an erroneous upper bound. Like constraints, overrides do not cause
installation of the package on their own.

```toml
[tool.uv]
override-dependencies = ["werkzeug==2.3.0"]
```

`override-dependencies` is read only from the workspace root `pyproject.toml`; it is
ignored in member `pyproject.toml` files and in `uv.toml`.

Multiple overrides for the same package must be differentiated with environment markers.

### Dependency metadata (`dependency-metadata`)

Provides static metadata for packages that lack it (e.g., source-only distributions that
require a build to expose metadata). uv uses these declarations instead of building the
package during resolution.

Recognised fields: `name`, `version` (optional for registry packages, required for direct
URL deps), `requires-dist`, `requires-python`, `provides-extra`. All other fields are
ignored.

### Environment filtering (`environments` and `required-environments`)

Both settings accept lists of PEP 508 environment marker expressions. They have opposite
effects:

- **`environments`** — limits the set of platforms uv resolves for. Useful for pruning
  unsatisfiable branches (e.g., ignoring Windows in a Linux-only project). Entries must be
  disjoint.
- **`required-environments`** — expands the set of platforms whose wheels must be present.
  Resolution fails if a wheel-only package has no distribution for a required environment.
  Useful when targeting non-latest platforms (e.g., Intel macOS) that require backtracking.

Both settings are also respected by `uv pip compile --universal`.

### Reproducible resolutions (`exclude-newer` / `exclude-newer-package`)

`exclude-newer` limits candidates to distributions uploaded before a given point in time.
The cutoff is compared against each artifact's `upload-time` field (PEP 700), not the
package release date. PyPI provides `upload-time` for all packages; custom indexes may not.

Accepts:
- RFC 3339 timestamp: `"2025-01-01T00:00:00Z"`
- Local date (in config only): `"2025-01-01"` — interpreted in the system time zone
- Friendly duration: `"7 days"`, `"30 days"`, `"24 hours"` (cooldown mode)
- ISO 8601 duration: `"P7D"`, `"PT24H"`

When a duration is used, the effective cutoff timestamp is stored in `uv.lock` and is only
updated when a new resolution is triggered (e.g., via `--upgrade` or `--refresh`).

Calendar units (months, years) are not allowed. DST transitions are ignored.

`exclude-newer-package` applies a per-package cutoff or exemption:
- `{ setuptools = "30 days" }` — cooldown for setuptools only
- `{ mylib = false }` — opt mylib out of the global `exclude-newer` cutoff

Package-specific values take precedence over global and index-level values. An index can
also override or disable the global cutoff:

```toml
[[tool.uv.index]]
name = "internal"
url  = "https://internal.example.com/simple"
exclude-newer = false   # index doesn't publish upload-time
```

To disable a global `exclude-newer` from a lower-priority config, set
`exclude-newer = false`, `UV_EXCLUDE_NEWER=false`, or pass `--exclude-newer false`.

## Examples

```toml
# pyproject.toml — test lower bounds in CI, pin pre-releases where needed
[tool.uv]
resolution = "lowest-direct"
prerelease = "if-necessary-or-explicit"
constraint-dependencies = ["grpcio<1.65"]
override-dependencies   = ["pydantic>=1.0,<3"]

# Solve only for Linux and macOS, not Windows
environments = [
    "sys_platform == 'linux'",
    "sys_platform == 'darwin'",
]

# Freeze resolution to packages published before this date
exclude-newer = "2025-06-01T00:00:00Z"
```

```toml
# Dependency cooldown — ignore packages newer than 7 days
[tool.uv]
exclude-newer = "7 days"
exclude-newer-package = { boto3 = "30 days", setuptools = false }
```

```toml
# Provide static metadata for a package that has no sdist and requires torch to build
[[tool.uv.dependency-metadata]]
name          = "flash-attn"
version       = "2.6.3"
requires-dist = ["torch", "einops"]
```

```bash
# CLI equivalents (override config for one-off runs)
uv lock --resolution lowest-direct
uv pip compile --prerelease allow requirements.in
uv lock --exclude-newer 2025-06-01T00:00:00Z

# Env var equivalents
UV_RESOLUTION=lowest uv sync
UV_EXCLUDE_NEWER="7 days" uv lock
```

## Caveats / Common Mistakes

- `constraint-dependencies` and `override-dependencies` are only read from the workspace
  root `pyproject.toml`. Placing them in a member's `pyproject.toml` or in `uv.toml` has
  no effect for `uv lock`/`uv sync`/`uv run`.
- `environments` entries must be disjoint. `sys_platform == 'darwin'` and
  `python_version >= '3.9'` are not disjoint (both can be true simultaneously) and will
  cause an error.
- `exclude-newer` requires the index to publish `upload-time` (PEP 700). When a
  distribution lacks this field, it is treated as unavailable unless the package or index is
  opted out via `exclude-newer-package = { pkg = false }` or
  `[[tool.uv.index]] exclude-newer = false`.
- When using `exclude-newer` with a local date (e.g., `"2025-01-01"`), the date is
  interpreted in the system time zone. Local date times are not allowed in persistent config
  — use a full RFC 3339 timestamp there.
- `dependency-metadata` `version` is optional for registry packages but required for direct
  URL (e.g., Git) dependencies.
- Resolution messages for unsatisfiable resolutions intentionally omit the `--exclude-newer`
  filter — newer distributions appear as if they do not exist.

## See Also

- concept-resolution
- dep-overrides-constraints
- dep-platform-environments
- cmd-lock
- ts-resolution-conflict
