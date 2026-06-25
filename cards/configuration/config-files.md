---
id: config-files
title: Configuration files — pyproject.toml vs uv.toml
category: configuration
tags: [config, project, index, authentication]
source: https://docs.astral.sh/uv/concepts/configuration-files/
related: [project-structure, dep-add, pip-install, bp-build-publish]
---

## Summary

uv reads settings from `[tool.uv]` in `pyproject.toml` or from a standalone `uv.toml`,
discovered across project, user, and system levels. `uv.toml` takes precedence over
`pyproject.toml` in the same directory.

## Syntax / Usage

`pyproject.toml` (tool-prefixed table):

```toml
[tool.uv]
[[tool.uv.index]]
url = "https://test.pypi.org/simple"
default = true
```

`uv.toml` (no `tool.uv` prefix):

```toml
[[index]]
url = "https://test.pypi.org/simple"
default = true
```

## Details

Discovery happens at three levels:

1. **Project** — current directory or nearest parent.
2. **User** — `~/.config/uv/uv.toml` (macOS/Linux) or `%APPDATA%\uv\uv.toml` (Windows).
3. **System** — `/etc/uv/uv.toml` or `%PROGRAMDATA%\uv\uv.toml`.

User- and system-level configuration cannot use the `pyproject.toml` format — only
`uv.toml`. When both `uv.toml` and `pyproject.toml` exist in one directory, `uv.toml`
wins entirely.

Precedence, highest to lowest: command-line args → environment variables → project
config → user config → system config. Array settings are concatenated across levels,
with project-level entries appearing first.

The `[tool.uv.pip]` table holds settings that apply only to `uv pip` subcommands, not to
`uv sync`/`uv lock`/etc.

Override discovery with `--no-config` (ignore all persistent config) or
`--config-file <path>` (use one specific `uv.toml`).

## Examples

```toml
# pyproject.toml — settings scoped to the uv pip interface only
[tool.uv.pip]
index-url = "https://pypi.org/simple"
no-build-isolation = true
```

```bash
# Ignore all config files for a one-off run
uv sync --no-config

# Point uv at a specific config file
uv pip compile --config-file ./ci/uv.toml requirements.in
```

## Caveats / Common Mistakes

- Keeping both `uv.toml` and a `[tool.uv]` block in `pyproject.toml` in the same
  directory silently ignores the `pyproject.toml` settings.
- `[tool.uv.pip]` does not affect project commands — don't expect `uv sync` to honor it.

## See Also

- project-structure
- dep-add
- pip-install
- bp-build-publish
