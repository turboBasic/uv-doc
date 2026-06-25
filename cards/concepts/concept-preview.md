---
id: concept-preview
title: Preview features
category: concepts
tags: [config, command]
source: https://docs.astral.sh/uv/concepts/preview/
related: [config-files, config-env-vars, concept-cache, concept-resolution]
---

## Summary

Preview features are opt-in, unstable uv capabilities released for community feedback before
becoming default. They are gated behind explicit flags, environment variables, or configuration so
that behavior changes don't affect users who haven't enabled them.

## Syntax / Usage

```bash
uv run --preview ...                       # enable all preview features
uv run --preview-features foo,bar ...      # enable specific features
uv run --no-preview ...                    # disable preview features
```

## Details

Preview features can be enabled several ways:

- `--preview` enables all of them; `--preview-features <name>` enables specific ones. The latter is
  repeatable (`--preview-features foo --preview-features bar`) or comma-separated (`foo,bar`).
- The `UV_PREVIEW` and `UV_PREVIEW_FEATURES` environment variables mirror those flags.
- In `uv.toml`, under `[tool.uv]` in `pyproject.toml`, or in PEP 723 script metadata via
  `preview-features = ["foo", "bar"]`. Set `preview-features = true` to enable everything.

Enabling a preview feature that does not exist warns rather than errors, for backwards
compatibility — regardless of where it was enabled. Some preview features take effect *before*
configuration files are loaded and therefore cannot be enabled from configuration (only via flag or
environment variable).

Often a feature can be used without enabling anything, when the behavior is gated by user
interaction. For example, while `pylock.toml` support is in preview, passing a `pylock.toml` to
`uv pip install` activates it directly — uv emits a preview warning, which enabling the feature
silences.

### Available preview features

Examples from the current set (subject to change as features stabilize): `add-bounds`,
`json-output`, `package-conflicts`, `pylock`, `python-install-default`, `format`,
`index-exclude-newer`, `azure-endpoint`, `native-auth`, `auth-helper`, `workspace-metadata`,
`workspace-dir`, `workspace-list`, `target-workspace-discovery`, `project-directory-must-exist`,
and `malware-check`.

## Examples

```bash
# Enable a single feature for one command
uv run --preview-features json-output -- uv pip list --output-format json

# Enable via environment variable
UV_PREVIEW_FEATURES=pylock uv pip install -r pylock.toml

# Use a preview feature implicitly (warns), then silence the warning by enabling it
uv pip install -r pylock.toml
uv pip install --preview-features pylock -r pylock.toml
```

Enable in configuration:

```toml
# pyproject.toml ([tool.uv]) or uv.toml (no prefix)
[tool.uv]
preview-features = ["pylock", "json-output"]
```

## Caveats / Common Mistakes

- Preview features are unstable and subject to change or removal — do not depend on them in
  production without accepting that risk.
- Misspelling a feature name silently warns instead of failing, so a typo leaves the feature
  disabled without an obvious error.
- Features that take effect before configuration is loaded (e.g. `target-workspace-discovery`,
  `project-directory-must-exist`) cannot be enabled from `uv.toml`/`pyproject.toml` — use the flag
  or environment variable.

## See Also

- config-files
- config-env-vars
- concept-cache
- concept-resolution
