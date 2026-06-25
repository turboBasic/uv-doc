# AI Instructions — uv-doc

## Project Overview

This repository is a Knowledge Base for AI harnesses about **uv** (astral-sh/uv), the
extremely fast Python package and project manager written in Rust. uv is a single tool
that replaces `pip`, `pip-tools`, `pipx`, `poetry`, `pyenv`, `twine`, and `virtualenv`.
The primary deliverable is a collection of Knowledge Cards covering every aspect of uv:
commands, concepts, projects, dependencies, configuration, Python version management,
tools, scripts, the pip-compatible interface, building/publishing, integrations, and
troubleshooting.

The Knowledge Cards are designed for RAG/vector-search and direct context injection
into AI assistants (Claude Code, Copilot, Cursor, etc.).

---

## Tech Stack

- **Cards:** YAML front-matter + Markdown body (one `.md` file per card)
- **Consumption:** Designed for both RAG/vector-search and direct context injection
- **Tooling:** AI agents generating cards from source materials listed below

---

## Source Materials

**Generate cards from the local mirror in `src/` first.** `src/` is a version-tracked
mirror of the upstream uv documentation, synced via `./sync-docs.sh` (see below). It is
the authoritative, offline-readable baseline — read it before reaching for the network.
The `source:` front-matter field should still cite the canonical upstream **URL** (so the
card is traceable for a reader without this repo), even when the content was read from the
local `src/` copy.

The mirror in `src/` corresponds to these upstream sources:

| Source           | URL                                                  | Local mirror (`src/`)                   |
| ---------------- | ---------------------------------------------------- | --------------------------------------- |
| Documentation    | https://docs.astral.sh/uv                            | `src/` (whole tree)                     |
| Docs source      | https://github.com/astral-sh/uv/tree/main/docs       | `src/` (whole tree)                     |
| CLI reference    | https://docs.astral.sh/uv/reference/cli/             | `src/reference/cli.md` (generated)      |
| Settings ref     | https://docs.astral.sh/uv/reference/settings/        | `src/reference/settings.md` (generated) |
| Env var ref      | https://docs.astral.sh/uv/reference/environment/     | `src/reference/environment.md` (generated) |

The three generated reference files (`cli.md`, `settings.md`, `environment.md`) are
produced by upstream's `cargo dev generate-all` build, not committed to the uv repo;
`sync-docs.sh` builds them best-effort and may skip them when `cargo` is unavailable. If
a generated file is absent locally, consult its upstream URL above.

These sources are NOT mirrored and must be consulted live when needed:

| Source           | URL                                                  | Notes                                   |
| ---------------- | ---------------------------------------------------- | --------------------------------------- |
| Source code      | https://github.com/astral-sh/uv                      | Ground truth for all behavior           |
| Changelog        | https://github.com/astral-sh/uv/blob/main/CHANGELOG.md | Version-specific behavior              |
| Issues           | https://github.com/astral-sh/uv/issues               | Bug patterns, edge cases, workarounds   |
| Discussions      | https://github.com/astral-sh/uv/discussions          | Community patterns, Q&A                 |

Do not invent behavior. If a claim cannot be traced to `src/` or one of the above
sources, omit it.

To refresh the mirror from upstream:

```sh
./sync-docs.sh
```

---

## Project Structure

