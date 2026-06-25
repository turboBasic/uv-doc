---
id: tool-list-uninstall
title: uv tool list and uv tool uninstall — inspecting and removing tools
category: tools
tags: [command, tool, installation]
source: https://docs.astral.sh/uv/reference/cli/#uv-tool-list
related: [tool-run, tool-install, tool-upgrade, tool-bin-path, tool-environments]
---

## Summary

`uv tool list` shows all persistently installed tools and their executables. `uv tool uninstall`
removes a tool and its isolated environment from disk.

## Syntax / Usage

```bash
uv tool list [OPTIONS]
uv tool uninstall [OPTIONS] <NAME>...
```

## Details

### uv tool list

`uv tool list` enumerates every tool installed via `uv tool install`, printing the tool name,
installed version, and its exposed executables.

Display flags that extend the default output:

| Flag | What it adds |
|---|---|
| `--outdated` | Queries the index for the latest version of each tool. Up-to-date tools are omitted; only tools with a newer available version are shown alongside their installed version. |
| `--show-paths` | Prints the path to each tool's isolated environment and each installed executable. |
| `--show-extras` | Shows the extras (e.g. `[server]`) that were activated when the tool was installed. |
| `--show-with` | Shows additional packages that were installed alongside the tool via `--with`. |
| `--show-python` | Shows the Python version linked to each tool environment. |
| `--show-version-specifiers` | Shows the version specifier(s) used when the tool was installed (e.g. `>=0.6,<1`). |

Flags can be combined freely: `uv tool list --outdated --show-paths`.

### uv tool uninstall

`uv tool uninstall <NAME>` removes the named tool: its isolated virtual environment is deleted
and its executables are removed from the tool bin directory. Multiple names can be passed in a
single invocation.

`--all` removes every installed tool in one operation.

## Examples

```bash
# List all installed tools (name, version, executables)
uv tool list

# Check which tools have a newer version available
uv tool list --outdated

# Show install paths and extra dependency details
uv tool list --show-paths --show-with --show-python

# Show version specifiers used at install time
uv tool list --show-version-specifiers

# Uninstall a single tool
uv tool uninstall ruff

# Uninstall multiple tools at once
uv tool uninstall ruff black

# Uninstall every installed tool
uv tool uninstall --all
```

## Caveats / Common Mistakes

- `--outdated` requires network access to query the index. Under `--offline` it is not usable.
- `uv tool list` only shows tools installed by `uv tool install`. Tools run ephemerally with
  `uvx`/`uv tool run` are cached but not listed here; they live in the uv cache directory and are
  cleaned by `uv cache clean`.
- Uninstalling a tool does not affect the uv cache. Ephemeral run environments remain in the cache
  until `uv cache clean` is run.
- If the Python version a tool was linked to is later uninstalled, the tool environment breaks. The
  fix is to reinstall the tool with `uv tool install`.

## See Also

- tool-run
- tool-install
- tool-upgrade
- tool-bin-path
- tool-environments
