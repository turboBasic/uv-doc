---
id: tool-with-from
title: Tool dependency options — --with, --from, and --with-executables-from
category: tools
tags: [tool, command, dependency, installation]
source: https://docs.astral.sh/uv/concepts/tools/
related: [tool-run, tool-install, tool-environments, dep-sources, dep-specifiers]
---

## Summary

`--with`/`-w` adds extra packages to a tool's isolated environment without exposing their executables; `--from` specifies which package provides the command when the package name differs from the command name (or to pin a version, extra, or git source); `--with-executables-from` is the install-only variant of `--with` that additionally links the sibling packages' executables onto `PATH`.

## Syntax / Usage

```bash
# --with / -w  (uvx and uv tool install)
uvx --with <extra-pkg> <tool>
uvx -w <extra-pkg> <tool>
uv tool install --with <extra-pkg> <tool-pkg>

# --from  (uvx only)
uvx --from <pkg-spec> <command>

# --with-executables-from  (uv tool install only)
uv tool install --with-executables-from <pkg1>,<pkg2> <tool-pkg>
```

## Details

### `--with` / `-w`

Installs one or more additional packages into the tool's environment alongside the tool itself. The flag may be repeated for multiple packages and accepts full package specifiers (including version constraints). Packages added with `--with` are treated as dependencies only — their own executables are **not** linked onto `PATH`.

When used with `uvx`, the extra packages are layered into the ephemeral environment for that single invocation. When used with `uv tool install`, they become part of the persistent tool environment and are retained across upgrades.

If a requested version conflicts with the tool package's own requirements, resolution will fail and the command will error.

### `--from`

By default uv infers the package name from the command name. `--from` overrides that inference to:

- Run a command whose name differs from its package (`http` is provided by `httpie`)
- Pin to a specific version using full PEP 508 syntax (`'ruff==0.3.0'`)
- Constrain to a version range (`'ruff>0.2.0,<0.3.0'`) — the `tool@version` shorthand only accepts exact versions
- Activate optional dependency groups (extras) on the package (`'mypy[faster-cache,reports]'`)
- Install from a git source (`git+https://github.com/httpie/cli`) at a branch, tag, or commit

`--from` is available for `uvx` / `uv tool run` but is not needed for `uv tool install`, which accepts a package specifier (including git URLs and version ranges) directly as the positional argument.

### `--with-executables-from`

An install-only option (`uv tool install`) that combines the behaviour of `--with` with executable linking. The specified packages are installed into the same tool environment **and** their executables are symlinked (Unix) or copied (Windows) into the tool executable directory, making them available on `PATH`. Executables from plain `--with` dependencies are never installed.

Multiple packages may be supplied as a comma-separated list or by repeating the flag, and it can be combined with `--with`.

Note that executables provided by *dependencies of* the packages specified with `--with-executables-from` are still not installed — only direct package executables are exposed.

## Examples

```bash
# Run mkdocs with the material theme plugin available
uvx --with mkdocs-material mkdocs build

# Shorthand -w flag, multiple packages
uvx -w requests -w rich httpie

# Command whose name differs from its package
uvx --from httpie http GET https://httpbin.org/get

# Pin an exact version via --from (full PEP 508 syntax)
uvx --from 'ruff==0.3.0' ruff check .

# Constrain to a version range (@ only supports exact pinning)
uvx --from 'ruff>0.2.0,<0.3.0' ruff check .

# Activate extras on the package
uvx --from 'mypy[faster-cache,reports]' mypy --xml-report mypy_report

# Install from a git repo at a specific tag
uvx --from git+https://github.com/httpie/cli@3.2.4 http

# Install from git at a specific commit
uvx --from git+https://github.com/httpie/cli@2843b87 http

# Install ansible with sibling executables from ansible-core and ansible-lint
uv tool install --with-executables-from ansible-core,ansible-lint ansible

# Combine --with-executables-from and --with
uv tool install --with-executables-from ansible-core --with mkdocs-material ansible

# Persistent install with an extra dependency (no executable linking)
uv tool install mkdocs --with mkdocs-material
```

## Caveats / Common Mistakes

- `--from` is **not** available for `uv tool install` — pass version constraints and git URLs directly as the package argument instead (e.g., `uv tool install 'httpie>0.1.0'` or `uv tool install git+https://github.com/httpie/cli`).
- `--with-executables-from` is only for `uv tool install`; there is no equivalent for `uvx` / `uv tool run`.
- Using `--with` never exposes the extra package's executables, even after `uv tool install`. Use `--with-executables-from` when you need those executables on `PATH`.
- Executables from *dependencies* of `--with-executables-from` packages are not installed — only executables belonging to the directly named packages.
- Version conflicts between `--with` packages and the main tool cause resolution failure and an error exit.
- The `tool@version` shorthand accepts exact versions only; for ranges or extras use `--from '<pkg-spec>'`.

## See Also

- tool-run
- tool-install
- tool-environments
- dep-sources
- dep-specifiers
