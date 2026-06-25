---
id: bp-publish-custom-index
title: Publishing to custom and private indexes
category: build-publish
tags: [publish, index, authentication, config, build]
source: https://docs.astral.sh/uv/guides/package/#publishing-your-package
related: [bp-build-publish, config-package-indexes, config-index-auth, bp-trusted-publishing, integration-private-indexes]
---

## Summary

`uv publish` can target any index — TestPyPI, JFrog Artifactory, a corporate private
registry — by configuring `publish-url` on a named `[[tool.uv.index]]` entry and
passing `--index <name>`, or by supplying `--publish-url` directly on the command line.

## Syntax / Usage

```bash
# Target a named index configured in pyproject.toml
uv publish --index <name>

# Supply publish URL directly (no pyproject.toml required)
uv publish --publish-url <url>

# With retry idempotency for non-PyPI registries
uv publish --publish-url <url> --check-url <simple-index-url>

# Authentication via flags
uv publish --index <name> --token <token>
uv publish --index <name> --username <user> --password <pass>
```

## Details

### Configuring a named index with publish-url

Add `publish-url` to a `[[tool.uv.index]]` entry. The `url` field is the Simple API
URL used for resolution and for `--check-url` deduplication; `publish-url` is the
upload endpoint.

```toml
[[tool.uv.index]]
name = "testpypi"
url = "https://test.pypi.org/simple/"
publish-url = "https://test.pypi.org/legacy/"
explicit = true
```

When `--index <name>` is used, uv automatically derives the check URL from the index
`url`, so the following two calls are equivalent:

```shell
uv publish --index testpypi
uv publish --publish-url https://test.pypi.org/legacy/ --check-url https://test.pypi.org/simple/
```

Note: `--index` requires `pyproject.toml` to be present (a checkout step is needed in
CI publish jobs).

### Using --publish-url without a config file

When no `pyproject.toml` is available, pass the upload endpoint directly. The default
publish URL is `https://upload.pypi.org/legacy/`. The `UV_PUBLISH_URL` environment
variable sets the same value.

### --check-url for retry idempotency

PyPI accepts re-uploading an identical file, so a partial publish can simply be
retried. Most other registries return an error on duplicate upload. Pass
`--check-url <simple-index-url>` to make uv skip files that already exist in the
index (matched by hash — SHA-256, SHA-384, or SHA-512 must be provided by the index).
This also handles the case of a parallel upload racing the same file.

`UV_PUBLISH_CHECK_URL` sets this via environment variable.

### Authentication

Three mutually usable mechanisms, in preference order for most registries:

| Mechanism | Flag | Env var |
|---|---|---|
| API token | `--token` / `-t` | `UV_PUBLISH_TOKEN` |
| Username + password | `--username` / `-u` and `--password` / `-p` | `UV_PUBLISH_USERNAME` and `UV_PUBLISH_PASSWORD` |
| Trusted publishing (CI) | `--trusted-publishing` | — |

A token is equivalent to `--username __token__ --password <token>`. PyPI no longer
accepts plain username/password; a token is required.

For trusted publishing (GitHub Actions, GitLab CI/CD) uv automatically detects the
environment and requests an OIDC token — no stored credentials needed. Set
`--trusted-publishing never` to disable auto-detection.

### Preventing accidental publish to PyPI

Mark internal packages with the `Private :: Do Not Upload` trove classifier. PyPI
rejects uploads containing this classifier; it has no effect on alternative registries.

```toml
[project]
classifiers = ["Private :: Do Not Upload"]
```

## Examples

**TestPyPI with a named index:**

```toml
# pyproject.toml
[[tool.uv.index]]
name = "testpypi"
url = "https://test.pypi.org/simple/"
publish-url = "https://test.pypi.org/legacy/"
explicit = true
```

```bash
UV_PUBLISH_TOKEN="$TEST_PYPI_TOKEN" uv publish --index testpypi
```

**JFrog / private registry with username and password:**

```toml
[[tool.uv.index]]
name = "artifactory"
url = "https://mycompany.jfrog.io/artifactory/api/pypi/pypi-local/simple/"
publish-url = "https://mycompany.jfrog.io/artifactory/api/pypi/pypi-local/"
explicit = true
```

```bash
uv publish --index artifactory \
  --username "$JFROG_USER" \
  --password "$JFROG_TOKEN" \
  --check-url https://mycompany.jfrog.io/artifactory/api/pypi/pypi-local/simple/
```

Note: when using `--index`, `--check-url` is derived automatically from the index `url`
and does not need to be passed separately.

**Publish without a config file (ad-hoc):**

```bash
uv publish dist/* \
  --publish-url https://upload.pypi.org/legacy/ \
  --token "$PYPI_TOKEN"
```

**Prevent accidental upload of an internal package:**

```toml
[project]
name = "internal-utils"
classifiers = ["Private :: Do Not Upload"]
```

## Caveats / Common Mistakes

- `--index <name>` requires the named index to be defined in `pyproject.toml` with a
  `publish-url`; it cannot be an index supplied only via CLI or env var.
- Do not use `--index` and `--publish-url` together — they are mutually exclusive
  ways to specify the publish destination.
- Most non-PyPI registries reject re-uploading a file even if it is identical; always
  use `--check-url` (or `--index`, which implies it) when retrying a partial publish.
- The `Private :: Do Not Upload` classifier blocks PyPI only; it does not prevent
  upload to private registries.
- Attestations are uploaded by default; some third-party indexes may reject uploads
  that include attestation files. Use `--no-attestations` or `UV_PUBLISH_NO_ATTESTATIONS`
  if you encounter errors on non-PyPI registries.

## See Also

- bp-build-publish
- config-package-indexes
- config-index-auth
- bp-trusted-publishing
- integration-private-indexes
