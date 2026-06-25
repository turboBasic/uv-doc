---
id: tool-version-pinning
title: Tool version pinning and caching behavior
category: tools
tags: [tool, cache, installation, command]
source: https://docs.astral.sh/uv/concepts/tools/
related: [tool-run, tool-upgrade, tool-install, tool-environments, concept-cache]
---

## Summary

`uvx` resolves and caches the latest version of a tool on first invocation, then reuses that cached
version on subsequent runs. Version specifiers, the `@latest` suffix, and `--isolated` give precise
control over which version is used.

## Syntax / Usage

```bash
uvx <tool>@<version>           # exact version, e.g. ruff@0.6.0
uvx <tool>@latest              # refresh cache to newest available
uvx --isolated <tool>          # ignore installed version; use cache (no refresh)
uvx --from '<pkg>>=X,<Y' <cmd> # PEP 508 range via --from
uv tool install <tool>@<version>
uv tool install <tool>@latest
uv tool install '<tool>>=X,<Y' # range constraint stored for future upgrades
```

## Details

**First-invocation caching.** When `uvx <tool>` is run without a version specifier, uv resolves
the latest available version and stores the resulting environment in the uv cache directory. Every
subsequent bare `uvx <tool>` call reuses that cached environment — it does not re-resolve, even if
a newer version has been released.

**`@version` suffix.** `uvx ruff@0.6.0` always resolves to that exact version. This is only valid
for exact versions; range constraints require `--from`.

**`@latest` suffix.** Appending `@latest` forces re-resolution against the index and refreshes the
cache entry. Use this to pick up a new release without pruning the entire cache.

**`--isolated` flag.** Runs the tool in a fresh temporary environment, bypassing any installed
(persistent) version. Critically, `--isolated` does *not* refresh the cache — it ignores the
installed version but still uses (or creates) a cached ephemeral env. Use `@latest` if you need
a version refresh.

**Interaction with `uv tool install`.** Once a tool is persistently installed via
`uv tool install`, a bare `uvx <tool>` will use the installed version instead of the cache. The
installed version takes precedence over the ephemeral cache. `uvx --isolated <tool>` overrides
this and falls back to the cache.

**PEP 508 range constraints with `--from`.** The `@` shorthand only accepts exact versions. For
range constraints, use `--from` with a PEP 508 specifier:

```bash
uvx --from 'ruff>0.2.0,<0.3.0' ruff check
```

**Range constraints for `uv tool install`.** Version ranges can be passed directly to
`uv tool install` as a package specifier. The constraint is stored and respected by future
`uv tool upgrade` invocations:

```bash
uv tool install 'ruff>=0.3,<0.4'
uv tool upgrade ruff   # stays within >=0.3,<0.4
```

To replace the stored constraint, reinstall with a new specifier:

```bash
uv tool install 'ruff>=0.4'
```

## Examples

```bash
# Run the cached version (resolved on first invocation)
uvx ruff check .

# Pin to an exact version
uvx ruff@0.6.0 --version

# Force-refresh the cache to the latest release
uvx ruff@latest --version

# Range constraint via --from (needed for non-exact specifiers with uvx)
uvx --from 'ruff>=0.5,<0.7' ruff check .

# Bypass an installed version but keep using the ephemeral cache
uvx --isolated ruff --version

# Install with an exact version
uv tool install ruff@0.6.0

# Install with the latest and refresh immediately
uv tool install ruff@latest

# Install with a range; upgrades will respect the range
uv tool install 'ruff>=0.3,<0.4'
uv tool upgrade ruff
```

## Caveats / Common Mistakes

- The `@` shorthand accepts only exact versions. `uvx ruff@>=0.3` is invalid — use
  `uvx --from 'ruff>=0.3' ruff` instead.
- `--isolated` does **not** pull a newer version; it only ignores the installed persistent tool.
  To get a newer version use `@latest` or `uv tool upgrade`.
- If `uv cache clean` removes the ephemeral environment, the next `uvx` invocation re-resolves
  from the index (which may produce a newer version than before the cache was cleared).
- A bare `uvx <tool>` after `uv tool install <tool>` runs the *installed* version, not the
  freshest cached one. This can cause confusion when testing a newer release with `uvx` after
  having an older version pinned via install.
- Tool environments must not be mutated with `pip` directly; use `uv tool install --with` or
  `uv tool upgrade` to add or update packages.

## See Also

- tool-run
- tool-upgrade
- tool-install
- tool-environments
- concept-cache
