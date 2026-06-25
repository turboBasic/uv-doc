---
id: pip-tree
title: uv pip tree — dependency tree for an environment
category: pip
tags: [command, pip, dependency, installation]
source: https://docs.astral.sh/uv/reference/cli/#uv-pip-tree
related: [pip-install, pip-inspect, cmd-tree, pip-sync, pip-compile]
---

## Summary

`uv pip tree` displays the dependency tree of the currently active or discovered virtual
environment. It operates on what is actually installed — not on a lockfile or
`pyproject.toml` — making it the pip-interface counterpart to `uv tree`.

## Syntax / Usage

```bash
uv pip tree [OPTIONS]
```

## Details

`uv pip tree` reads installed package metadata from the environment (active `VIRTUAL_ENV`
or `.venv`) and renders a tree showing each top-level package and its transitive
dependencies. The default display depth is 255, effectively unlimited.

Key flags:

- `--depth <N>` / `-d <N>` — limit how many levels deep the tree is displayed. Default
  is 255.
- `--prune <package>` — omit a package and its subtree from the output. Can be specified
  multiple times.
- `--package <package>` — show only the subtree for the named package. Useful for
  focusing on a single dependency. Can be specified multiple times.
- `--invert` / `--reverse` — flip the tree to show reverse dependencies: for each
  package, list which packages depend on it. Combine with `--package` to answer "what
  depends on X?".
- `--outdated` — fetch the latest available version of each package from the index and
  display it alongside the installed version. Requires network access.
- `--no-dedupe` — by default, if a package has already appeared in the tree, subsequent
  occurrences show `(*)` and omit the subtree. This flag forces full expansion at every
  occurrence.
- `--show-version-specifiers` — show the version constraint imposed on each dependency
  edge (e.g., `>=2.0`).
- `--show-sizes` — show the compressed wheel size for each package.
- `--strict` — validate the environment and report packages with missing or conflicting
  dependencies.
- `--system` — inspect the system Python environment instead of a virtual environment.
- `--python <request>` / `-p` — target a specific Python interpreter.

**How it differs from `uv tree`:**

`uv tree` (the project command) reads the project's `uv.lock` file and reflects the
resolved dependency graph defined there, including dependency groups and workspace
members. `uv pip tree` reads the actual installed state of an environment — no lockfile
or `pyproject.toml` is consulted. Use `uv pip tree` when working with pip-managed or
imperatively assembled environments; use `uv tree` for project-managed workflows.

## Examples

```bash
# Show the full dependency tree of the active environment
uv pip tree

# Limit to two levels deep
uv pip tree --depth 2

# Prune setuptools and wheel from the output
uv pip tree --prune setuptools --prune wheel

# Show only the subtree for requests
uv pip tree --package requests

# Reverse lookup: what depends on urllib3?
uv pip tree --invert --package urllib3

# Show installed vs latest available versions
uv pip tree --outdated

# Show version constraints on each edge
uv pip tree --show-version-specifiers

# Inspect a specific venv without activating it
uv pip tree --python .venv/bin/python

# Inspect the system environment
uv pip tree --system

# Expand all repeated packages (no deduplication)
uv pip tree --no-dedupe
```

## Caveats / Common Mistakes

- `uv pip tree` reflects what is installed — if the environment is out of sync with
  `pyproject.toml` or a requirements file, the tree will not match the intended
  dependency specification. Run `uv pip sync` or check with `uv pip check` first.
- `--outdated` makes network requests to PyPI (or configured indexes). In offline or
  airgapped environments, use `--offline` to suppress this.
- `--invert` without `--package` inverts the entire tree. On large environments this can
  produce very verbose output; combine with `--package` or `--depth` to narrow it.
- Repeated packages are deduplicated by default (shown as `(*)`). Pass `--no-dedupe`
  only when you need to trace a specific transitive path, as the output can grow large.
- `uv tree` (project interface) and `uv pip tree` (pip interface) are distinct commands
  with different data sources. Do not use them interchangeably when diagnosing
  environment drift.

## See Also

- pip-install
- pip-inspect
- cmd-tree
- pip-sync
- pip-compile
