---
id: cmd-self
title: uv self — manage the uv executable
category: commands
tags: [command, installation]
source: https://docs.astral.sh/uv/reference/cli/#uv-self
related: [cmd-version, cmd-help, cmd-cache, ts-verbose-debugging, config-env-vars, config-installation]
---

## Summary

`uv self` is the subcommand group for managing the uv binary itself. It provides
`uv self update` to upgrade (or downgrade) the uv executable and `uv self version`
to display uv's own version string, including build commit and date.

## Syntax / Usage

```bash
uv self <COMMAND>

uv self update [OPTIONS] [TARGET_VERSION]
uv self version [OPTIONS]
```

## Details

### uv self update

Downloads and replaces the current uv binary with the requested release. When
`TARGET_VERSION` is omitted, uv updates to the latest available release. Passing an
older version installs that version instead (the output will say "Downgraded" rather
than "Upgraded").

Key options:

- `--dry-run` — resolve and report what would be updated without performing the
  replacement (added in 0.7.3).
- `--token <token>` / `UV_GITHUB_TOKEN` — a GitHub personal access token to reduce the
  likelihood of hitting GitHub API rate limits during the update check.
- `--offline` — exits early with an error when the global `--offline` flag is set,
  because a network fetch is required.

`uv self update` re-runs the installer, which may modify shell profiles to keep `PATH`
current. Set `UV_NO_MODIFY_PATH=1` to suppress profile modifications. When uv was
installed with `UV_UNMANAGED_INSTALL`, self-updates are disabled entirely.

Self-update is only available when uv was installed via the standalone installer
(`astral.sh/uv/install.sh` or `install.ps1`). When installed through pip, Homebrew,
pipx, Cargo, or another package manager, `uv self update` does nothing — use the
package manager's own upgrade mechanism instead.

### uv self version

Displays uv's version, build commit hash, and build date, for example:

```
uv 0.11.8 (abc1234de 2026-04-27)
```

Key options:

- `--short` — prints only the bare version number (e.g. `0.11.8`), without the build
  commit or date (added in 0.11.8).
- `--output-format` — controls the output format.

### Short-form aliases

`uv --version` produces the same output as `uv self version`. `uv -V` is the short
flag equivalent, but it does **not** include the build commit and date — it only
prints the version number.

### UV_INSTALL_DIR

The standalone installer respects `UV_INSTALL_DIR` to control where the uv binary
is placed (default: the user executable directory, typically `~/.local/bin` on Linux
and macOS). The `uv self update` command places the updated binary in the same
location the original was installed.

## Examples

```bash
# Update to the latest release
uv self update

# Preview what update would do, without applying it
uv self update --dry-run

# Pin to a specific version
uv self update 0.11.0

# Show the full version including build metadata
uv self version

# Show only the version number (for scripting)
uv self version --short

# Short-form flags (no build metadata)
uv --version
uv -V
```

## Caveats / Common Mistakes

- `uv self update` only works when uv was installed via the standalone installer. If
  you installed uv with `pip install uv`, `brew install uv`, or Cargo, the command
  silently does nothing — use your package manager's upgrade path.
- Before 0.7.0, `uv version` displayed uv's own version. In 0.7.0 that command was
  repurposed to display and bump the *project's* version (PEP 621 `version` field in
  `pyproject.toml`). The old behavior moved to `uv self version`. Running `uv version`
  outside a project prints a compatibility warning and falls back to `uv self version`,
  but this fallback will eventually be removed.
- `uv -V` (capital V) omits the build commit and date. Use `uv self version` or
  `uv --version` when you need full build metadata for a bug report.
- `UV_UNMANAGED_INSTALL` (used in CI to install to a custom path without modifying
  shell profiles) also disables self-updates.

## See Also

- cmd-version
- cmd-help
- cmd-cache
- ts-verbose-debugging
- config-env-vars
- config-installation
