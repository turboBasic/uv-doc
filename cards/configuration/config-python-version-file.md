---
id: config-python-version-file
title: .python-version file — pinning the default Python version
category: configuration
tags: [config, python, project]
source: https://docs.astral.sh/uv/concepts/python-versions/#python-version-files
related: [python-pin, python-request-formats, config-python-discovery, config-files, python-versions]
---

## Summary

`.python-version` (and `.python-versions` for multi-version projects) tells uv which
Python version to use by default, without requiring `--python` on every command. uv
discovers the file by walking up from the working directory and also checks the user
configuration directory as a global fallback.

## Syntax / Usage

Create or update the local pin:

```bash
uv python pin [REQUEST]
```

Create or update the global (user-level) pin:

```bash
uv python pin --global [REQUEST]
```

Read back the current pin (no argument):

```bash
uv python pin
```

Remove the pin:

```bash
uv python pin --rm
```

## Details

### File format

`.python-version` contains a single Python version request on one line. Any
[request format](https://docs.astral.sh/uv/concepts/python-versions/#requesting-a-version)
is valid — e.g., `3.12`, `3.12.3`, `cpython@3.12`, `>=3.12,<3.13` — but plain version
numbers (e.g., `3.12`) are recommended for interoperability with pyenv and mise, which
read the same file but support fewer formats.

`.python-versions` (plural) lists one request per line and is used when a project needs
multiple Python versions, for example to drive `uv python install` across a test matrix.
`uv python install` (with no arguments) installs all versions listed in the file.

### Discovery order

1. Working directory.
2. Each parent directory, walking upward.
3. uv stops at a project or workspace root — it does not cross workspace boundaries
   when searching parent directories.
4. If no file is found within the project tree, the user configuration directory is
   checked: `$XDG_CONFIG_HOME/uv` (Linux/macOS) or `%APPDATA%\uv` (Windows).

### Creating the file

`uv python pin <REQUEST>` writes `.python-version` in the current directory.
`uv python pin --global <REQUEST>` writes to the user configuration directory, acting
as a machine-wide default when no project-local pin exists.

By default, `uv init` creates a `.python-version` file alongside the new project. Pass
`--no-pin-python` to suppress this.

### Validation against `requires-python`

When a project or workspace is discovered, `uv python pin` validates that the pinned
version satisfies the workspace's `requires-python` constraint. Use `--no-project`
(`--no-workspace`) to skip this validation.

### `--resolved` flag

`uv python pin --resolved` writes the absolute interpreter path instead of the version
request. This locks the environment to one specific binary but is generally not suitable
for committing to version control.

### Interaction with `--no-config`

Passing `--no-config` to any uv command disables discovery of `.python-version` files
entirely, in addition to suppressing `pyproject.toml` and `uv.toml` discovery.

## Examples

```bash
# Pin the project to Python 3.12
uv python pin 3.12
# → Pinned `.python-version` to `3.12`

# Pin globally so all projects without a local pin use 3.11
uv python pin --global 3.11

# Show the currently pinned version
uv python pin
# → 3.12

# Remove the local pin
uv python pin --rm

# Run uv sync without reading any .python-version file
uv sync --no-config
```

`.python-versions` for a project that tests against multiple versions:

```text
3.12
3.11
3.10
```

```bash
# Install all versions listed in .python-versions
uv python install
```

## Caveats / Common Mistakes

- **Format interoperability**: uv supports richer request formats (e.g.,
  `cpython@3.12`, version specifiers) than pyenv or mise. If the `.python-version`
  file is shared with those tools, use only a plain version number such as `3.12`.
- **Workspace boundary**: uv stops searching for `.python-version` at the workspace
  root. A file in a parent directory above the workspace root is ignored (the global
  user config directory is the only out-of-project fallback).
- **`--resolved` in version control**: Writing the resolved interpreter path with
  `--resolved` embeds a machine-specific absolute path. Committing that file will
  likely break other contributors' environments.
- **`uv tool` ignores local pins**: `uv tool run` / `uvx` respect only the global
  `.python-version` file, not project-local ones.

## See Also

- python-pin
- python-request-formats
- config-python-discovery
- config-files
- python-versions
