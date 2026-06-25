---
id: script-reproducibility
title: Improving script reproducibility with exclude-newer
category: scripts
tags: [script, resolution, config, lockfile]
source: https://docs.astral.sh/uv/guides/scripts/
related: [script-inline-metadata, script-lockfile, config-resolution-settings, concept-resolution, cmd-lock]
---

## Summary

Embedding `exclude-newer` in a script's inline `[tool.uv]` section caps dependency
resolution to distributions uploaded before a given timestamp, making the script
produce the same dependency set regardless of when it is run in the future.

## Syntax / Usage

```toml
# Inside the # /// script ... # /// block:
[tool.uv]
exclude-newer = "2023-10-16T00:00:00Z"
```

## Details

`exclude-newer` is a uv resolution setting that filters candidate packages to those
whose distribution artifact was uploaded to the package index **before** the specified
date. The comparison is against the upload time of each individual artifact, not the
release date of the package version.

**Accepted formats** (all equivalent in effect; the timestamp form is most portable
inside inline metadata):

- RFC 3339 timestamp: `"2023-10-16T00:00:00Z"`
- "Friendly" duration (CLI/`uv.toml` only — not recommended in inline metadata):
  `"24 hours"`, `"1 week"`, `"30 days"`
- ISO 8601 duration: `"PT24H"`, `"P7D"`, `"P30D"`

Duration forms are resolved to a fixed number of seconds; DST transitions and
calendar units such as months or years are not supported.

**Disabling with `false`.** Set `exclude-newer = false` to explicitly remove a
constraint inherited from a parent config (e.g., a `uv.toml` that sets a global
cutoff). This is the only way to opt out of an inherited value from within inline
metadata.

**Interaction with `uv lock --script`.** When `uv lock --script example.py` is run,
the `exclude-newer` value embedded in the script's inline metadata is honoured during
resolution, so the resulting `.lock` file reflects the capped package universe. The
lockfile then pins exact versions, giving a second layer of reproducibility on top of
the timestamp cap.

**Scope.** The setting applies to all packages resolved for the script. To cap
individual packages to different dates (or exempt specific packages from a global
cutoff), use `exclude-newer-package` in `[tool.uv]` of a `pyproject.toml` or
`uv.toml` — that per-package form is not supported inside inline script metadata.

## Examples

Script pinned to the package universe as of a specific date:

```python
# /// script
# dependencies = [
#   "requests",
# ]
# [tool.uv]
# exclude-newer = "2023-10-16T00:00:00Z"
# ///

import requests

print(requests.__version__)
```

```bash
# Run with the capped universe
uv run example.py

# Lock the capped universe for repeatable installs
uv lock --script example.py
```

Disabling an inherited global cutoff for a specific script:

```python
# /// script
# dependencies = ["httpx"]
# [tool.uv]
# exclude-newer = false
# ///

import httpx
```

## Caveats / Common Mistakes

- The date is compared against **upload time**, not release date. A package version
  released before the cutoff may still be excluded if its specific wheel or sdist was
  uploaded after the cutoff.
- Duration forms (`"30 days"`, `"P7D"`) are relative to the time `uv` is invoked and
  will resolve to different points in time on different runs — they do not improve
  long-term reproducibility and should not be used for that purpose in inline metadata.
- `exclude-newer` does not lock exact versions by itself; combine it with
  `uv lock --script` to get a fully pinned lockfile.
- The per-package `exclude-newer-package` setting is only available in `pyproject.toml`
  or `uv.toml`, not inside PEP 723 inline script metadata.

## See Also

- script-inline-metadata
- script-lockfile
- config-resolution-settings
- concept-resolution
- cmd-lock
