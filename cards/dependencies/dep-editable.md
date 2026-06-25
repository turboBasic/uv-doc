---
id: dep-editable
title: Editable and virtual path dependencies
category: dependencies
tags: [dependency, project, workspace, installation]
source: https://docs.astral.sh/uv/concepts/projects/dependencies/#editable-dependencies
related: [dep-sources, project-workspaces, dep-add, project-packaging, cmd-sync]
---

## Summary

Editable installations link a local package directory into the virtual environment via a `.pth`
file, so the interpreter uses source files directly without a rebuild on every change. Virtual
dependencies install a path dependency's transitive deps but do not build or install the package
itself.

## Syntax / Usage

```bash
# Add an editable path dependency
uv add --editable ./path/to/pkg

# Opt out of editable for a workspace member
uv add --no-editable ./path/to/pkg
```

```toml
# Editable path source in pyproject.toml
[tool.uv.sources]
bar = { path = "../projects/bar", editable = true }

# Virtual path source (package not installed, only its deps are)
[tool.uv.sources]
bar = { path = "../projects/bar", package = false }
```

## Details

### Editable installations

A normal directory installation builds a wheel and copies source files into the virtual
environment. After editing sources, the installed copy is stale. An editable installation writes a
`.pth` file into the virtual environment that points the interpreter directly at the source tree,
so every import picks up the latest code without reinstalling.

Editable mode is requested via `--editable` on `uv add`, which records `editable = true` in
`[tool.uv.sources]`. The flag applies only to directory (project) sources — wheel or sdist path
sources cannot be editable.

**Build-backend requirement:** the build backend must support editable installs (PEP 660). Most
modern backends (`hatchling`, `setuptools>=64`, `flit-core`, `maturin`, etc.) do. If the backend
does not support PEP 660, uv will fall back to a legacy editable mechanism or error.

**Native extensions:** native modules (compiled C/Cython/Rust extensions) are not recompiled on
import, even in editable mode. A rebuild is still required after changing extension code.

**Workspace members are editable by default.** uv always installs workspace members as editable
unless `--no-editable` is explicitly passed. To override globally, set `tool.uv.package = false`
on the member to treat it as a virtual dependency instead.

### Virtual dependencies

A virtual dependency is a path (or workspace) source where the package itself is not built or
installed, but its transitive dependencies are added to the environment. This is useful for
monorepo roots or shared constraint sets that are not independently installable packages.

Virtual behavior is opt-in at the source level via `package = false`:

```toml
[tool.uv.sources]
bar = { path = "../projects/bar", package = false }
```

It can also be set project-wide in the referenced package's own `pyproject.toml`:

```toml
[tool.uv]
package = false
```

When `tool.uv.package = false` is set on a project, uv will not attempt to build it. If a
dependent project's source overrides this with `package = true`, the package is built and
installed regardless.

Workspace members that are declared in `[tool.uv.workspace] members` but are **not** listed as
dependencies in any member's `project.dependencies` are implicitly virtual — their own package is
not installed, but their `project.dependencies` are pulled in.

## Examples

### Editable local dependency

```bash
uv add --editable ../sibling-lib
```

Resulting `pyproject.toml`:

```toml
[project]
dependencies = ["sibling-lib"]

[tool.uv.sources]
sibling-lib = { path = "../sibling-lib", editable = true }
```

### Virtual path dependency (install deps only)

```toml
[project]
dependencies = ["shared-config"]

[tool.uv.sources]
shared-config = { path = "../shared-config", package = false }
```

`shared-config` itself is not installed; its dependencies are resolved and installed.

### Workspace member editable by default

```toml
# root pyproject.toml
[project]
dependencies = ["foo"]

[tool.uv.sources]
foo = { workspace = true }

[tool.uv.workspace]
members = ["packages/foo"]
```

`packages/foo` is installed as editable automatically — no `editable = true` needed.

### Opt out of editable for a workspace member

```bash
uv add --no-editable packages/bar
```

Or in `pyproject.toml`:

```toml
[tool.uv.sources]
bar = { path = "packages/bar", editable = false }
```

## Caveats / Common Mistakes

- **Editable requires a build backend.** If the target project has no `[build-system]` table, uv
  cannot produce an editable install. Either add a build system or use `package = false` (virtual)
  instead.
- **Native extensions are not auto-recompiled.** Changes to Rust/C/Cython code still require
  `uv run maturin develop` (or equivalent) after editing.
- **`package = false` vs `editable = true` are distinct.** `package = false` means the package is
  never installed (virtual). `editable = true` means the package is installed but linked to source.
  Setting both simultaneously is contradictory and unnecessary.
- **`tool.uv.sources` is uv-specific.** Other tools (pip, poetry) ignore it. Validate a
  publishable build without sources via `uv build --no-sources`.
- **Workspace members listed under `members` but not in any `dependencies` list are implicitly
  virtual**, even without `package = false`, as long as they declare no build system.

## See Also

- dep-sources
- project-workspaces
- dep-add
- project-packaging
- cmd-sync
