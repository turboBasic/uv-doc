---
id: dep-sources
title: Dependency sources — [tool.uv.sources]
category: dependencies
tags: [dependency, config, project, index, workspace]
source: https://docs.astral.sh/uv/concepts/projects/dependencies/#dependency-sources
related: [dep-add, config-package-indexes, project-workspaces, dep-editable, dep-platform-environments, project-migrate-from-pip]
---

## Summary

`[tool.uv.sources]` extends `project.dependencies` (and other dependency tables) with
alternative resolution sources used during development — Git repos, direct URLs, local
paths, workspace members, and named indexes. Sources are uv-only; other tools see only the
standard dependency tables.

## Syntax / Usage

```toml
[tool.uv.sources]
<package-name> = { <source-key> = <value> [, <option> = <value>]* }

# or a list when multiple sources are needed (disambiguated by markers)
<package-name> = [
  { <source-key> = <value>, marker = "<env-marker>" },
  ...
]
```

## Details

`tool.uv.sources` maps a normalised package name to one source entry (or a list of entries).
uv applies the source during resolution and installation; the `project.dependencies` entry
keeps its standard form so the published metadata remains PEP 508-compliant.

### Five source types

| Key | Resolves from |
|-----|--------------|
| `index` | A named `[[tool.uv.index]]` entry |
| `git` | A Git repository (HTTPS or SSH) |
| `url` | A direct `.whl`, `.tar.gz`, or `.zip` URL |
| `path` | A local wheel, sdist, or project directory |
| `workspace` | A member of the current `[tool.uv.workspace]` |

**index source** — pins a package to a specific named index, preventing fallback to other
indexes. The index must exist in `[[tool.uv.index]]`. Set `explicit = true` on the index to
make it available only to packages that explicitly request it.

**git source** — accepts `tag`, `branch`, or `rev` to pin a specific reference. A
`subdirectory` key handles monorepos where the package root is not at the repo root. Git LFS
support is controlled per-source with `lfs = true|false`; if omitted, the `UV_GIT_LFS`
environment variable applies.

**url source** — direct link to a wheel or source distribution archive. A `subdirectory` key
is supported for source distributions where the `pyproject.toml` is not in the archive root.

**path source** — accepts absolute or relative paths to a wheel, sdist, or directory. For
directories, uv builds and installs the package by default. Pass `editable = true` to install
in editable mode (`.pth` link). Pass `package = false` to treat the directory as a virtual
dependency (install its transitive deps but not the package itself).

**workspace source** — `{ workspace = true }` declares a dependency on another member of the
current workspace. All workspace member dependencies must be declared explicitly. Workspace
members are installed as editable by default.

### Platform-specific sources

A `marker` key on any source restricts it to matching platforms or Python versions. When a
marker is present, uv falls back to PyPI (or whatever other source is configured) on
non-matching platforms.

### Multiple sources per package

A package can have a list of sources, each disambiguated by a `marker`. This enables
per-platform builds (e.g. different Git tags on macOS vs Linux) or per-extra index selection.

Sources may also use an `extra` key to scope a source to a specific
`[project.optional-dependencies]` extra.

### Workspace-level sources

`tool.uv.sources` defined in the workspace root apply to all workspace members. A member's
own `tool.uv.sources` entry overrides the root entry for that package, even if the root entry
carries a marker that does not match.

### Disabling sources

`--no-sources` instructs uv to ignore `tool.uv.sources` entirely. Use this to simulate
publishable metadata — the same behavior as tools that do not understand `tool.uv.sources`.
The env var `UV_NO_SOURCES=1` provides the same effect. `--no-sources-package <name>` disables
sources for a single package only.

## Examples

```toml
# index — pin torch to PyTorch's own index
[tool.uv.sources]
torch = { index = "pytorch" }

[[tool.uv.index]]
name = "pytorch"
url = "https://download.pytorch.org/whl/cpu"
explicit = true
```

```toml
# git — tag, branch, rev, subdirectory
[tool.uv.sources]
httpx     = { git = "https://github.com/encode/httpx", tag = "0.27.0" }
langchain = { git = "https://github.com/langchain-ai/langchain", subdirectory = "libs/langchain" }
my-lib    = { git = "https://github.com/example/my-lib", rev = "abc1234" }
```

```toml
# url — direct wheel or sdist
[tool.uv.sources]
pytest = { url = "https://files.pythonhosted.org/packages/.../pytest-8.3.3-py3-none-any.whl" }
```

```toml
# path — local directory (editable)
[tool.uv.sources]
bar = { path = "../projects/bar", editable = true }
```

```toml
# workspace member
[tool.uv.sources]
foo = { workspace = true }
```

```toml
# platform-specific: GitHub on macOS, PyPI everywhere else
[tool.uv.sources]
httpx = { git = "https://github.com/encode/httpx", tag = "0.27.2", marker = "sys_platform == 'darwin'" }
```

```toml
# multiple sources: different tags by platform
[tool.uv.sources]
httpx = [
  { git = "https://github.com/encode/httpx", tag = "0.27.2", marker = "sys_platform == 'darwin'" },
  { git = "https://github.com/encode/httpx", tag = "0.24.1", marker = "sys_platform == 'linux'" },
]
```

```toml
# multiple sources: different indexes per optional extra
[tool.uv.sources]
torch = [
  { index = "torch-cpu", extra = "cpu" },
  { index = "torch-gpu", extra = "gpu" },
]
```

Validate publishability without sources:

```console
$ uv lock --no-sources
$ uv build --no-sources
```

## Caveats / Common Mistakes

- Sources are **uv-only**. Running `pip install`, `poetry install`, or `pypa/build` will
  ignore `tool.uv.sources` and use only the standard dependency tables. Validate that the
  package builds without sources before publishing with `uv build --no-sources`.
- A workspace member source (`workspace = true`) is always installed as editable. If the
  member has no build system, it becomes a virtual dependency by default; declare `package =
  true` on the source to force installation.
- If a member's `tool.uv.sources` defines an entry for a package that the workspace root also
  defines, the member's entry wins entirely — even if the root entry uses a marker that would
  not match. Plan marker coverage carefully when mixing root and member sources.
- `--no-sources` also prevents workspace member discovery, so `uv lock --no-sources` may fail
  if workspace members are listed as dependencies.
- Git LFS objects are not fetched by default. Set `lfs = true` on the source or export
  `UV_GIT_LFS=1` if the package requires LFS assets at build time.

## See Also

- dep-add
- config-package-indexes
- project-workspaces
- dep-editable
- dep-platform-environments
- project-migrate-from-pip
