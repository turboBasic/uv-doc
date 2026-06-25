---
id: ts-resolution-conflict
title: "No solution found" — resolving dependency conflicts
category: troubleshooting
tags: [troubleshooting, resolution, dependency, config, lockfile]
source: https://docs.astral.sh/uv/concepts/resolution/
related: [concept-lockfile, dep-add, config-files, pip-install]
---

## Summary

`uv lock` (or `uv pip compile`) fails with "No solution found" when requirements in the
dependency tree are mutually incompatible. uv prints the conflicting chain; you resolve
it by declaring conflicts, adding constraints, or overriding bad metadata.

## Syntax / Usage

```bash
uv lock                 # surfaces the conflict
uv lock --verbose       # more detail while debugging
```

## Details

The most common cause is two requirements demanding incompatible versions of the same
package. uv's error names the exact chain, e.g. `extra1` needs `numpy==2.1.2` while
`extra2` needs `numpy==2.0.0`.

Fixes, depending on the situation:

- **Declare conflicts** — when extras or groups legitimately cannot coexist, list them
  under `[tool.uv] conflicts`. Locking then succeeds, but the two cannot be installed
  together.
- **Constraints** — narrow acceptable versions of packages already pulled in, without
  adding them as dependencies (e.g. `uv pip compile --constraint constraints.txt`).
- **Overrides** — `[tool.uv] override-dependencies` *replaces* a package's declared
  requirements, to bypass incorrect upstream metadata (e.g. a dep that over-restricts
  `pydantic`).
- **Resolution strategy** — `--resolution lowest` / `lowest-direct` validates declared
  lower bounds (useful for libraries).
- **Pre-releases** — `--prerelease allow`, or add the package directly with a pre-release
  specifier, when a needed version is only pre-release.
- **`requires-python`** — universal resolution requires every package to be compatible
  with the whole declared range; an over-broad range can force the conflict.

## Examples

Conflict that fails:

```toml
[project.optional-dependencies]
extra1 = ["numpy==2.1.2"]
extra2 = ["numpy==2.0.0"]
```

Declare them as mutually exclusive:

```toml
[tool.uv]
conflicts = [
    [{ extra = "extra1" }, { extra = "extra2" }],
]
```

Override incorrect upstream metadata:

```toml
[tool.uv]
override-dependencies = ["pydantic>=1.0,<3"]
```

Validate lower bounds:

```bash
uv pip compile --resolution lowest-direct requirements.in
```

## Caveats / Common Mistakes

- Overrides *replace* all declared requirements for a package — they are blunt; prefer
  constraints when you only need to narrow, not rewrite.
- A too-wide `requires-python` can be the real culprit: tightening it often clears a
  conflict that looks like it comes from a dependency.

## See Also

- concept-lockfile
- dep-add
- config-files
- pip-install
