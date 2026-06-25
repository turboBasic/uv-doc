---
id: ts-verbose-debugging
title: Using verbose output and version info to diagnose uv problems
category: troubleshooting
tags: [troubleshooting, command, config, python, performance]
source: https://docs.astral.sh/uv/getting-started/help/
related: [cmd-self, cmd-help, ts-resolution-conflict, ts-reproducible-examples, config-env-vars]
---

## Summary

When a uv command misbehaves, `-v` / `-vv` expose resolver decisions, cache hits, and
Python discovery details. Checking `uv self version` first confirms whether the problem
is already fixed in a newer release.

## Syntax / Usage

```bash
uv <command> -v          # verbose output (one level)
uv <command> -vv         # extra-verbose output (two levels)

uv self version          # full version string (includes build commit and date)
uv --version             # same output as `uv self version`
uv -V                    # short version number only (no build commit/date)

uv help                  # long help menu for uv (paged via less/more)
uv help <subcommand>     # long help menu for a specific subcommand
uv <command> --help      # condensed help (inline, no pager)
```

## Details

### Verbose flags

The `-v` flag can be passed to any uv command to enable verbose output. Repeating it
(`-vv`) increases verbosity further. Verbose output typically includes:

- Resolver decisions: why a particular version was selected or rejected
- Cache interactions: whether a cached wheel or metadata entry was used or bypassed
- Python discovery: which Python interpreters were found and which was chosen

Verbose logs are also recommended when filing a bug report: they can reveal differences
between environments that are not visible in the default output.

### Version identification

`uv self version` (introduced in uv 0.7.0) prints the installed uv version including
the build commit hash and release date. This is the preferred command for sharing
version information when seeking help.

`uv --version` and `uv -V` are aliases; `-V` omits the build commit and date, printing
only the version number.

Before uv 0.7.0, `uv version` served this purpose. As of 0.7.0, `uv version` was
repurposed to display or bump the *project's* version (requires a `pyproject.toml`).
Running `uv version` outside a project still falls back to showing the uv version with
a deprecation warning, but this fallback will be removed in a future release.

### Help menus

`uv <command> --help` displays a condensed help menu inline. `uv help <subcommand>`
displays the long help menu, paged through `less` or `more` (press `q` to exit). The
long menu includes all flags, including rarely-used ones omitted from the condensed view.

## Examples

Show resolver and cache detail while syncing:

```bash
uv sync -vv
```

Check the installed uv version before searching for a fix:

```bash
uv self version
# uv 0.7.3 (abc1234de 2025-05-10)
```

View all flags for `uv add` that are not shown in the condensed help:

```bash
uv help add
```

Collect verbose output for a script run to include in a bug report:

```bash
uv run -vv myscript.py 2>&1 | tee uv-debug.log
```

## Caveats / Common Mistakes

- `uv version` no longer reports the uv binary version inside a project directory as of
  0.7.0. Use `uv self version` (or `uv --version`) instead to avoid confusion with the
  project-version command.
- `-V` (capital V) omits the build commit and date; when sharing version info for a bug
  report, prefer `uv self version` or `uv --version` for the full string.
- Verbose output can include pre-signed upload URLs in older releases; uv 0.8.x and
  later redact these automatically.
- Docker-based reproductions are platform-specific: Docker images default to the host
  architecture, which may mask or introduce platform-dependent bugs. Pin the platform
  explicitly with `--platform linux/amd64` when cross-platform consistency matters.

## See Also

- cmd-self
- cmd-help
- ts-resolution-conflict
- ts-reproducible-examples
- config-env-vars
