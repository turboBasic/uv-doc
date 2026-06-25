---
id: tool-run
title: uvx and uv tool — run and install CLI tools
category: tools
tags: [command, tool, installation, venv]
source: https://docs.astral.sh/uv/concepts/tools/
related: [cmd-run, script-inline-metadata, python-versions, pip-install]
---

## Summary

uv runs Python command-line tools in isolated environments, separate from any project.
`uvx` runs a tool ephemerally; `uv tool install` installs it persistently onto your PATH.
This is uv's replacement for pipx.

## Syntax / Usage

```bash
uvx <tool> [ARGS]              # == uv tool run <tool>
uv tool install <tool>
uv tool list
uv tool upgrade <tool>
uv tool uninstall <tool>
```

## Details

`uvx` and `uv tool run` are equivalent — `uvx` is the short alias. They execute a tool in
a temporary, cached environment that is removed by `uv cache clean`. Tools run isolated
from the project by default.

`uv tool install` creates a persistent environment in uv's tools directory and links the
executables onto your PATH. Ensure the bin directory is on PATH with
`uv tool update-shell`.

Version and dependency control:

- `<tool>@<version>` pins a version: `uvx ruff@0.6.0`.
- `<tool>@latest` refreshes to the newest: `uvx ruff@latest`.
- `--with <pkg>` adds extra packages to the environment.
- `--from <pkg>` runs a command whose name differs from the package, or pins the source
  package.
- `--isolated` bypasses an already-installed tool.
- `--with-executables-from <pkgs>` (install) also exposes those packages' executables.

To run a tool that should see your *project* (like `pytest` or `mypy`), use `uv run`
instead of `uvx`.

## Examples

```bash
# One-off run in an ephemeral env
uvx ruff check .

# Pin a version / force latest
uvx ruff@0.6.0 --version
uvx ruff@latest --version

# Extra dependency for the run
uvx --with requests-mock pytest

# Persistent install onto PATH
uv tool install ruff
uv tool update-shell

# Command name differs from the package
uvx --from httpie http GET example.com
```

## Caveats / Common Mistakes

- `uvx`/`uv tool` environments are isolated from your project — for project-aware tools
  (pytest, mypy) reach for `uv run`.
- After `uv tool install`, if the command "isn't found", run `uv tool update-shell` and
  restart your shell to put the tool bin directory on PATH.

## See Also

- cmd-run
- script-inline-metadata
- python-versions
- pip-install
