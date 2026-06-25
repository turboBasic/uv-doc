---
id: bp-build-publish
title: Building and publishing packages (uv build / uv publish)
category: build-publish
tags: [command, build, publish, index, config]
source: https://docs.astral.sh/uv/guides/package/
related: [config-files, dep-add, project-structure, integration-docker]
---

## Summary

`uv build` produces a source distribution and wheel from a project; `uv publish` uploads
them to PyPI or another index. Together they cover the package release workflow.

## Syntax / Usage

```bash
uv build [SRC]
uv publish [--index <name>] [--token <token>]
```

## Details

`uv build` writes an sdist and a wheel into `dist/`. Build a specific workspace package
with `--package <name>`, or a different source directory with `uv build <SRC>`. Before a
release, run `uv build --no-sources` to confirm the package builds without
`[tool.uv.sources]`, matching how other tools see it.

The project should declare a `[build-system]`; uv strongly recommends configuring one
(e.g. its native `uv_build` backend or `hatchling`). Without it, uv falls back to legacy
setuptools.

Versioning: `uv version 1.0.0` sets an explicit version; `uv version --bump minor` bumps
semantically; `--dry-run` previews the change.

`uv publish` authenticates via a PyPI token (`--token` or `UV_PUBLISH_TOKEN`), or via
trusted publishing in CI (no stored credentials). Custom indexes are configured in
`pyproject.toml` with a `publish-url`, then targeted with `uv publish --index <name>`.
After publishing, verify with
`uv run --with <package> --no-project -- python -c "import <package>"`.

## Examples

```bash
# Build sdist + wheel into dist/
uv build

# Verify it builds without uv-specific sources
uv build --no-sources

# Bump version, then publish to PyPI with a token
uv version --bump minor
uv publish --token "$UV_PUBLISH_TOKEN"
```

Custom index in `pyproject.toml`:

```toml
[[tool.uv.index]]
name = "testpypi"
url = "https://test.pypi.org/simple/"
publish-url = "https://test.pypi.org/legacy/"
```

```bash
uv publish --index testpypi
```

## Caveats / Common Mistakes

- Always test with `uv build --no-sources` before release — `[tool.uv.sources]` is
  uv-only and absent for consumers installing from the index.
- Configure a `[build-system]`; relying on the legacy setuptools fallback is discouraged.

## See Also

- config-files
- dep-add
- project-structure
- integration-docker
