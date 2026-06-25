---
id: cmd-tree
title: uv tree — display the project dependency tree
category: commands
tags: [command, project, dependency, lockfile, resolution]
source: https://docs.astral.sh/uv/reference/cli/#uv-tree
related: [concept-lockfile, cmd-lock, project-dependency-groups, dep-groups, pip-tree]
---

## Summary

`uv tree` renders the project's resolved dependency graph as a tree, showing each
package and its transitive dependencies. It is the primary way to inspect what uv
has locked without reading `uv.lock` directly.

## Syntax / Usage

```bash
uv tree [OPTIONS]
```

## Details

Before rendering, `uv tree` automatically updates the lockfile if it is out of date —
the same behaviour as `uv run` and `uv sync`. Use `--frozen` to skip this check and
display the current lockfile as-is (exits with an error if the lockfile is missing),
or `--locked` to assert the lockfile is already up-to-date (exits with an error if
it is not).

Key flags:

- `--depth`/`-d <N>` — limit display to N levels of nesting. Default is 255 (effectively
  unlimited).
- `--invert`/`--reverse` — flip the tree to show reverse dependencies: each node lists
  the packages that depend on it rather than the packages it depends on.
- `--package <name>` — show only the sub-tree rooted at the specified package. Can be
  combined with `--invert` to answer "what depends on `<package>`?".
- `--prune <name>` — remove a specific package (and its subtree) from the display.
- `--no-dedupe` — repeat full sub-trees for every occurrence of a package instead of
  showing `(*)` for already-displayed nodes.
- `--universal` — show a platform-independent tree: all resolved versions across every
  Python version and platform, not filtered to the current environment.
- `--python-version <version>` / `--python-platform <platform>` — filter the tree as if
  resolving for a specific Python version or target platform, without requiring that
  interpreter to be installed.
- `--outdated` — annotate each package in the tree with the latest available version on
  the index.
- `--show-sizes` — annotate each package with its compressed wheel size.
- `--all-groups` — include dependencies from all dependency groups. Individual groups
  can be excluded with `--no-group <name>`.
- `--group <name>` — include a specific dependency group (may be repeated).
- `--no-group <name>` — exclude a specific dependency group. Always takes precedence
  over `--all-groups` and `--group`.
- `--no-dev` — alias for `--no-group dev`.
- `--only-group <name>` — show only the specified dependency group; omits the project
  and its non-group dependencies.
- `--extra <name>` / `--all-extras` — include optional dependency extras.
- `--script <path>` — display the dependency tree for a PEP 723 script instead of the
  current project. Reuses the script's `.lock` file if present, updating it if necessary.

## Examples

```bash
# Basic project dependency tree
uv tree

# Limit depth to direct and first-level transitive dependencies
uv tree --depth 2

# Show what depends on requests (reverse lookup)
uv tree --invert --package requests

# Show only the sub-tree for a specific package
uv tree --package httpx

# Platform-independent tree for all Python versions
uv tree --universal

# Include all dependency groups (dev, test, docs, etc.)
uv tree --all-groups

# Show tree without updating the lockfile (fail if missing)
uv tree --frozen

# Check tree in CI — fail if lockfile would change
uv tree --locked

# Show tree for a standalone PEP 723 script
uv tree --script my_script.py

# Show outdated versions alongside resolved ones
uv tree --outdated
```

## Caveats / Common Mistakes

- By default, `uv tree` filters the displayed packages to those relevant for the
  current platform and Python interpreter. Pass `--universal` to see the full
  cross-platform graph, which may show multiple versions of the same package.
- When a package appears more than once in the graph, subsequent occurrences show
  `(*)` and their subtree is collapsed. Use `--no-dedupe` to expand them, but note
  that this can produce very large output for projects with many shared transitive
  dependencies.
- `uv tree` is a project interface command. To inspect the dependency tree of an
  ad-hoc virtual environment managed with `uv pip`, use `uv pip tree` instead.
- `--invert` without `--package` inverts the entire tree, which lists every package
  with the packages that depend on it — useful for auditing, but can be verbose.

## See Also

- concept-lockfile
- cmd-lock
- project-dependency-groups
- dep-groups
- pip-tree
