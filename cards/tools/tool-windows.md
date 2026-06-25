---
id: tool-windows
title: Tool support on Windows — legacy scripts and PowerShell
category: tools
tags: [tool, installation, troubleshooting]
source: https://docs.astral.sh/uv/guides/tools/
related: [tool-run, tool-install, tool-bin-path, integration-docker, tool-environments]
---

## Summary

On Windows, uv tool executables are copied rather than symlinked, and uv supports legacy
setuptools scripts with `.ps1`, `.cmd`, and `.bat` extensions — including automatic extension
resolution when no extension is specified.

## Syntax / Usage

```powershell
# Explicit extension
uv tool run --from <pkg> <script>.cmd --version
uv tool run --from <pkg> <script>.ps1 --version
uv tool run --from <pkg> <script>.bat --version

# Extension omitted — uv resolves automatically
uv tool run --from <pkg> <script> --version
uvx --from <pkg> <script> --version
```

## Details

### Executables are copied, not symlinked

On Unix, `uv tool install` symlinks executables into the
[executable directory](https://docs.astral.sh/uv/reference/storage/#executable-directory).
On Windows, executables are **copied** instead because Windows does not support the same
symlink semantics.

### Legacy setuptools scripts

Tools packaged with legacy setuptools `scripts` (not `console_scripts` entry points) produce
`.ps1`, `.cmd`, and `.bat` wrappers in the tool's `Scripts` directory
(`$(uv tool dir)\<tool-name>\Scripts`). uv exposes these via `uvx` / `uv tool run`.

Supported extensions:

- `.ps1` — PowerShell script
- `.cmd` — Windows Command Prompt batch file
- `.bat` — legacy batch file

### Automatic extension resolution

When running a legacy script, you can omit the file extension. `uvx` searches the tool's
`Scripts` directory and resolves extensions in this order: `.ps1`, then `.cmd`, then `.bat`.
The first match is executed.

### Tool executable directory on Windows

The default executable directory on Windows follows the Known Folder scheme:

1. `%XDG_BIN_HOME%`
2. `%XDG_DATA_HOME%\..\bin`
3. `%USERPROFILE%\.local\bin`

Override it with the `UV_TOOL_BIN_DIR` environment variable.

## Examples

```powershell
# Run a legacy .cmd script explicitly
uv tool run --from nuitka==2.6.7 nuitka.cmd --version

# Same invocation without the extension — uv resolves .ps1 > .cmd > .bat
uv tool run --from nuitka==2.6.7 nuitka --version

# Short alias works the same way
uvx --from nuitka==2.6.7 nuitka --version
```

```dockerfile
# Docker / Windows-like setup: pin the tool bin directory to a known path
ENV UV_TOOL_BIN_DIR=/opt/uv-bin/
RUN uv tool install cowsay
ENV PATH=/opt/uv-bin:$PATH
```

## Caveats / Common Mistakes

- The automatic extension search order is `.ps1` first, then `.cmd`, then `.bat`. If a tool
  ships both `.ps1` and `.cmd` wrappers, the `.ps1` variant is selected unless you specify
  the extension explicitly.
- Because executables are copied (not symlinked) on Windows, upgrading a tool with
  `uv tool upgrade` reinstalls and re-copies all executables even if they have not changed.
- `UV_TOOL_BIN_DIR` overrides only the executable directory, not the tool environments
  directory. Use `UV_TOOL_DIR` to relocate the environments themselves.

## See Also

- tool-run
- tool-install
- tool-bin-path
- integration-docker
- tool-environments
