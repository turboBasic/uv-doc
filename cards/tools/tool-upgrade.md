---
id: tool-upgrade
title: uv tool upgrade — upgrading and reinstalling tools
category: tools
tags: [command, tool, installation]
source: https://docs.astral.sh/uv/reference/cli/#uv-tool-upgrade
related: [tool-install, tool-environments, tool-version-pinning, tool-list-uninstall, tool-run]
---

## Summary

`uv tool upgrade` upgrades the packages in a persistently installed tool environment.
Upgrades always respect the version constraints and settings that were provided at install
time; to change those constraints, re-run `uv tool install`.

## Syntax / Usage

```bash
uv tool upgrade <NAME>...              # upgrade all packages in the named tool env
uv tool upgrade --all                  # upgrade every installed tool
uv tool upgrade <NAME> --upgrade-package <PKG>   # upgrade one dependency within the env
uv tool upgrade <NAME> --reinstall               # force reinstall of all packages
uv tool upgrade <NAME> --reinstall-package <PKG> # force reinstall of one package
```

## Details

`uv tool upgrade` operates on tools that have been installed with `uv tool install`.
It re-resolves dependencies and updates packages within the tool's isolated virtual
environment.

**Version constraints are sticky.** If a tool was installed with
`uv tool install black >=23,<24`, running `uv tool upgrade black` will upgrade Black
only within that `>=23,<24` range. Constraints are not widened automatically.

**Settings are sticky.** Installation-time flags such as `--prerelease allow` or
`--python 3.11` are preserved across upgrades. A plain `uv tool upgrade` call
inherits all of them.

**Replace constraints with `uv tool install`.** To upgrade beyond the original
constraints, re-install the tool with new specifiers:

```console
$ uv tool install black>=24
```

**Upgrade a single dependency** in the environment with `--upgrade-package`. This is
useful when you want to bump only one transitive or extra dependency without touching
the rest:

```console
$ uv tool upgrade black --upgrade-package click
```

**Force reinstall** with `--reinstall` (all packages) or `--reinstall-package <pkg>`
(a single package). Both flags imply `--refresh` / `--refresh-package` respectively,
so the package index is re-queried:

```console
$ uv tool upgrade black --reinstall
$ uv tool upgrade black --reinstall-package click
```

**Note:** `uv tool upgrade` always reinstalls the tool executables even if no package
versions changed.

**Upgrade with a different Python version** using `--python`. Combined with `--all`, it
applies to every installed tool:

```console
$ uv tool upgrade ruff --python 3.12
$ uv tool upgrade --all --python 3.12
```

## Examples

```bash
# Upgrade ruff to the latest version allowed by its install-time constraints
uv tool upgrade ruff

# Upgrade every installed tool at once
uv tool upgrade --all

# Upgrade Black only within the >=23,<24 range it was installed with
uv tool install 'black>=23,<24'
uv tool upgrade black          # stays in >=23,<24

# Break out of that constraint by re-installing with a new specifier
uv tool install 'black>=24'

# Upgrade only the click dependency inside the black environment
uv tool upgrade black --upgrade-package click

# Force a clean reinstall of the entire black environment
uv tool upgrade black --reinstall

# Force reinstall of just one package in the black environment
uv tool upgrade black --reinstall-package platformdirs

# Upgrade ruff using Python 3.12 for its environment
uv tool upgrade ruff --python 3.12
```

## Caveats / Common Mistakes

- **Constraints are not widened on upgrade.** If a tool was pinned to `ruff>=0.3,<0.4`
  at install time, `uv tool upgrade ruff` will never install `ruff 0.4.x`. Use
  `uv tool install 'ruff>=0.4'` to change the constraint.
- **`--upgrade-package` is not in the CLI reference flags list** but is documented in
  the uv tools concept guide as the supported way to upgrade a single dependency within
  a tool environment.
- **Tool environments must not be mutated directly.** Do not run `pip install` or
  `pip upgrade` inside a tool environment; use `uv tool upgrade` or
  `uv tool install` instead.
- **`uv tool upgrade` only works on persistently installed tools.** Ephemeral `uvx`
  environments are upgraded by refreshing the cache (e.g., using `uvx <tool>@latest`).

## See Also

- tool-install
- tool-environments
- tool-version-pinning
- tool-list-uninstall
- tool-run
