---
id: config-index-auth
title: Index authentication — credentials, netrc, keyring, and TLS
category: configuration
tags: [config, index, authentication, integration]
source: https://docs.astral.sh/uv/concepts/indexes/#authentication
related: [config-package-indexes, integration-private-indexes, ts-auth-network, config-git-auth, config-files]
---

## Summary

uv supports multiple credential mechanisms for private package indexes: per-index environment
variables, embedded URL credentials, netrc files, the uv credentials store (`uv auth`), and the
keyring subprocess provider. TLS verification is configurable via certificate environment variables
and `allow-insecure-host`.

## Syntax / Usage

```toml
# pyproject.toml — define the index without credentials
[[tool.uv.index]]
name = "internal-proxy"
url = "https://example.com/simple"
authenticate = "always"
```

```bash
# Supply credentials out-of-band via env vars
export UV_INDEX_INTERNAL_PROXY_USERNAME=public
export UV_INDEX_INTERNAL_PROXY_PASSWORD=koala

# Or store credentials once with uv auth
uv auth login example.com --username public --password -
```

## Details

### Credential lookup order

For each index, uv resolves credentials in this order:

1. The URL itself — `https://<user>:<password>@hostname/...`
2. A netrc file (always enabled; `NETRC` env var overrides path, default `~/.netrc`)
3. The uv credentials store (`~/.local/share/uv/credentials/credentials.toml` on Unix)
4. A keyring subprocess provider (disabled by default)

Credentials found for a host are cached for the duration of the command only — not across
invocations. If a username is set, uv skips the unauthenticated probe and fetches credentials
eagerly.

### Per-index environment variables

Given an index named `internal-proxy`, derive the env var name by uppercasing it and replacing
non-alphanumeric characters with underscores:

```bash
UV_INDEX_INTERNAL_PROXY_USERNAME=public
UV_INDEX_INTERNAL_PROXY_PASSWORD=koala
```

This avoids storing secrets in `pyproject.toml`.

### The `authenticate` setting

Controls whether uv probes credential providers before making requests to a specific index:

- `"auto"` (default) — unauthenticated request first; if it fails, search for credentials.
- `"always"` — search for credentials eagerly; error if none are found.
- `"never"` — never attach credentials; error if credentials are provided directly.

Use `"always"` for indexes like GitLab that transparently redirect unauthenticated requests to
a public index, which would otherwise cause uv to skip credential lookup.

### The `ignore-error-codes` setting

When using the `first-index` strategy, uv stops searching further indexes on HTTP 401 or 403
responses. To continue searching past specific error codes on an index:

```toml
[[tool.uv.index]]
name = "private-index"
url = "https://private-index.com/simple"
authenticate = "always"
ignore-error-codes = [403]
```

uv always continues on 404; this cannot be overridden.

### The uv credentials store

`uv auth login`, `uv auth logout`, and `uv auth token` manage credentials stored in the uv
credentials store. Credentials are written to a plaintext file by default. A system-native
encrypted backend (macOS Keychain, Windows Credential Manager, Linux Secret Service) is
available in preview with `UV_PREVIEW_FEATURES=native-auth`.

### Keyring subprocess provider

Disabled by default. Enable via:

- `--keyring-provider subprocess`
- `UV_KEYRING_PROVIDER=subprocess`
- `tool.uv.keyring-provider = "subprocess"` in `uv.toml`

uv invokes the `keyring` CLI to retrieve credentials. No other keyring provider types are
supported.

### Cache-control per index

Override the HTTP cache headers served by an index:

```toml
[[tool.uv.index]]
name = "example"
url = "https://example.com/simple"
cache-control = { api = "max-age=600", files = "max-age=365000000, immutable" }
```

`api` controls Simple API metadata requests; `files` controls artifact downloads.

### TLS certificate configuration

| Mechanism | How to enable |
|---|---|
| System certificate store | `--system-certs`, `UV_SYSTEM_CERTS=true`, or `system-certs = true` in `uv.toml` |
| Custom CA bundle (PEM) | `SSL_CERT_FILE=/path/to/bundle.pem` |
| Custom CA directory | `SSL_CERT_DIR=/path/to/certs` (`:` / `;` separated on Unix / Windows) |
| mTLS client certificate | `SSL_CLIENT_CERT=/path/to/cert-and-key.pem` |
| Skip verification for a host | `allow-insecure-host` setting (see below) |

By default, uv uses bundled Mozilla root certificates via `rustls`. `SSL_CERT_FILE` and
`SSL_CERT_DIR` **override** the default source entirely — only the provided certificates are
trusted. DER-encoded files are not supported; use PEM only.

`SSL_CLIENT_CERT` must point to a PEM file containing the client certificate immediately followed
by the private key (mTLS).

### Disabling certificate verification (`allow-insecure-host`)

```toml
[tool.uv]
allow-insecure-host = ["example.com", "localhost:8080"]
```

Accepts hostnames or `host:port` pairs. Applies only to HTTPS connections.

## Examples

```toml
# Private index with per-index credentials via env vars
[[tool.uv.index]]
name = "corp-proxy"
url = "https://pypi.corp.dev/simple"
authenticate = "always"
ignore-error-codes = [403]
```

```bash
# Provide credentials at install time without touching pyproject.toml
UV_INDEX_CORP_PROXY_USERNAME=ci-bot \
UV_INDEX_CORP_PROXY_PASSWORD=s3cr3t \
uv sync
```

```bash
# Store credentials once, reuse across invocations
echo 'my-token' | uv auth login pypi.corp.dev --token -

# Verify stored credentials
uv auth token pypi.corp.dev

# Remove credentials
uv auth logout pypi.corp.dev
```

```bash
# Corporate proxy with a custom CA bundle
SSL_CERT_FILE=/etc/ssl/corp-ca.pem uv sync

# Allow an internal registry with a self-signed cert (use only in trusted environments)
# uv.toml or pyproject.toml:
# [tool.uv]
# allow-insecure-host = ["internal-registry.corp:8080"]
```

```bash
# Enable keyring subprocess provider
UV_KEYRING_PROVIDER=subprocess uv sync
```

## Caveats / Common Mistakes

- Credentials embedded in index URLs (`https://user:pass@host/...`) are **never** written to
  `uv.lock`. The lock file is safe to commit, but uv needs the authenticated URL available at
  every install — supply it via env vars or the credentials store instead.
- `uv add` strips credentials from the index URL before writing to `pyproject.toml`. Subsequent
  runs will fail to authenticate unless credentials are available through another mechanism.
- `authenticate = "never"` prevents all credential attachment and will error if credentials are
  provided directly — do not confuse it with a no-op.
- `SSL_CERT_FILE` / `SSL_CERT_DIR` completely replace the default Mozilla root bundle; if you
  set these for a custom CA, also include the standard roots or other trusted certificates, or
  connections to public indexes will break.
- The uv credentials store is currently **plaintext**. Use `UV_PREVIEW_FEATURES=native-auth`
  if secrets at rest are a concern (experimental).
- `uv auth` credentials are not used for Git requests — only HTTP(S) package registry requests.

## See Also

- config-package-indexes
- integration-private-indexes
- ts-auth-network
- config-git-auth
- config-files
