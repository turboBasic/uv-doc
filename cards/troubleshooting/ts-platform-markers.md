---
id: ts-platform-markers
title: Platform and environment marker surprises in universal resolution
category: troubleshooting
tags: [troubleshooting, resolution, lockfile, dependency, config]
source: https://docs.astral.sh/uv/concepts/resolution/#platform-markers
related: [concept-universal-resolution, dep-platform-environments, concept-lockfile, config-resolution-settings, ts-resolution-conflict]
---

## Summary

`uv.lock` is a cross-platform lockfile produced by universal resolution — unlike pip-tools'
platform-specific output. This causes packages to appear with unexpected environment markers or
multiple versions in the lockfile, and can produce resolution failures when `requires-python` is
too broad or when packages lack source distributions.

## Details

### Universal vs. platform-specific resolution

uv's project interface (`uv lock`, `uv sync`, `uv add`) always uses **universal resolution**:
the lockfile is solved for all platforms and Python versions simultaneously so that every developer
can use the same `uv.lock` regardless of their OS or architecture.

`uv pip compile` defaults to **platform-specific resolution** (matching pip-tools behaviour),
using the markers of the current machine. Pass `--universal` to get cross-platform output that
includes markers, comparable to what `uv.lock` contains.

### Why packages appear with markers or multiple times

During universal resolution uv must keep track of which version belongs on which platform. A
package appears with markers such as `; sys_platform == "win32"` when it is only required on
Windows, and may appear multiple times at different versions when different Python versions need
different releases of the same package.

Example: with `requires-python = ">=3.8"`, `numpy` may resolve to three entries:

```
numpy==1.24.4 ; python_version == "3.8"
numpy==2.0.2  ; python_version == "3.9"
numpy==2.2.0  ; python_version >= "3.10"
```

This is normal and intentional — it is not a conflict.

### Common marker values by platform

The values are derived from the Python runtime (`sys.platform`, `platform.machine()`, `os.name`):

| Marker                       | Linux       | macOS      | Windows     |
| ---------------------------- | ----------- | ---------- | ----------- |
| `sys_platform`               | `'linux'`   | `'darwin'` | `'win32'`   |
| `platform_system`            | `'Linux'`   | `'Darwin'` | `'Windows'` |
| `platform_machine` (x86-64)  | `'x86_64'`  | `'x86_64'` | `'AMD64'`   |
| `platform_machine` (ARM64)   | `'aarch64'` | `'arm64'`  | `'ARM64'`   |
| `os_name`                    | `'posix'`   | `'posix'`  | `'nt'`      |

Note: `sys_platform` is always `'win32'` on Windows, even on 64-bit systems.

### How `requires-python` affects universal resolution

Universal resolution requires every dependency to be compatible with the **entire** declared
`requires-python` range. If any version of a dependency requires Python 3.9+ while the project
declares `requires-python = ">=3.8"`, resolution fails unless an older version of that dependency
supports 3.8.

uv only considers lower bounds on `requires-python` for dependencies — upper bounds such as
`<4` are ignored entirely, to avoid backtracking caused by overly conservative upstream metadata.

### Limiting resolution to specific platforms (`environments`)

Use `[tool.uv] environments` to narrow the set of platforms the resolver considers. This reduces
the number of markers and versions in `uv.lock` and can speed up resolution:

```toml
[tool.uv]
environments = [
    "sys_platform == 'darwin'",
    "sys_platform == 'linux'",
]
```

Entries **must be disjoint** — they must not overlap. `sys_platform == 'darwin'` and
`sys_platform == 'linux'` are disjoint; `sys_platform == 'darwin'` and
`python_version >= '3.9'` are not, because both can be true at the same time, and uv will
reject overlapping entries.

The `environments` setting is also respected by `uv pip compile` when set in the project config.

### Packages without source distributions (`required-environments`)

Some packages (e.g. PyTorch GPU builds) publish only pre-built wheels for specific platforms and
no source distribution. Universal resolution fails for these packages because there is no wheel
for at least one platform in the full cross-platform matrix.

`required-environments` tells uv which platforms **must** have a compatible wheel; resolution
fails explicitly if none is found, rather than silently falling back to a source build:

```toml
[tool.uv]
required-environments = [
    "sys_platform == 'darwin' and platform_machine == 'x86_64'"
]
```

While `environments` **limits** the platforms resolved, `required-environments` **expands** the
set of platforms that must be satisfiable.

## Examples

Check marker values for the current machine:

```console
$ uvx python -c "import sysconfig; print(sysconfig.get_config_vars())"
```

Restrict the lockfile to Linux and macOS only (disjoint entries required):

```toml
# pyproject.toml
[tool.uv]
environments = [
    "sys_platform == 'linux'",
    "sys_platform == 'darwin'",
]
```

Restrict to CPython only:

```toml
[tool.uv]
environments = [
    "implementation_name == 'cpython'"
]
```

Require a wheel for Intel macOS (useful for PyTorch-style packages):

```toml
[tool.uv]
required-environments = [
    "sys_platform == 'darwin' and platform_machine == 'x86_64'"
]
```

Produce a cross-platform `requirements.txt` (with markers) via the pip interface:

```console
$ uv pip compile --universal requirements.in -o requirements.txt
```

Produce a platform-specific file for Linux/Python 3.11 from macOS:

```console
$ uv pip compile --python-platform linux --python-version 3.11 requirements.in -o requirements-linux.txt
```

## Caveats / Common Mistakes

- Overlapping `environments` entries are rejected. `sys_platform == 'darwin'` and
  `python_version >= '3.9'` overlap and will cause an error; split them into fully disjoint
  expressions or use a single entry with `and`.
- `environments` removes platforms from the universal resolution entirely — packages that were
  previously needed only on Windows will disappear from `uv.lock`. This is intentional but can
  surprise teammates on excluded platforms.
- A too-broad `requires-python` is often the real cause of resolution failures that look like
  marker issues. Tightening `requires-python` to match the platforms you actually support usually
  resolves them.
- `--python-platform` in `uv pip compile` cannot express every marker value (e.g.
  `platform_version` on macOS encodes kernel build time). uv makes a best-effort approximation;
  results may not be pixel-perfect for unusual package/platform combinations.
- On Windows, `sys_platform` is always `'win32'` even on 64-bit systems. Use
  `platform_machine == 'AMD64'` to distinguish 64-bit Windows from 32-bit.

## See Also

- concept-universal-resolution
- dep-platform-environments
- concept-lockfile
- config-resolution-settings
- ts-resolution-conflict