```text
uv-doc/
├── CLAUDE.md                    <- entry point, references this file
├── sync-docs.sh                 <- mirrors upstream uv docs into src/ (best-effort builds cli/settings/environment refs)
├── docs/
│   └── ai-instructions.md       <- this file — single source of truth for all AI tools
├── src/                         <- version-tracked mirror of upstream uv docs (the baseline cards are generated from)
│   ├── getting-started/         <- installation, first steps, features, help
│   ├── guides/                  <- task guides; guides/integration/, guides/migration/
│   ├── concepts/                <- projects/, authentication/, resolution, indexes, cache, build-backend, tools, python-versions
│   ├── pip/                     <- pip-compatible interface docs
│   ├── reference/               <- cli.md*, settings.md*, environment.md* (*generated), policies/, internals/, troubleshooting/
│   └── index.md                 <- docs landing page
├── cards/                       <- all Knowledge Cards live here
│   ├── commands/                <- CLI commands (init, add, run, lock, sync, venv, build, publish, etc.)
│   ├── concepts/                <- architecture and concepts (resolution, lockfile, workspaces, cache, venv)
│   ├── projects/                <- project layout, members, dependency groups, workspaces
│   ├── dependencies/            <- adding deps, sources, extras, markers, constraints, overrides
│   ├── configuration/           <- pyproject.toml, uv.toml, settings, indexes, authentication
│   ├── python/                  <- Python version management, pinning, downloads, discovery
│   ├── tools/                   <- uvx / uv tool install / run (pipx replacement)
│   ├── scripts/                 <- PEP 723 inline metadata, single-file scripts
│   ├── pip/                     <- pip-compatible interface (uv pip install/compile/sync)
│   ├── build-publish/           <- build backend, uv build, uv publish, package indexes
│   ├── integrations/            <- Docker, CI/GitHub Actions, Jupyter, pre-commit, PyTorch, FastAPI
│   └── troubleshooting/         <- patterns from issues and debugging
└── .claude/
    └── skills/
        └── uv/
            └── SKILL.md         <- Claude Code skill for knowledge lookup
```

---

## Knowledge Card Schema

Every card is a single `.md` file with this exact YAML front-matter:

```yaml
---
id: <kebab-case-unique-identifier>
title: <human-readable title>
category: <commands | concepts | projects | dependencies | configuration | python | tools | scripts | pip | build-publish | integrations | troubleshooting>
tags: [<tag1>, <tag2>, ...]
source: <URL of the primary source this card is derived from>
related: [<id-of-related-card>, ...]
---
```

Followed by a Markdown body with this structure:

```markdown
## Summary

One or two sentences: what this is and why it matters.

## Syntax / Usage

(omit for concept-only cards)
Code block showing the canonical form.

## Details

Prose explanation. Cover behavior, defaults, constraints, interactions.
Keep to what is true and sourced — no speculation.

## Examples

Concrete, copy-pasteable uv invocations or config snippets. At least one example per card.

## Caveats / Common Mistakes

(omit if none documented in sources)
Known footguns, version-specific behavior, order-sensitivity, etc.

## See Also

(omit if no related cards yet)
Bulleted list of related card ids.
```

---

## Card Generation Rules

1. **One concept per card.** If a topic requires 300+ words of body text, split it.
2. **Narrow scope.** Each command, each setting, each concept gets its own card.
3. **Source every claim.** The `source:` field in front-matter must point to where the
   information was found.
4. **No duplication.** Before creating a card, check if an existing card already covers
   the concept. Prefer adding a `See Also` link.
5. **Tags must be consistent.** Use existing tags before inventing new ones. Core tag
   vocabulary: `command`, `project`, `dependency`, `lockfile`, `resolution`, `venv`,
   `python`, `tool`, `script`, `pip`, `config`, `build`, `publish`, `workspace`,
   `cache`, `index`, `authentication`, `installation`, `troubleshooting`, `integration`,
   `ci`, `docker`, `performance`.
6. **IDs are permanent.** Once a card is committed, its `id` must not change.
7. **File naming:** `<id>.md` — exactly matches the front-matter `id` field.

---

## AI Behaviour Guidelines

- Read the local mirror in `src/` before generating cards (run `./sync-docs.sh` first if
  it is stale or absent). Do not rely on training-data knowledge of uv — the project
  evolves rapidly. Fall back to the live upstream sources only for material not mirrored
  in `src/` (source code, changelog, issues, discussions).
- Prefer concrete shell examples in Examples over prose descriptions of usage.
- Distinguish the **project interface** (`uv add`, `uv sync`, `uv lock`, `uv run`) from
  the **pip-compatible interface** (`uv pip install`, `uv pip compile`). They are separate
  workflows — never conflate them in a single card.
- The `related` field should link cards that a user would naturally navigate between.
- When unsure whether something belongs in `concepts/` vs `configuration/`, ask: is it
  about what uv does (concept) or how you configure it (configuration)?
- When unsure whether something belongs in `commands/` vs a domain category, prefer the
  domain category (`projects/`, `dependencies/`, `python/`, `tools/`, `scripts/`,
  `pip/`, `build-publish/`) for workflow cards, and reserve `commands/` for per-command
  reference cards.
