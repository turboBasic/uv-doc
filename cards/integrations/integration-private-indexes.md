---
id: integration-private-indexes
title: Using uv with Private Package Indexes
category: integrations
tags: [integration, index, authentication, publish, config]
source: https://docs.astral.sh/uv/guides/integration/aws/
related: [config-index-auth, config-package-indexes, bp-publish-custom-index, ts-auth-network, bp-build-publish]
---

## Summary

uv supports installing from and publishing to private registries on AWS CodeArtifact, Azure
Artifacts, Google Artifact Registry, and JFrog Artifactory. Each registry uses the same
`UV_INDEX_<NAME>_USERNAME/PASSWORD` pattern with a registry-specific required username.

## Syntax / Usage

```toml
# pyproject.toml — declare the private index
[[tool.uv.index]]
name = "private-registry"
url  = "https://<registry-host>/simple/"
publish-url = "https://<registry-host>/"   # only needed for uv publish
```

```bash
# Supply credentials (index name uppercased, non-alphanumeric → underscore)
export UV_INDEX_PRIVATE_REGISTRY_USERNAME=<username>
export UV_INDEX_PRIVATE_REGISTRY_PASSWORD=<token>

uv sync
uv publish --index private-registry
```

## Details

All four registries share the same wiring pattern:

1. Declare the index in `pyproject.toml` (or `uv.toml`) with a `name`.
2. Export `UV_INDEX_<NAME>_USERNAME` and `UV_INDEX_<NAME>_PASSWORD` (uppercase the name,
   replace non-alphanumeric characters with underscores).
3. Optionally use the `keyring` subprocess provider instead of explicit tokens.

For `uv publish`, add a `publish-url` to the index entry and set `UV_PUBLISH_USERNAME` /
`UV_PUBLISH_PASSWORD` (these do **not** include the index name in the variable name).

### AWS CodeArtifact

- Required username: **`aws`** (hardcoded by the service; any other value fails auth).
- Token is short-lived; generate it with `aws codeartifact get-authorization-token`.
- Keyring plugin: `keyrings.codeartifact` — wraps boto3, handles token refresh automatically.

```bash
export AWS_CODEARTIFACT_TOKEN="$(aws codeartifact get-authorization-token \
    --domain <DOMAIN> --domain-owner <ACCOUNT_ID> \
    --query authorizationToken --output text)"

export UV_INDEX_PRIVATE_REGISTRY_USERNAME=aws
export UV_INDEX_PRIVATE_REGISTRY_PASSWORD="$AWS_CODEARTIFACT_TOKEN"
```

Keyring alternative:

```bash
uv tool install keyring --with keyrings.codeartifact
export UV_KEYRING_PROVIDER=subprocess
export UV_INDEX_PRIVATE_REGISTRY_USERNAME=aws
```

### Azure Artifacts

- Required username for keyring: **`VssSessionToken`** (the `artifacts-keyring` plugin requires
  this exact value in the URL username field).
- For PAT auth, the username can be any non-empty string.
- Token source: `$(System.AccessToken)` in an Azure pipeline, or a manually issued PAT.
- Keyring plugin: `artifacts-keyring` — wraps the Azure Artifacts Credential Provider.

```bash
export UV_INDEX_PRIVATE_REGISTRY_USERNAME=dummy
export UV_INDEX_PRIVATE_REGISTRY_PASSWORD="$AZURE_ARTIFACTS_TOKEN"
```

Keyring alternative:

```bash
uv tool install keyring --with artifacts-keyring
export UV_KEYRING_PROVIDER=subprocess
export UV_INDEX_PRIVATE_REGISTRY_USERNAME=VssSessionToken
```

### Google Artifact Registry

- Required username: **`oauth2accesstoken`** (hardcoded by the service; any other value fails).
- Token is short-lived; generate it with `gcloud auth application-default print-access-token`.
- Keyring plugin: `keyrings.google-artifactregistry-auth` — wraps gcloud, handles token refresh.

```bash
export ARTIFACT_REGISTRY_TOKEN=$(gcloud auth application-default print-access-token)
export UV_INDEX_PRIVATE_REGISTRY_USERNAME=oauth2accesstoken
export UV_INDEX_PRIVATE_REGISTRY_PASSWORD="$ARTIFACT_REGISTRY_TOKEN"
```

Keyring alternative:

