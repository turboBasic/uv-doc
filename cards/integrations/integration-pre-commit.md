---
id: integration-pre-commit
title: Using uv with pre-commit
category: integrations
tags: [integration, ci, lockfile, pip]
source: https://docs.astral.sh/uv/guides/integration/pre-commit/
related: [cmd-lock, cmd-export, pip-compile, concept-lockfile, cmd-sync]
---

## Summary

The official `astral-sh/uv-pre-commit` repository provides pre-commit hooks for
keeping lock files and requirements files up to date automatically on every commit.

## Syntax / Usage

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/astral-sh/uv-pre-commit
    rev: <uv-version>
    hooks:
      - id: <hook-id>
```

Available hook ids: `uv-lock`, `uv-export`, `pip-compile`.

## Details

All hooks are sourced from `https://github.com/astral-sh/uv-pre-commit`. The `rev` field
must be set to a specific uv version tag (e.g. `0.11.24`) — pinning ensures reproducible
hook behaviour across machines and CI.

**`uv-lock`** — re-runs `uv lock` whenever `pyproject.toml` changes, keeping `uv.lock`
up to date. The hook fails (and stages the updated lockfile) if the lockfile was stale.

**`uv-export`** — exports the resolved lockfile to a `requirements.txt` via `uv export`,
keeping a plain-text requirements file in sync with `uv.lock`. Useful when downstream
tooling (Docker, pip) consumes `requirements.txt` instead of `uv.lock`.

**`pip-compile`** — compiles a `.in` source file into a pinned requirements file using
`uv pip compile`. The input file and output path are passed via `args`. The `files`
pattern controls which changed files trigger the hook; without it the hook runs on every
commit.

To run `pip-compile` over multiple input files in parallel, add multiple entries with
the same `id: pip-compile` but distinct `name`, `args`, and `files` values. pre-commit
runs hook entries with distinct names in parallel.

## Examples

Keep `uv.lock` current after `pyproject.toml` edits:

```yaml
repos:
  - repo: https://github.com/astral-sh/uv-pre-commit
    rev: 0.11.24
    hooks:
      - id: uv-lock
```

Sync `requirements.txt` from the lockfile:

```yaml
repos:
  - repo: https://github.com/astral-sh/uv-pre-commit
    rev: 0.11.24
    hooks:
      - id: uv-export
```

Compile a single requirements file:

```yaml
repos:
  - repo: https://github.com/astral-sh/uv-pre-commit
    rev: 0.11.24
    hooks:
      - id: pip-compile
        args: [requirements.in, -o, requirements.txt]
```

Compile multiple requirements files in parallel:

```yaml
repos:
  - repo: https://github.com/astral-sh/uv-pre-commit
    rev: 0.11.24
    hooks:
      - id: pip-compile
        name: pip-compile requirements.in
        args: [requirements.in, -o, requirements.txt]
      - id: pip-compile
        name: pip-compile requirements-dev.in
        args: [requirements-dev.in, -o, requirements-dev.txt]
        files: ^requirements-dev\.(in|txt)$
```

## Caveats / Common Mistakes

- Using `rev: latest` or a branch name makes builds non-reproducible; always pin to a
  specific uv version tag.
- When multiple `pip-compile` entries share the same `name`, pre-commit treats them as
  one hook and runs them serially. Give each entry a unique `name` to enable parallel
  execution.
- The `files` pattern on a `pip-compile` entry must match both the `.in` source and the
  generated `.txt` output, otherwise a stale `.txt` file will not trigger a recompile
  when only the `.txt` is modified.

## See Also

- cmd-lock
- cmd-export
- pip-compile
- concept-lockfile
- cmd-sync
