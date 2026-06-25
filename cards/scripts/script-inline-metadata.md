---
id: script-inline-metadata
title: Single-file scripts with PEP 723 inline metadata
category: scripts
tags: [script, dependency, python, command, lockfile]
source: https://docs.astral.sh/uv/guides/scripts/
related: [cmd-run, tool-run, dep-add, python-versions]
---

## Summary

uv runs standalone Python scripts and resolves their dependencies on the fly. Scripts
declare their requirements with a PEP 723 inline metadata block, so a single file is
fully self-describing — no project or manual virtualenv needed.

## Syntax / Usage

```bash
uv run <script.py>
uv init --script <script.py> --python 3.12
uv add --script <script.py> <packages>...
```

## Details

A PEP 723 metadata block is a comment fenced by `# /// script` and `# ///` containing
TOML. It can declare `dependencies` and `requires-python`. When a script has inline
metadata, `uv run` builds an isolated environment from exactly those dependencies and
ignores any surrounding project.

- `uv init --script example.py --python 3.12` scaffolds the block.
- `uv add --script example.py 'requests<3' rich` inserts dependencies into the block.
- `requires-python` makes uv fetch/use a matching interpreter automatically.
- `uv run --with <pkg> script.py` adds a dependency for one invocation without editing
  the script.
- `uv lock --script example.py` writes `example.py.lock` for reproducible runs.

A `uv run --script` shebang makes the file directly executable on Unix.

## Examples

A self-contained script:

```python
# /// script
# requires-python = ">=3.12"
# dependencies = [
#   "requests<3",
#   "rich",
# ]
# ///

import requests
from rich.pretty import pprint

resp = requests.get("https://peps.python.org/api/peps.json")
pprint(list(resp.json())[:10])
```

```bash
# Run it — uv resolves requests + rich automatically
uv run example.py

# Add a dependency to the block
uv add --script example.py httpx

# One-off dependency without editing the file
uv run --with rich example.py
```

Executable shebang script:

```python
#!/usr/bin/env -S uv run --script

print("Hello, world!")
```

## Caveats / Common Mistakes

- With inline metadata present, project dependencies are ignored — only the script's
  declared dependencies are installed.
- The block must use the exact `# /// script` … `# ///` fences; malformed fences are not
  recognized as metadata.

## See Also

- cmd-run
- tool-run
- dep-add
- python-versions
