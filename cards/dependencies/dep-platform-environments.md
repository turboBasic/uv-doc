---
id: dep-platform-environments
title: Platform-scoped resolution — environments and required-environments
category: dependencies
tags: [dependency, resolution, lockfile, config]
source: https://docs.astral.sh/uv/concepts/resolution/#limited-resolution-environments
related: [concept-resolution, concept-lockfile, config-resolution-settings, integration-pytorch, ts-platform-markers, concept-platform-support]
---

## Summary

`tool.uv.environments` limits which platforms uv solves during universal resolution, shrinking the lockfile. `tool.uv.required-environments` forces the resolver to verify that wheels exist for specific platforms, causing resolution to fail if a binary-only package (like PyTorch) has no wheel for a required target.

## Syntax / Usage

```toml
# pyproject.toml

[tool.uv]
# Limit the lockfile to a subset of platforms (disjoint entries required)
environments = [
    "sys_platform == 'darwin'",
    "sys_platform == 'linux'",
]

# Require wheels to exist for specific targets (fail if absent)
required-environments = [
    "sys_platform == 'darwin' and platform_machine == 'arm64'",
    "sys_platform == 'linux' and platform_machine == 'x86_64'",
    "sys_platform == 'win32' and platform_machine == 'AMD64'",
]
```

Both settings accept PEP 508 environment marker expressions as strings or a list of strings.

## Details

### `tool.uv.environments` — limit resolution scope

By default, uv's universal resolver solves for every platform and Python version in the `requires-python` range. `environments` lets you declare which environments uv should actually resolve for, excluding all others from the lockfile.

This is useful when:
- Your project is Linux/macOS-only and you want to keep the lockfile clean of Windows-specific packages.
- You want to exclude alternative Python implementations (e.g., restrict to CPython only).
- A dependency does not build on all platforms and you know it will never be deployed there.

**Disjointness requirement:** entries must not overlap. For example, `"sys_platform == 'darwin'"` and `"sys_platform == 'linux'"` are disjoint and valid. `"sys_platform == 'darwin'"` and `"python_version >= '3.9'"` are _not_ disjoint (both can be true simultaneously) and will be rejected.

The setting also applies when `uv pip compile --universal` is used.

**Default:** `[]` (solve for all environments).

### `tool.uv.required-environments` — assert wheel availability

When a package ships only wheels (no source distribution), it is only installable on platforms that have a matching wheel. By default, uv only checks that at least one wheel is compatible with the declared Python version; it does not guarantee coverage of all target platforms.

`required-environments` upgrades that check: uv will fail during resolution if any package without a source distribution lacks a wheel for each listed environment. This is the correct tool for projects that depend on PyTorch or similarly binary-heavy packages, where silently resolving without a compatible wheel for a target platform would produce a broken install.

**Key contrast with `environments`:**
- `environments` *reduces* the set of platforms uv solves for.
- `required-environments` *expands* the minimum set of platforms uv must cover.

Both can coexist. For example, you can limit the lockfile to Linux and macOS (`environments`) while also asserting that PyTorch wheels exist for both x86_64 and ARM64 variants on those platforms (`required-environments`).

**Default:** `[]` (only check that at least one compatible wheel exists for the target Python version).

### Common marker values

| Marker | Linux | macOS | Windows |
|---|---|---|---|
| `sys_platform` | `'linux'` | `'darwin'` | `'win32'` |
| `platform_system` | `'Linux'` | `'Darwin'` | `'Windows'` |
| `platform_machine` (x86-64) | `'x86_64'` | `'x86_64'` | `'AMD64'` |
| `platform_machine` (ARM64) | `'aarch64'` | `'arm64'` | `'ARM64'` |
| `os_name` | `'posix'` | `'posix'` | `'nt'` |

Note: `sys_platform` is always `'win32'` on Windows, even on 64-bit systems.

To inspect marker values for the current platform:

```console
$ uvx python -c "import sysconfig; print(sysconfig.get_config_vars())"
```

### Per-dependency markers vs. lockfile-level settings

Environment markers can appear in two places:

- **Per-dependency** (e.g., `uv add "pywinreg; sys_platform == 'win32'"`): the package is included in the lockfile but only installed on matching platforms.
- **`tool.uv.environments`**: controls which platforms are solved at all — platforms excluded here are never present in the lockfile, and per-dependency markers for those platforms are ignored.

## Examples

### Linux/macOS-only project, skip Windows entirely

```toml
[tool.uv]
environments = [
    "sys_platform == 'darwin'",
    "sys_platform == 'linux'",
]
```

### CPython-only lockfile

```toml
[tool.uv]
environments = [
    "implementation_name == 'cpython'"
]
```

### PyTorch project — require wheels on all target platforms

```toml
[project]
name = "ml-project"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = ["torch>=2.0"]

[tool.uv]
required-environments = [
    "sys_platform == 'darwin' and platform_machine == 'arm64'",
    "sys_platform == 'linux' and platform_machine == 'x86_64'",
    "sys_platform == 'win32' and platform_machine == 'AMD64'",
]
```

Resolution fails immediately if no PyTorch wheel is available for any listed environment, rather than producing a lockfile that silently breaks on that platform.

### Require support for legacy Intel macOS

```toml
[tool.uv]
required-environments = [
    "sys_platform == 'darwin' and platform_machine == 'x86_64'"
]
```

This forces uv to backtrack past any package version that dropped Intel macOS wheel support.

### Combining both settings

```toml
[tool.uv]
# Only solve for Linux and macOS — ignore Windows entirely
environments = [
    "sys_platform == 'darwin'",
    "sys_platform == 'linux'",
]
# Within those, require wheels for both architectures
required-environments = [
    "sys_platform == 'darwin' and platform_machine == 'arm64'",
    "sys_platform == 'darwin' and platform_machine == 'x86_64'",
    "sys_platform == 'linux' and platform_machine == 'x86_64'",
    "sys_platform == 'linux' and platform_machine == 'aarch64'",
]
```

## Caveats / Common Mistakes

- **Disjointness is enforced for `environments` only.** Entries in `required-environments` may overlap. Overlapping entries in `environments` will cause an error.
- **`environments` does not suppress per-dependency markers.** A dep like `"pywinreg; sys_platform == 'win32'"` is still valid in `pyproject.toml` even when `environments` excludes Windows; uv simply never resolves that branch.
- **`required-environments` only applies to packages without a source distribution.** Packages that publish a source distribution are always installable (via build-from-source) so no wheel check is performed.
- **uv.toml scope:** `environments` and `required-environments` are read from the workspace root `pyproject.toml`. Declarations in non-root `uv.toml` files are respected according to the normal configuration hierarchy, but workspace-level resolution always uses the root.

## See Also

- concept-resolution
- concept-lockfile
- config-resolution-settings
- integration-pytorch
- ts-platform-markers
- concept-platform-support
