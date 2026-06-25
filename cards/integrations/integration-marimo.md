---
id: integration-marimo
title: Using uv with marimo
category: integrations
tags: [integration, tool, script, venv, project]
source: https://docs.astral.sh/uv/guides/integration/marimo/
related: [script-inline-metadata, tool-run, cmd-venv, project-run, script-managing-deps]
---

## Summary

marimo notebooks are stored as pure Python scripts, enabling tight integration with uv across four
usage modes: standalone tool via `uvx`, self-contained scripts with PEP 723 inline metadata,
project-managed environments via `uv run`, and bare venvs managed through the pip-compatible interface.

## Syntax / Usage

```console
# Standalone: launch marimo in an isolated environment
$ uvx marimo edit
$ uvx marimo edit my_notebook.py

# Inline metadata: add a dependency to a notebook's script metadata
$ uv add --script my_notebook.py numpy

# Inline metadata: edit notebook in a sandbox environment
$ uvx marimo edit --sandbox my_notebook.py

# Project: run notebook with access to the project's venv
$ uv run marimo edit my_notebook.py

# Run any marimo notebook as a plain Python script
$ uv run my_notebook.py
```

## Details

**Standalone tool (`uvx marimo edit`):**
`uvx marimo edit` runs marimo in a temporary isolated environment without requiring any project or
venv. Useful for ad-hoc exploration. Provide a filename to open a specific notebook.

**Inline script metadata (`--sandbox`):**
Because marimo notebooks are stored as Python files, they support PEP 723 inline script metadata.
Use `uv add --script my_notebook.py <pkg>` to embed dependency declarations directly in the
notebook file. Then launch with `uvx marimo edit --sandbox my_notebook.py`; marimo will
automatically call uv to create an isolated venv from the embedded metadata. Packages installed
from the marimo UI while running in `--sandbox` mode are written back into the notebook's inline
metadata automatically.

**Within a project (`uv run marimo edit`):**
When marimo is listed as a project dependency, `uv run marimo edit my_notebook.py` starts a marimo
session with the project's `.venv` active. Adding packages via marimo's UI invokes `uv add` on your
behalf. If marimo is not a project dependency, use `uv run --with marimo marimo edit my_notebook.py`
to inject marimo without installing it into the project; however, packages installed via the marimo
UI in this mode are not persisted to `pyproject.toml` and may disappear on the next invocation.

**Non-project venv (`uv pip install`):**
Create a venv, install packages and marimo via the pip-compatible interface, then launch marimo
directly. marimo's UI will use `uv pip install` to add packages into the same venv.

**Running as a script:**
All marimo notebooks can be executed as plain Python scripts with `uv run my_notebook.py`,
regardless of how their dependencies are managed. This runs without opening an interactive browser
session.

## Examples

```console
# Ad-hoc: launch marimo in a throw-away environment
$ uvx marimo edit

# Self-contained notebook with inline deps
$ uvx marimo edit my_notebook.py               # create the file first
$ uv add --script my_notebook.py numpy polars  # embed deps in the file
$ uvx marimo edit --sandbox my_notebook.py     # open in isolated sandbox

# Project-based workflow (marimo is a project dep)
$ uv add --dev marimo
$ uv run marimo edit my_notebook.py

# Project-based workflow (marimo is NOT a project dep)
$ uv run --with marimo marimo edit my_notebook.py

# Non-project venv
$ uv venv
$ uv pip install numpy marimo
$ uv run marimo edit

# Execute notebook headlessly as a script
$ uv run my_notebook.py
```

## Caveats / Common Mistakes

- **`uv run --with marimo` does not persist UI-installed packages.** Packages added via marimo's
  package installer when running with `--with marimo` target a transient layer, not the project's
  `pyproject.toml`. Use `uv add` explicitly or add marimo as a proper project dependency instead.
- **`--sandbox` requires inline metadata to exist.** Running `uvx marimo edit --sandbox` on a
  notebook without any `# /// script` block still works but creates an empty environment; add
  metadata first with `uv add --script`.

## See Also

- script-inline-metadata
- script-managing-deps
- tool-run
- project-run
- cmd-venv
