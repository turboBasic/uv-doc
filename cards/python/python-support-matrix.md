---
id: python-support-matrix
title: Python version and implementation support tiers
category: python
tags: [python, installation, performance]
source: https://docs.astral.sh/uv/reference/policies/python/
related: [python-versions, python-distributions, python-variants, concept-platform-support, python-request-formats]
---

## Summary

uv classifies the Python versions and implementations it works with into support tiers
(Tier 1 "guaranteed to work", Tier 2 "expected to work", Tier 3 "should work"). The tier
tells you how thoroughly a given version or interpreter is tested before relying on it.

## Details

### Python version tiers

| Tier | Versions | Meaning |
|---|---|---|
| Tier 1 | 3.10, 3.11, 3.12, 3.13, 3.14 | Continuously tested; guaranteed to work. |
| Tier 2 | 3.6, 3.7, 3.8, 3.9 | Tested, but end-of-life and no longer receiving security fixes; not recommended. |
| Tier 2 | 3.15 pre-releases | Tested against pre-releases of the next version. |

uv does not work with Python versions prior to 3.6.

### Python implementation tiers

| Tier | Implementations | Managed installs |
|---|---|---|
| Tier 1 | CPython | Yes — builds maintained by Astral. |
| Tier 2 | PyPy, GraalPy, Pyodide | Managed installs available, but builds are **not** maintained by Astral. |
| Tier 3 | Pyston | "Should work"; stability may vary. No managed installs. |

Tier 1 implementations are guaranteed to work; Tier 2 are expected to work; Tier 3 should
work but stability varies. Note that managed-install availability is separate from
discovery — uv can also discover and use system interpreters of implementations it does not
build itself.

## Examples

```bash
# Tier 1 version — fully supported
uv python install 3.13

# Tier 2 (EOL) version — works but unsupported / insecure
uv python install 3.8

# Tier 2 implementation with a managed (non-Astral) build
uv python install pypy@3.10

# Pre-release of the next version (Tier 2)
uv python install 3.15
```

## Caveats / Common Mistakes

- Tier 2 versions 3.6–3.9 have reached end-of-life and receive no security fixes — uv tests
  them but does not recommend them for new work.
- Managed PyPy/GraalPy/Pyodide builds are not maintained by Astral, and these
  implementations are not auto-upgraded by `uv python upgrade` (see `python-distributions`).
- Pyston (Tier 3) has no managed installs; you must supply the interpreter yourself.

## See Also

- python-versions
- python-distributions
- python-variants
- concept-platform-support
- python-request-formats
