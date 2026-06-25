---
id: tool-environments
title: Tool environments — ephemeral vs persistent, isolation, and Python version
category: tools
tags: [tool, venv, python, cache, installation]
source: https://docs.astral.sh/uv/concepts/tools/
related: [tool-run, tool-install, python-versions, concept-cache, tool-upgrade]
---

## Summary

uv creates two distinct types of virtual environments for tools: ephemeral environments (used by
`uvx`/`uv tool run`, stored in the cache) and persistent environments (used by `uv tool install`,
stored in the tools directory). Both are isolated from the current project and must not be mutated
directly.

## Details

### Ephemeral environments (`uvx` / `uv tool run`)

When a tool is run with `uvx` or `uv tool run`, uv creates a virtual environment in the **uv cache
directory** (e.g., `~/.cache/uv` on Linux/macOS). This environment is treated as disposable:

- It is cached to reduce overhead on repeated invocations.
- Running `uv cache clean` will delete it; uv recreates it automatically on the next invocation.
- The environment persists across shell sessions as long as the cache is intact.

### Persistent environments (`uv tool install`)

When a tool is installed with `uv tool install`, uv creates a virtual environment in the **uv tools
directory** (e.g., `~/.local/share/uv/tools/<tool-name>`). This environment:

- Survives until the tool is explicitly uninstalled with `uv tool uninstall`.
- If manually deleted, the tool executables will fail to run.
- Use `uv tool dir` to show the tools directory path; override with `UV_TOOL_DIR`.

### Isolation

Both environment types are isolated from the current project. Tool environments do not have access
to project packages and do not inherit project dependencies. For tools that need to see the project
(e.g., `pytest`, `mypy`), use `uv run` instead.

### No direct mutation

Tool environments are **not intended to be mutated directly**. Never run `pip install` or any other
package manager operation inside a tool environment. Doing so is unsupported and can break the
environment in unpredictable ways.

### Python version selection

Each tool environment is linked to a specific Python interpreter. The Python version discovery
follows the same logic as other uv virtual environments, with one important exception: **tool
environments ignore `.python-version` files and the `requires-python` value from any
`pyproject.toml`**. Only global Python version requests are considered.

Use `--python` to request a specific Python version explicitly:

```bash
uvx --python 3.11 ruff check .
uv tool install --python 3.11 ruff
uv tool upgrade --python 3.11 ruff
```

If the Python version used by a tool environment is later uninstalled, **the tool environment
breaks** and the tool may become unusable. Reinstall the tool to recover.

## Examples

```bash
# Ephemeral: environment cached in uv cache dir, removed by uv cache clean
uvx ruff check .

# Persistent: environment in tools dir, survives until uninstall
uv tool install ruff
uv tool dir                  # show tools directory (~/.local/share/uv/tools)

# Request a specific Python version for a tool environment
uv tool install --python 3.11 ruff

# Remove the ephemeral cache (all uvx environments are deleted)
uv cache clean

# Uninstall a persistent tool environment
uv tool uninstall ruff
```

## Caveats / Common Mistakes

- **Never mutate tool environments directly** (e.g., with `pip install`). Use `uv tool upgrade` or
  reinstall with `uv tool install` to add packages.
- **`.python-version` files are ignored** for tool environments. If you rely on a project-level
  `.python-version` file to pin Python, you must pass `--python` explicitly when running or
  installing tools.
- **`requires-python` in `pyproject.toml` is ignored** for tool environments.
- **Uninstalling the Python interpreter** used by a persistent tool environment will break the tool.
  Run `uv tool install <tool>` again to recreate the environment with an available interpreter.
- If an ephemeral environment is missing (e.g., after `uv cache clean`), uv recreates it
  automatically — no manual intervention required.

## See Also

- tool-run
- tool-install
- python-versions
- concept-cache
- tool-upgrade
