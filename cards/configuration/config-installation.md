---
id: config-installation
title: Installing, upgrading, and uninstalling uv
category: configuration
tags: [installation, config]
source: https://docs.astral.sh/uv/getting-started/installation/
related: [cmd-self, config-env-vars, python-storage, integration-docker, concept-platform-support]
---

## Summary

uv can be installed via a standalone installer (the recommended method, which enables
`uv self update`) or through a package manager. The installer's path and shell-profile
behavior are controlled by environment variables, and uv stores data separately from the
binary, so a full uninstall has two parts.

## Syntax / Usage

```bash
# Standalone installer (macOS / Linux)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Standalone installer (Windows PowerShell)
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

## Details

### Standalone installer

The standalone installer downloads a prebuilt binary. On macOS/Linux use `curl` (or
`wget -qO-` if `curl` is absent); on Windows use `irm ... | iex`. Pin a specific version
by embedding it in the URL, e.g. `https://astral.sh/uv/0.11.24/install.sh`. Inspect the
script before running by piping to `less` / `more` instead of the shell.

Installing via the standalone installer is what enables self-updates (see `cmd-self`).

### Package managers

| Method | Command |
|---|---|
| PyPI (isolated, recommended) | `pipx install uv` |
| PyPI (pip) | `pip install uv` |
| Homebrew | `brew install uv` |
| MacPorts | `sudo port install uv` |
| WinGet | `winget install --id=astral-sh.uv -e` |
| Scoop | `scoop install main/uv` |
| Cargo (builds from source) | `cargo install --locked uv` |

uv is also published as a Docker image at `ghcr.io/astral-sh/uv` (see `integration-docker`),
and release artifacts are downloadable directly from GitHub Releases. uv ships prebuilt
wheels for many platforms; where no wheel exists, PyPI/Cargo installs build from source and
require a Rust toolchain.

### Installer environment variables

The standalone installer reads several environment variables (pass them via `env` when
piping the script):

- `UV_INSTALL_DIR` — change where the `uv`/`uvx` binaries are placed. This affects only the
  binary location; cache, Python, and tool data still use their default directories.
- `UV_NO_MODIFY_PATH=1` — prevent the installer from editing shell profiles. The setting
  persists, so later `uv self update` runs also leave profiles untouched.
- `UV_UNMANAGED_INSTALL="/path"` — for ephemeral environments like CI: install to a fixed
  path without modifying profiles or environment variables. This also disables self-updates.

Options can also be passed directly to the script after `-s --`, e.g.
`curl -LsSf https://astral.sh/uv/install.sh | sh -s -- --help`. Using environment variables
is recommended because they are consistent across platforms.

### Upgrading

When uv was installed via the standalone installer, upgrade it in place with
`uv self update`. With any other installation method self-updates are disabled — use the
package manager's own upgrade path (e.g. `pip install --upgrade uv`,
`brew upgrade uv`). See `cmd-self` for details and the `--dry-run` / target-version options.

### Shell autocompletion

Generate completion scripts with `uv generate-shell-completion <shell>` (bash, zsh, fish,
elvish, powershell). For uvx, use `uvx --generate-shell-completion <shell>`. Append the
appropriate `eval`/`source` line to your shell config, then restart the shell.

### Uninstalling

uv stores data separately from its binary, so removal is two steps. Optionally clear stored
data first, then remove the binaries:

```bash
uv cache clean
rm -r "$(uv python dir)"
rm -r "$(uv tool dir)"
rm ~/.local/bin/uv ~/.local/bin/uvx
```

## Examples

```bash
# Install a specific pinned version
curl -LsSf https://astral.sh/uv/0.11.24/install.sh | sh

# Install to a custom directory without touching shell profiles
curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="$HOME/.local/uv" UV_NO_MODIFY_PATH=1 sh

# Unmanaged CI install (no profile changes, self-update disabled)
curl -LsSf https://astral.sh/uv/install.sh | env UV_UNMANAGED_INSTALL="/opt/uv" sh

# Enable zsh autocompletion for uv and uvx
echo 'eval "$(uv generate-shell-completion zsh)"' >> ~/.zshrc
echo 'eval "$(uvx --generate-shell-completion zsh)"' >> ~/.zshrc

# Upgrade (standalone installer only)
uv self update
```

## Caveats / Common Mistakes

- `uv self update` only works for standalone-installer installs. With pip/Homebrew/Cargo it
  does nothing — upgrade through the package manager instead.
- `UV_INSTALL_DIR` relocates the binary only, not uv's data (cache, Python, tools). To move
  data, set the corresponding storage variables (see `python-storage`, `config-env-vars`).
- `UV_UNMANAGED_INSTALL` disables self-updates as a side effect — intended for CI, not daily
  use.
- Prior to 0.5.0, uv was installed into `~/.cargo/bin`. Upgrading does not remove the old
  binary there; delete it manually if uninstalling.

## See Also

- cmd-self
- config-env-vars
- python-storage
- integration-docker
- concept-platform-support
