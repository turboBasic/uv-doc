---
id: script-managing-deps
title: Managing script dependencies with uv init, add, and remove
category: scripts
tags: [script, dependency, command, python, index]
source: https://docs.astral.sh/uv/guides/scripts/
related: [script-inline-metadata, script-with-deps, script-lockfile, dep-add, config-package-indexes]
---

## Summary

`uv init --script`, `uv add --script`, and `uv remove --script` create and maintain PEP 723
inline metadata directly inside a script file, keeping dependencies co-located with the code
that needs them.

## Syntax / Usage

```bash
# Scaffold a new script with an inline metadata block
uv init --script <script.py>
uv init --script <script.py> --python 3.12
uv init --script <script.py> --bare

# Add one or more dependencies to a script
uv add --script <script.py> <package>...
uv add --script <script.py> --index <url> <package>...

# Remove a dependency from a script
uv remove --script <script.py> <package>...
```

## Details

### `uv init --script`

`uv init --script <path>` scaffolds a new standalone Python file with a PEP 723 metadata
block at the top. The path argument is required (unlike project init, which defaults to the
current directory).

By default, uv adds a `requires-python` constraint based on the system Python version. Pass
`--python <version>` to set an explicit version constraint instead — for example,
`--python 3.12` emits `requires-python = ">=3.12"`.

Pass `--bare` to produce a file that contains only the inline metadata header and no sample
code. Without `--bare`, uv generates a minimal script body in addition to the metadata block.

### `uv add --script`

`uv add --script <script.py> <packages>` inserts the specified PEP 508 requirements into the
script's `dependencies` array inside the `# /// script` block. If no such block exists, uv
creates one.

When a lockfile (`<script>.lock`) already exists, uv updates it to reflect the added
dependency. Subsequent `uv run --script` invocations reuse the locked resolution.

Pass `--index <url>` to embed an alternative package index in the inline metadata. The index
is written into a `[[tool.uv.index]]` section inside the script, so it is preserved for every
future run:

```python
# [[tool.uv.index]]
# url = "https://example.com/simple"
```

Multiple packages can be added in a single invocation. Version constraints follow PEP 508
syntax (e.g., `'requests<3'`).

### `uv remove --script`

`uv remove --script <script.py> <packages>` removes the named entries from the script's
`dependencies` array. If a lockfile is present it is updated in place. Requesting a package
that is not listed in the script's metadata causes uv to exit with an error.

## Examples

Create a new script targeting Python 3.12:

```bash
uv init --script fetch.py --python 3.12
```

The resulting file:

```python
# /// script
# requires-python = ">=3.12"
# dependencies = []
# ///
```

Create a script with only the metadata header (no sample body):

```bash
uv init --script fetch.py --python 3.12 --bare
```

Add dependencies to an existing script:

```bash
uv add --script fetch.py 'requests<3' rich
```

After the command the metadata block becomes:

```python
# /// script
# requires-python = ">=3.12"
# dependencies = [
#   "requests<3",
#   "rich",
# ]
# ///
```

Add a dependency from a private index and embed the index in the script:

```bash
uv add --index "https://pypi.example.com/simple" --script fetch.py internal-sdk
```

Remove a dependency:

```bash
uv remove --script fetch.py rich
```

Full workflow — scaffold, add deps, run:

```bash
uv init --script analyze.py --python 3.12
uv add --script analyze.py polars httpx
uv run analyze.py
```

## Caveats / Common Mistakes

- The path argument to `uv init --script` is required; unlike `uv init` for projects it does
  not default to the current directory.
- `uv init --script` will exit with an error if the target file already exists.
- `dependencies = []` must be present in the metadata block even if the list is empty;
  `uv run` requires the field to recognize the block as valid PEP 723 metadata.
- `uv remove --script` exits with an error if the requested package is not found in the
  script's metadata — it does not silently succeed.
- `--index` on `uv add --script` is written into the script's `[tool.uv]` section as
  `[[tool.uv.index]]`; this index applies only to this script's own resolution, not to any
  surrounding project.

## See Also

- script-inline-metadata
- script-with-deps
- script-lockfile
- dep-add
- config-package-indexes
