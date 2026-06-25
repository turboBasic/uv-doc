---
id: project-migrate-from-pip
title: Migrating from pip / pip-tools to a uv project
category: projects
tags: [project, dependency, lockfile, pip]
source: https://docs.astral.sh/uv/guides/migration/pip-to-project/
related: [dep-add, dep-sources, project-dependency-groups, concept-lockfile, pip-compile]
---

## Summary

Converting a `requirements.txt` / `pip-tools` workflow to a uv project means replacing
`requirements.in` with `pyproject.toml` and `requirements.txt` with `uv.lock`. The `uv add`
command imports existing requirements files directly, and constraints preserve your
already-locked versions during the switch.

## Syntax / Usage

```bash
# Create a pyproject.toml if you don't have one
uv init

# Import requirements, preserving previously locked versions as constraints
uv add -r requirements.in -c requirements.txt
```

## Details

### What replaces what

- `requirements.in` (declared deps) → `[project.dependencies]` in `pyproject.toml`.
- `requirements.txt` (locked deps) → `uv.lock`, a uv-specific, always-universal lockfile.
- Per-platform requirements files are unnecessary: a single `uv.lock` is
  [universal](https://docs.astral.sh/uv/concepts/resolution/#universal-resolution) across
  platforms (see `concept-lockfile`).

### Importing requirements

The simplest import is `uv add -r requirements.in`. Because `requirements.in` is unpinned,
uv will resolve fresh versions. To keep your existing locked versions unchanged during the
migration, pass the locked file as a constraint:

```bash
uv add -r requirements.in -c requirements.txt
```

### Importing platform-specific lock files

You cannot pass a bare platform-specific `requirements.txt` via `-c` — those files lack
environment markers and will conflict. First add markers by re-compiling with
`uv pip compile` (see `pip-compile`):

```bash
uv pip compile requirements.in -o requirements-win.txt \
  --python-platform windows --no-strip-markers
```

Then import the marker-annotated files together:

```bash
uv add -r requirements.in -c requirements-win.txt -c requirements-linux.txt
```

### Importing development / grouped dependencies

Dev and other dependency groups (see `project-dependency-groups`) import with `--dev` or
`--group <name>`:

```bash
uv add --dev -r requirements-dev.in -c requirements-dev.txt
uv add -r requirements-docs.in -c requirements-docs.txt --group docs
```

If `requirements-dev.in` includes the base file via `-r requirements.in`, strip those lines
first so the base deps don't land in the `dev` group:

```bash
sed '/^-r /d' requirements-dev.in | uv add --dev -r - -c requirements-dev.txt
```

### Importing dependency sources

Local paths, editable paths, and Git requirements are mapped automatically into
`[tool.uv.sources]` (see `dep-sources`). For example, `./path-dep`, `-e ./editable-dep`, and
`git-dep @ git+https://...` become `path`, `path + editable = true`, and `git` source
entries respectively.

### Project environments

Unlike pip, uv has no "active" virtual environment concept — each project gets a managed
`.venv`. Run commands with `uv run` (which verifies the lockfile and environment are current
first), or create the environment explicitly with `uv sync`. In a project, uv prefers the
project `.venv` and ignores `VIRTUAL_ENV` unless you pass `--active`.

## Examples

```bash
# Straight import, re-resolving to current versions
uv init
uv add -r requirements.in

# Migration that preserves existing pins
uv add -r requirements.in -c requirements.txt

# Convert platform-specific locks to universal, then import
uv pip compile requirements.in -o requirements-linux.txt --python-platform linux --no-strip-markers
uv pip compile requirements.in -o requirements-win.txt   --python-platform windows --no-strip-markers
uv add -r requirements.in -c requirements-linux.txt -c requirements-win.txt

# Import a dev group, stripping the included base file
sed '/^-r /d' requirements-dev.in | uv add --dev -r - -c requirements-dev.txt

# Run in the managed environment afterward
uv run pytest
```

## Caveats / Common Mistakes

- Passing a bare platform-specific `requirements.txt` to `-c` fails — it has no markers and
  conflicts across platforms. Re-compile with `--no-strip-markers` first.
- Without `-c requirements.txt`, `uv add -r requirements.in` re-resolves and may change your
  locked versions. Use the constraint to keep them stable.
- A `requirements-dev.in` that pulls in the base file via `-r` will add base deps to the dev
  group unless you strip the `-r` lines before importing.
- uv does not read `pip.conf` or `PIP_INDEX_URL`; configure indexes in `pyproject.toml` /
  `uv.toml` instead.

## See Also

- dep-add
- dep-sources
- project-dependency-groups
- concept-lockfile
- pip-compile