```bash
uv tool install keyring --with keyrings.google-artifactregistry-auth
export UV_KEYRING_PROVIDER=subprocess
export UV_INDEX_PRIVATE_REGISTRY_USERNAME=oauth2accesstoken
```

### JFrog Artifactory

- Supports username + password or a JWT token.
- For JWT token auth: set `UV_INDEX_PRIVATE_REGISTRY_USERNAME=""` (empty string) and put the
  JWT token in `UV_INDEX_PRIVATE_REGISTRY_PASSWORD`.
- **`--token` / `UV_PUBLISH_TOKEN` must not be used** for `uv publish` with JFrog — JFrog
  requires an empty username, but uv passes `__token__` as the username when `--token` is
  used, which triggers a 401.

```bash
# Username + password
export UV_INDEX_PRIVATE_REGISTRY_USERNAME="<username>"
export UV_INDEX_PRIVATE_REGISTRY_PASSWORD="<password>"

# JWT token
export UV_INDEX_PRIVATE_REGISTRY_USERNAME=""
export UV_INDEX_PRIVATE_REGISTRY_PASSWORD="$JFROG_JWT_TOKEN"
```

## Examples

### AWS CodeArtifact — full install + publish workflow

```toml
# pyproject.toml
[[tool.uv.index]]
name = "codeartifact"
url = "https://my-domain-123456789.d.codeartifact.us-east-1.amazonaws.com/pypi/my-repo/simple/"
publish-url = "https://my-domain-123456789.d.codeartifact.us-east-1.amazonaws.com/pypi/my-repo/"
```

```bash
export AWS_CODEARTIFACT_TOKEN="$(aws codeartifact get-authorization-token \
    --domain my-domain --domain-owner 123456789 \
    --query authorizationToken --output text)"

export UV_INDEX_CODEARTIFACT_USERNAME=aws
export UV_INDEX_CODEARTIFACT_PASSWORD="$AWS_CODEARTIFACT_TOKEN"

uv sync
uv build
export UV_PUBLISH_USERNAME=aws
export UV_PUBLISH_PASSWORD="$AWS_CODEARTIFACT_TOKEN"
uv publish --index codeartifact
```

### JFrog Artifactory — publish with empty username

```bash
# Correct: use -u "" -p <token> or env vars with empty username
uv publish --index private-registry -u "" -p "$JFROG_TOKEN"

# Also correct via env vars
export UV_PUBLISH_USERNAME=""
export UV_PUBLISH_PASSWORD="$JFROG_TOKEN"
uv publish --index private-registry
```

### Keyring for any registry (generic pattern)

```bash
# Install keyring + the appropriate backend plugin
uv tool install keyring --with <registry-keyring-plugin>

# Enable subprocess mode and set the required username
export UV_KEYRING_PROVIDER=subprocess
export UV_INDEX_PRIVATE_REGISTRY_USERNAME=<required-username-for-registry>

uv sync
```

## Caveats / Common Mistakes

- **JFrog + `--token`:** Using `uv publish --token "$JFROG_TOKEN"` sends `__token__` as the
  username; JFrog rejects this with 401. Always use `-u "" -p "$JFROG_TOKEN"` or the
  `UV_PUBLISH_USERNAME` / `UV_PUBLISH_PASSWORD` env vars with an empty username.
- **AWS and Google require exact usernames:** Using any username other than `aws`
  (CodeArtifact) or `oauth2accesstoken` (Artifact Registry) causes authentication to fail —
  these are not conventional Basic Auth; the username is part of the auth protocol.
- **`UV_PUBLISH_USERNAME` / `UV_PUBLISH_PASSWORD` have no index suffix:** Unlike the install
  credentials (`UV_INDEX_<NAME>_USERNAME`), the publish credentials do not encode the index
  name. Target the right registry with `uv publish --index <name>`.
- **Setting `UV_PUBLISH_URL` without `publish-url` in config:** Publishing this way works but
  uv cannot check if the package version already exists before uploading artifacts, which can
  cause partial-upload errors on duplicate versions.
- **Keyring must be on `PATH`:** uv only supports keyring in subprocess mode — the `keyring`
  CLI must be accessible as a command. Install it globally with `uv tool install keyring`.
- **Token expiry:** CodeArtifact and Google tokens are short-lived. In CI, regenerate them
  per-job rather than caching.

## See Also

- config-index-auth
- config-package-indexes
- bp-publish-custom-index
- ts-auth-network
- bp-build-publish
