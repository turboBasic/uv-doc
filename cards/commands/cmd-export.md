---
id: cmd-export
title: uv export — export the lockfile to an alternate format
category: commands
tags: [command, lockfile, project, pip, workspace]
source: https://docs.astral.sh/uv/concepts/projects/export/
related: [concept-lockfile, cmd-lock, cmd-sync, dep-groups, project-workspaces]
---

## Summary

`uv export` converts `uv.lock` into an alternate format for use with other tools. It
supports `requirements.txt` (pip-compatible), `pylock.toml` (PEP 751), and CycloneDX
v1.5 JSON SBOM output.

## Syntax / Usage

```bash
uv export [OPTIONS]
```

Output goes to stdout by default. Use `-o` / `--output-file` to write to a file.

## Details

Before exporting, uv re-locks the project unless `--locked` or `--frozen` is passed.
If no `uv.lock` exists and `--frozen` is set, uv exits with an error.

**Format selection** (`--format`):

| Value | Description |
|---|---|
| `requirements.txt` | pip-compatible flat file (default when no `--output-file`) |
| `pylock.toml` | PEP 751 standardized TOML lockfile |
| `cyclonedx1.5` | CycloneDX v1.5 JSON SBOM (preview — may change) |

When `--output-file` is given, uv infers the format from the file extension if
`--format` is not specified.

**Scope flags:**

- `--all-extras` — include all optional dependency extras.
- `--extra <name>` — include a specific extra (repeatable).
- `--all-groups` — include all dependency groups; `--no-group <name>` can exclude specific ones.
- `--group <name>` — include a specific group (repeatable).
- `--no-dev` — alias for `--no-group dev`; excludes the dev group.
- `--only-dev` — alias for `--only-group dev`; include only the dev group, omitting the project itself.
- `--only-group <name>` — include only the named group(s), omitting project dependencies (implies `--no-default-groups`).

**Workspace flags:**

- `--all-packages` — export the entire workspace; all member dependencies are merged.
- `--package <name>` — export only the named workspace member(s).

**Output control flags (requirements.txt):**

- `--no-hashes` — omit per-package hashes.
- `--no-annotate` — suppress source comments above each entry.
- `--no-header` — suppress the generated-by comment header.
- `--emit-index-url` — include `--index-url` / `--extra-index-url` lines.
- `--emit-find-links` — include `--find-links` lines.
- `--no-emit-local` / `--no-install-local` — omit local path and editable packages;
  useful for Docker layers that cache only third-party deps.
- `--no-editable` — export editable packages as non-editable (pinned by version).

**Lockfile safety flags:**

- `--frozen` — use the existing lockfile as-is without checking for changes. Exits
  with an error if no lockfile exists.
- `--locked` — assert the lockfile is up-to-date; exit with an error if it is stale.

In workspaces, the root member is exported by default; use `--package` to target a
specific member, or `--all-packages` to merge the entire workspace.

## Examples

```bash
# Export to stdout in default requirements.txt format
uv export

# Write requirements.txt, using the existing lockfile without re-locking
uv export --frozen -o requirements.txt

# Fail if lockfile is stale (safe for CI)
uv export --locked -o requirements.txt

# Include a specific extra
uv export --extra docs -o requirements-docs.txt

# Include all extras and the 'tests' group
uv export --all-extras --group tests -o requirements-full.txt

# Exclude dev dependencies
uv export --no-dev -o requirements.txt

# Omit local/editable packages — useful for Docker layer caching
uv export --frozen --no-emit-local --no-dev --no-editable -o requirements.txt

# Export as PEP 751 pylock.toml
uv export --format pylock.toml -o pylock.toml

# Export CycloneDX SBOM (preview)
uv export --format cyclonedx1.5 -o sbom.json

# Export only a specific workspace member
uv export --package my-lib -o requirements-lib.txt

# Export the entire workspace merged
uv export --all-packages -o requirements-all.txt
```

## Caveats / Common Mistakes

- **Prefer `uv.lock` over `requirements.txt`.** The docs recommend against maintaining
  both: `uv.lock` is more expressive and cannot be fully represented in
  `requirements.txt`. Only export if an external tool actually requires that format.
- **CycloneDX is preview.** The `cyclonedx1.5` format may change in any future release.
- **`--frozen` vs `--locked`:** `--frozen` skips all staleness checks; `--locked`
  checks and errors if stale. Use `--locked` in CI to catch drift; use `--frozen` when
  you have already verified the lockfile externally.
- **Format inference from extension** only applies when `--output-file` is given without
  `--format`. Passing `-o sbom.json` without `--format cyclonedx1.5` does not produce
  an SBOM — the extension-based inference covers `.toml` → `pylock.toml` and
  `.txt` → `requirements.txt`; JSON output requires explicit `--format cyclonedx1.5`.
- **`--no-emit-local` vs `--no-editable`:** these are independent. `--no-emit-local`
  omits path-based packages entirely from the output; `--no-editable` keeps them but
  writes them as pinned version specifiers instead of `-e` editable references.

## See Also

- concept-lockfile
- cmd-lock
- cmd-sync
- dep-groups
- project-workspaces
