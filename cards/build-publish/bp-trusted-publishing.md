---
id: bp-trusted-publishing
title: Trusted publishing in CI (GitHub Actions, GitLab CI)
category: build-publish
tags: [publish, ci, authentication, integration, build]
source: https://docs.astral.sh/uv/guides/integration/github/#publishing-to-pypi
related: [bp-build-publish, integration-github-actions, integration-gitlab-ci, bp-publish-attestations, config-index-auth]
---

## Summary

Trusted publishing lets `uv publish` upload to PyPI from CI without storing any credentials,
using OIDC tokens issued by the CI platform (GitHub Actions or GitLab CI/CD).

## Syntax / Usage

```bash
uv publish                          # automatic mode (default) — uses OIDC when available
uv publish --trusted-publishing always   # require OIDC; fail if not available
uv publish --trusted-publishing never    # skip OIDC; fall back to token/password
```

## Details

`uv publish` supports three trusted-publishing modes controlled by `--trusted-publishing`:

- `automatic` (default): attempt OIDC when running in a supported environment; continue
  with token/password if it fails or is not configured.
- `always`: require OIDC; error if the environment does not support it or PyPI rejects it.
- `never`: disable OIDC entirely; authenticate only with `--token` / `UV_PUBLISH_TOKEN`.

The setting can also be placed in `pyproject.toml` or `uv.toml` under `[tool.uv]`:

```toml
[tool.uv]
trusted-publishing = "always"
```

Supported CI environments are **GitHub Actions** and **GitLab CI/CD**.

### GitHub Actions requirements

The job must hold the `id-token: write` permission so the runner can request an OIDC token
from GitHub. Without it, the token request is rejected and uv will fall back (in `automatic`
mode) or error (in `always` mode).

### PyPI project setup

Before the first trusted-publisher upload, register the publisher in the PyPI project
settings under **Publishing**. For a GitHub Actions publisher, the required fields are:

- Owner (GitHub organisation or user)
- Repository name
- Workflow file name (e.g. `release.yml`)
- Environment name (must match the `environment:` field in the workflow job)

### GitLab CI/CD

GitLab CI/CD is also a supported environment. uv detects it automatically; no extra
`--trusted-publishing` flag is needed beyond the default `automatic` mode. Configure
a corresponding trusted publisher in PyPI pointing at the GitLab project.

## Examples

### Full GitHub Actions release workflow

```yaml
# .github/workflows/release.yml
name: "Publish release to PyPI"

on:
  push:
    tags:
      - v*

jobs:
  run:
    runs-on: ubuntu-latest
    environment:
      name: pypi
    permissions:
      id-token: write
      contents: read
    steps:
      - name: Checkout
        uses: actions/checkout@v6
      - name: Install uv
        uses: astral-sh/setup-uv@08807647e7069bb48b6ef5acd8ec9567f424441b # v8.1.0
      - name: Install Python 3.13
        run: uv python install 3.13
      - name: Build
        run: uv build
      # Optional: verify the built artifacts work before publishing
      - name: Smoke test (wheel)
        run: uv run --isolated --no-project --with dist/*.whl tests/smoke_test.py
      - name: Smoke test (source distribution)
        run: uv run --isolated --no-project --with dist/*.tar.gz tests/smoke_test.py
      - name: Publish
        run: uv publish
```

Trigger with a version tag:

```bash
git tag -a v0.1.0 -m v0.1.0
git push --tags
```

### Force OIDC (fail fast if misconfigured)

```bash
uv publish --trusted-publishing always
```

### Opt out of OIDC (use an explicit token)

```bash
uv publish --trusted-publishing never --token "$UV_PUBLISH_TOKEN"
```

## Caveats / Common Mistakes

- The job **must** declare `permissions: id-token: write`. Omitting it silently prevents
  token issuance; uv will hint about the missing permission in its error output.
- The `environment:` name in the workflow job must **exactly** match the environment name
  registered as a trusted publisher in PyPI.
- `uv publish` must be run from a checkout so that `pyproject.toml` is present when
  using `--index <name>` (the index URL is read from the file).
- Third-party or self-hosted indexes may not support OIDC. Use
  `--trusted-publishing never` and a token for those targets.
- When using `automatic` mode outside a supported environment (e.g. a local workstation),
  uv silently skips OIDC and requires `--token` or `UV_PUBLISH_TOKEN`.

## See Also

- bp-build-publish
- integration-github-actions
- integration-gitlab-ci
- bp-publish-attestations
- config-index-auth
