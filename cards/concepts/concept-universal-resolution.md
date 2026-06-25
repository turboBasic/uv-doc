---
id: concept-universal-resolution
title: Universal (cross-platform) resolution and resolution forking
category: concepts
tags: [resolution, lockfile, python, config, project]
source: https://docs.astral.sh/uv/concepts/resolution/#universal-resolution
related: [concept-lockfile, concept-resolution, dep-platform-environments, config-resolution-settings, ts-resolution-conflict]
---

## Summary

Universal resolution solves for all supported platforms and Python versions in a single
pass, producing a lockfile that is portable across operating systems, CPU architectures,
and Python versions. Environment markers in the output record which variant applies where.

## Details

### Universal vs. platform-specific resolution

uv's project interface (`uv lock`, `uv sync`, `uv add`, `uv run`) always uses universal
resolution. A single `uv.lock` covers every combination of platform and Python version
within the project's `requires-python` range.

uv's pip interface (`uv pip compile`) defaults to platform-specific resolution (like
`pip-tools`), but accepts `--universal` to produce a universal requirements file with
markers. It also accepts `--python-platform` and `--python-version` to target an
alternate platform during platform-specific resolution.

### Environment markers

Because universal resolution must track which packages are required where, it uses
[PEP 508 environment markers](https://packaging.python.org/en/latest/specifications/dependency-specifiers/#environment-markers)
(e.g., `sys_platform`, `python_version`, `platform_machine`) throughout the lockfile.
A single package may appear multiple times with different versions if different versions
are needed for different platforms or Python versions.

### requires-python and dependency bounds

During universal resolution, every dependency must supply a usable version for the
entire `requires-python` range declared in `pyproject.toml`. If a dependency has no
version compatible with the lower bound of `requires-python`, resolution fails. uv
evaluates only lower bounds on `requires-python` for dependencies and ignores upper
bounds (e.g., `>=3.8,<4` is treated as `>=3.8`).

### Multi-version (forked) resolution and --fork-strategy

When different Python versions require different releases of the same package, uv
includes multiple versions in the lockfile. The `--fork-strategy` setting controls the
trade-off:

| Value | Behaviour |
|---|---|
| `requires-python` (default) | Select the latest version for each supported Python version; minimize forks across platforms |
| `fewest` | Minimise the total number of selected versions; prefer older versions compatible with a wider range |

Example with `requires-python = ">=3.8"` and numpy:

- `requires-python` strategy: `numpy==1.24.4` for Python 3.8, `numpy==2.0.2` for
  Python 3.9, `numpy==2.2.0` for Python >=3.10.
- `fewest` strategy: `numpy==1.24.4` for all supported Python versions.

### Limiting the solve space with `environments`

By default uv solves for all platforms. The `environments` setting accepts a list of
PEP 508 markers that restrict the solve space. Entries must be disjoint.

```toml title="pyproject.toml"
[tool.uv]
environments = [
    "sys_platform == 'darwin'",
    "sys_platform == 'linux'",
]
```

This speeds up resolution and avoids unsatisfiable branches for platforms the project
does not target.

### Guaranteeing wheel availability with `required-environments`

Some packages (e.g., PyTorch) publish wheels but no source distribution, so they are
only installable where a wheel exists. `required-environments` forces resolution to fail
if a matching wheel is not available, rather than silently omitting the platform.

`environments` narrows the solve space; `required-environments` expands the set of
platforms that must have wheels.

## Examples

Set fork strategy to minimise version count:

```toml title="pyproject.toml"
[tool.uv]
fork-strategy = "fewest"
```

Restrict the lockfile to macOS and Linux only:

```toml title="pyproject.toml"
[tool.uv]
environments = [
    "sys_platform == 'darwin'",
    "sys_platform == 'linux'",
]
```

Require wheels for Intel macOS and Linux x86-64 (useful for PyTorch-like packages):

```toml title="pyproject.toml"
[tool.uv]
required-environments = [
    "sys_platform == 'darwin' and platform_machine == 'x86_64'",
    "sys_platform == 'linux' and platform_machine == 'x86_64'",
]
```

Produce a universal requirements file with the pip interface:

```bash
uv pip compile --universal requirements.in -o requirements.txt
```

## Caveats / Common Mistakes

- `environments` entries must be disjoint. `sys_platform == 'darwin'` and
  `python_version >= '3.9'` are not disjoint (both can be true simultaneously) — uv
  will error.
- A project's `requires-python` range directly widens the solve space. Overly broad
  ranges (e.g., `>=3.7`) can force resolution to include very old package versions or
  fail for dependencies that have dropped support for old Pythons.
- `required-environments` is for packages without source distributions. If the package
  has a source distribution, uv can always build it; `required-environments` does not
  add value there.
- Platform-specific resolution (`uv pip compile` without `--universal`) uses the
  provided `--python-version` as an exact version, not a lower bound, unlike universal
  resolution.

## See Also

- concept-lockfile
- concept-resolution
- dep-platform-environments
- config-resolution-settings
- ts-resolution-conflict
