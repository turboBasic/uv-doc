---
id: dep-optional
title: Optional dependencies and extras
category: dependencies
tags: [dependency, project, config, resolution]
source: https://docs.astral.sh/uv/concepts/projects/dependencies/#optional-dependencies
related: [dep-add, dep-groups, concept-resolution, project-conflicting-deps, dep-sources]
---

## Summary

`[project.optional-dependencies]` declares named groups of dependencies ("extras") that
consumers opt into with the `package[extra]` syntax. Extras are published in the package
metadata and are the standard mechanism for shipping optional features (e.g. `pandas[plot]`).

## Syntax / Usage

```bash
# Add a package to an optional group (creates the group if absent)
uv add <package> --optional <extra>

# Install the current project with one or more extras
uv sync --extra <extra>
uv sync --extra <extra1> --extra <extra2>

# Consume an extra when depending on a third-party package
uv add "pandas[excel,plot]"
```

## Details

Optional dependencies live in `[project.optional-dependencies]`, a TOML table that maps
extra names to lists of dependency specifiers. They follow the same
[PEP 508](https://peps.python.org/pep-0508/) syntax as `project.dependencies` and are
included in published package metadata.

`uv add --optional <extra>` writes the dependency into the named extra table, re-resolves
the lockfile, and syncs the environment.

**Sources scoped to an extra.** `tool.uv.sources` entries can be restricted to a specific
extra using the `extra` key. This is useful when the same package name appears in multiple
extras but must be fetched from different indexes:

```toml
[tool.uv.sources]
torch = [
  { index = "torch-cpu", extra = "cpu" },
  { index = "torch-gpu", extra = "gpu" },
]
```

**Conflicting extras.** uv resolves all extras together when building the lockfile. If two
extras require incompatible versions of the same package, resolution fails unless the
conflict is declared explicitly in `tool.uv.conflicts`:

```toml
[tool.uv]
conflicts = [
    [
      { extra = "extra1" },
      { extra = "extra2" },
    ],
]
```

When conflicts are declared, uv resolves the extras in separate passes, allowing the
lockfile to be created. However, installing both conflicting extras simultaneously is still
an error at sync time.

## Examples

**Declaring extras manually:**

```toml
[project]
name = "mylib"
version = "0.1.0"

[project.optional-dependencies]
plot = [
  "matplotlib>=3.6.3",
]
excel = [
  "openpyxl>=3.1.0",
  "xlrd>=2.0.1",
]
```

**Adding an optional dependency via CLI:**

```bash
uv add httpx --optional network
# Writes httpx into [project.optional-dependencies] network = [...]
```

**Installing with extras:**

```bash
uv sync --extra plot
uv sync --extra plot --extra excel
```

**Scoping a source to a specific extra (e.g. CPU vs GPU torch):**

```toml
[project.optional-dependencies]
cpu = ["torch"]
gpu = ["torch"]

[tool.uv.sources]
torch = [
  { index = "torch-cpu", extra = "cpu" },
  { index = "torch-gpu", extra = "gpu" },
]

[[tool.uv.index]]
name = "torch-cpu"
url = "https://download.pytorch.org/whl/cpu"

[[tool.uv.index]]
name = "torch-gpu"
url = "https://download.pytorch.org/whl/cu130"
```

**Declaring conflicting extras so the lockfile can be created:**

```toml
[project.optional-dependencies]
extra1 = ["numpy==2.1.2"]
extra2 = ["numpy==2.0.0"]

[tool.uv]
conflicts = [
    [
      { extra = "extra1" },
      { extra = "extra2" },
    ],
]
```

## Caveats / Common Mistakes

- If two extras require incompatible versions of the same package and `tool.uv.conflicts`
  is not declared, `uv lock` will fail with a resolution error. Declare conflicts explicitly
  to allow separate resolution passes.
- Even with conflicts declared, `uv sync --extra extra1 --extra extra2` will error at sync
  time — conflicting extras cannot be installed into the same environment simultaneously.
- `tool.uv.sources` is uv-specific; other tools will ignore it. Validate a publishable
  build without sources using `uv build --no-sources`.
- Removing an optional dependency with `uv remove` requires the `--optional <extra>` flag
  to target the correct table; omitting it will look in `project.dependencies` first.

## See Also

- dep-add
- dep-groups
- concept-resolution
- project-conflicting-deps
- dep-sources
