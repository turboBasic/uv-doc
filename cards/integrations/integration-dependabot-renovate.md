---
id: integration-dependabot-renovate
title: Automated Dependency Updates with Dependabot and Renovate
category: integrations
tags: [integration, dependency, lockfile, ci]
source: https://docs.astral.sh/uv/guides/integration/dependabot/
related: [concept-lockfile, script-inline-metadata, script-lockfile, config-resolution-settings, integration-github-actions]
---

## Summary

Both Dependabot and Renovate support uv, automating pull requests that keep `pyproject.toml`
and `uv.lock` in sync with the latest dependency releases. Each bot requires a small config
snippet; both need an alignment step if you use `exclude-newer`.

## Syntax / Usage

**Dependabot** (`dependabot.yml`):

```yaml
version: 2

updates:
  - package-ecosystem: "uv"
    directory: "/"
    schedule:
      interval: "weekly"
```

**Renovate** (`renovate.json5`):

```json5
{
  $schema: "https://docs.renovatebot.com/renovate-schema.json",
  lockFileMaintenance: {
    enabled: true,
  },
}
```

## Details

### Dependabot

Dependabot supports updating `uv.lock` files via `package-ecosystem: "uv"`. Partial support
exists — track [astral-sh/uv#2512](https://github.com/astral-sh/uv/issues/2512) for the
status of unresolved use cases.

**Dependency cooldown:** If `exclude-newer` is set in `uv.toml` or `pyproject.toml`, Dependabot
may open PRs that uv cannot lock (the candidate version is excluded). Align the two by setting
the `cooldown.default-days` option in `dependabot.yml` to the same duration.

### Renovate

Renovate detects uv projects by the presence of a `uv.lock` file. It updates both
`pyproject.toml` and `uv.lock` for project dependencies, optional dependencies, and
development dependencies.

**`lockFileMaintenance`:** Enables periodic full-lockfile refreshes (e.g., to update transitive
dependencies that have no direct version constraint change). Disabled by default.

**Inline script metadata (`pep723` manager):** Renovate can update PEP 723 inline dependency
declarations, but it cannot auto-discover which files contain them. Explicit paths must be
provided via `managerFilePatterns`.

**Dependency cooldown (`minimumReleaseAge`):** Same concern as Dependabot — if `exclude-newer`
is set, Renovate PRs may introduce versions uv rejects. Set `minimumReleaseAge` to match.
The option can be scoped to PyPI only via `packageRules.matchDatasources`, or applied globally.

## Examples

### Dependabot with cooldown

```yaml title="dependabot.yml"
version: 2

updates:
  - package-ecosystem: "uv"
    directory: "/"
    schedule:
      interval: "weekly"
    cooldown:
      default-days: 7
```

### Renovate with lockfile maintenance and inline script support

```json5 title="renovate.json5"
{
  $schema: "https://docs.renovatebot.com/renovate-schema.json",
  lockFileMaintenance: {
    enabled: true,
  },
  pep723: {
    managerFilePatterns: [
      "scripts/**/*.py",
    ],
  },
}
```

### Renovate with `minimumReleaseAge` aligned to `exclude-newer`

```json5 title="renovate.json5"
{
  $schema: "https://docs.renovatebot.com/renovate-schema.json",
  packageRules: [
    {
      matchDatasources: ["pypi"],
      minimumReleaseAge: "1 week",
    },
  ],
}
```

## Caveats / Common Mistakes

- **`exclude-newer` mismatch:** If `exclude-newer` is set in uv config but no cooldown/
  `minimumReleaseAge` is set in the bot config, the bot proposes a version that uv refuses
  to lock, causing the update PR to fail CI.
- **Dependabot partial support:** Not all uv use cases work with Dependabot yet. Check
  [#2512](https://github.com/astral-sh/uv/issues/2512) before relying on it for non-standard
  setups.
- **Renovate script lock files:** Renovate updates inline script metadata (`pep723` manager)
  but does **not** update the associated `.lock` file for scripts. That file must be regenerated
  manually with `uv lock` (tracked at [renovatebot/renovate#33591](https://github.com/renovatebot/renovate/issues/33591)).
- **Auto-discovery of scripts:** Renovate cannot auto-detect PEP 723 scripts; paths must be
  listed explicitly in `managerFilePatterns`.

## See Also

- concept-lockfile
- script-inline-metadata
- script-lockfile
- config-resolution-settings
- integration-github-actions
