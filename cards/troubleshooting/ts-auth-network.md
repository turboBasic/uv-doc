---
id: ts-auth-network
title: Authentication and network errors with package indexes
category: troubleshooting
tags: [troubleshooting, authentication, index, config, installation]
source: https://docs.astral.sh/uv/concepts/authentication/http/
related: [config-index-auth, config-package-indexes, integration-private-indexes, ts-git-auth, concept-indexes]
---

## Summary

401/403 errors from private package indexes mean uv could not find or supply credentials;
TLS errors mean the server's certificate chain is untrusted. Both classes of error are fixed
by telling uv where to find credentials or which CA bundle to use.

## Syntax / Usage

```bash
# Store credentials persistently in uv's credentials store
uv auth login <hostname>
uv auth login example.com --username myuser --password -   # read password from stdin

# Supply per-index credentials via env vars
export UV_INDEX_<NAME>_USERNAME=myuser
export UV_INDEX_<NAME>_PASSWORD=mytoken

# Override CA bundle
export SSL_CERT_FILE=/path/to/ca-bundle.pem

# Use the OS certificate store instead of bundled Mozilla roots
uv sync --system-certs
UV_SYSTEM_CERTS=true uv sync

# Disable cert verification for a specific host (development only)
uv sync --allow-insecure-host example.com
```

## Details

### Credential sources and precedence

uv tries credential sources in this order:

1. **URL embedding** — `https://user:password@host/...` in the index URL.
2. **netrc file** — always checked; path from `NETRC` env var, falling back to `~/.netrc`.
3. **uv credentials store** — written by `uv auth login`; stored at
   `~/.local/share/uv/credentials/credentials.toml` on Unix.
4. **Keyring** — off by default; enable with `--keyring-provider subprocess`,
   `UV_KEYRING_PROVIDER=subprocess`, or `tool.uv.keyring-provider = "subprocess"`.

### Per-index environment variables

For an index named `my-index` in `pyproject.toml`, set:

```
UV_INDEX_MY_INDEX_USERNAME=...
UV_INDEX_MY_INDEX_PASSWORD=...
```

The name is uppercased and all non-alphanumeric characters are replaced with underscores.

### Lazy vs. eager credential lookup (`authenticate`)

By default, uv makes an unauthenticated request first and only searches for credentials if it
receives a 401. Some registries (notably GitLab) silently forward unauthenticated requests to
PyPI instead of returning 401, so uv never searches for credentials and pulls the wrong
package. Set `authenticate = "always"` to force eager credential lookup:

```toml
[[tool.uv.index]]
name = "gitlab"
url = "https://gitlab.example.com/api/v4/projects/1/packages/pypi/simple"
authenticate = "always"
```

Setting `authenticate = "always"` also causes uv to error immediately when no credentials
are found, rather than making an unauthenticated request that will fail later.

To prevent any credentials from being sent (e.g., for a fully public mirror), set
`authenticate = "never"`.

### Ignoring 403 responses (`ignore-error-codes`)

When using the `first-index` strategy, uv stops searching across indexes on a 401 or 403.
JFrog Artifactory and the PyTorch index return 403 for packages that do not exist on that
index, which would halt the search prematurely. uv has a built-in exception for the `pytorch`
index; for other registries, configure `ignore-error-codes`:

```toml
[[tool.uv.index]]
name = "private-index"
url = "https://private-index.com/simple"
authenticate = "always"
ignore-error-codes = [403]
```

### TLS errors

uv bundles Mozilla root certificates (via `rustls`). Common causes of TLS failures:

- **Corporate proxy or internal CA not in Mozilla roots** — use `--system-certs` /
  `UV_SYSTEM_CERTS=true` to delegate verification to the OS certificate store, which
  includes enterprise-added roots.
- **Custom CA bundle** — set `SSL_CERT_FILE` to a PEM-encoded bundle, or `SSL_CERT_DIR` to
  a directory of PEM files (`:` delimited on Unix, `;` on Windows). These variables
  *replace* the default bundle entirely; include all required CAs.
- **mTLS (client certificate auth)** — set `SSL_CLIENT_CERT` to a PEM file containing
  the certificate followed by the private key.
- **Self-signed cert / cert verification disabled** — add the host to
  `allow-insecure-host`; it accepts `hostname` or `hostname:port` strings. DER-encoded
  certificates are not supported; convert to PEM first.

## Examples

**Persist credentials for a private index:**

```bash
# Store once; uv reuses on subsequent operations
echo "$MY_TOKEN" | uv auth login example.com --username ci-user --password -
```

**Per-index env vars for CI (index name `corp-pypi`):**

```bash
export UV_INDEX_CORP_PYPI_USERNAME=__token__
export UV_INDEX_CORP_PYPI_PASSWORD="$PYPI_TOKEN"
uv sync
```

**Force credential search on a GitLab registry that forwards to PyPI:**

```toml
# pyproject.toml
[[tool.uv.index]]
name = "gitlab"
url = "https://gitlab.example.com/api/v4/projects/42/packages/pypi/simple"
authenticate = "always"
```

**Corporate proxy with a private CA:**

```bash
export SSL_CERT_FILE=/etc/ssl/corp-ca-bundle.pem
uv sync
```

**Self-signed cert in local dev:**

```toml
# uv.toml or pyproject.toml [tool.uv]
allow-insecure-host = ["devregistry.local:8080"]
```

**JFrog with a JWT token (username must be empty):**

```bash
export UV_INDEX_PRIVATE_REGISTRY_USERNAME=""
export UV_INDEX_PRIVATE_REGISTRY_PASSWORD="$JFROG_JWT_TOKEN"
uv sync
```

## Caveats / Common Mistakes

- Embedding credentials directly in the index URL in `pyproject.toml` or `uv.toml` risks
  leaking secrets into version control. Use env vars or `uv auth login` instead.
- `SSL_CERT_FILE` / `SSL_CERT_DIR` fully replace the default CA bundle. If you set one of
  these to a single corporate CA, standard PyPI connections will fail unless the bundle also
  contains the Mozilla roots.
- DER-encoded certificate files are not supported — convert with
  `openssl x509 -inform DER -outform PEM`.
- `uv auth login` does not validate credentials at login time; a typo will fail silently
  until the next `uv sync` or `uv add`.
- When `authenticate = "always"`, uv errors if no credentials are found rather than
  attempting an unauthenticated request.
- Using `--token` or `UV_PUBLISH_TOKEN` with JFrog triggers a 401 because JFrog requires
  an empty username; pass the token as `--password` with `-u ""` instead.

## See Also

- config-index-auth
- config-package-indexes
- integration-private-indexes
- ts-git-auth
- concept-indexes
