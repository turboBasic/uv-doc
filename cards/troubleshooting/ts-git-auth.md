---
id: ts-git-auth
title: Authentication failures with Git dependencies
category: troubleshooting
tags: [troubleshooting, authentication, dependency, integration, ci]
source: https://docs.astral.sh/uv/concepts/authentication/git/
related: [config-git-auth, dep-sources, integration-github-actions, config-index-auth, ts-auth-network]
---

## Summary

`uv sync` or `uv add` fails to fetch a private Git dependency because credentials are not
embedded in the stored URL and no Git credential helper is configured. This is the most
common authentication failure pattern with Git sources.

## Syntax / Usage

```bash
# Add a private dependency over SSH
uv add git+ssh://git@github.com/<org>/<repo>

# Add a private dependency over HTTPS (credentials NOT stored in pyproject.toml)
uv add git+https://github.com/<org>/<repo>

# Force credentials into the URL (not recommended)
uv add --raw "git+https://git:<token>@github.com/<org>/<repo>"
```

## Details

### Why credentials go missing after `uv add`

`uv add` deliberately strips credentials from Git URLs before writing to `pyproject.toml`
and `uv.lock`. Both files are typically committed to source control, and embedding secrets
would expose them. The URL stored on disk contains no user or token component.

On the machine where `uv add` was run, a Git credential helper may silently supply the
token on subsequent fetches — making it appear that credentials are persisted. On a fresh
machine (or CI runner) with no credential helper, `uv sync` fails.

### SSH authentication

SSH uses the username `git`. Key selection and agent forwarding are handled by the
SSH agent and `~/.ssh/config`; uv has no additional configuration for this. Common
failures:

- SSH key not added to the agent (`ssh-add ~/.ssh/id_ed25519`).
- `~/.ssh/known_hosts` missing the host — first connection prompts host verification.
- Non-default key name not referenced in `~/.ssh/config`.

### HTTPS / token authentication

Without a credential helper, embed credentials directly in the URL passed to `uv add`:

```
git+https://<user>:<token>@<hostname>/<owner>/<repo>
git+https://<token>@<hostname>/<owner>/<repo>
```

For GitHub PATs, the `<user>` value is arbitrary — GitHub does not accept account passwords
over HTTPS. The credential is stripped before storage regardless.

### Setting up a Git credential helper

The correct fix is to configure a Git credential helper so that subsequent `uv sync`
invocations can resolve credentials automatically without embedding them.

For GitHub, use the `gh` CLI:

```console
$ gh auth login          # interactive — configures the helper automatically
```

For non-interactive use (CI, containers):

```console
$ echo "$MY_PAT" | gh auth login --with-token
$ gh auth setup-git
```

`gh auth login --with-token` alone does **not** configure the Git credential helper; the
`gh auth setup-git` step is required.

### The `--raw` flag

Passing `--raw` to `uv add` forces credentials to be written verbatim into the URL in
`pyproject.toml` and `uv.lock`. This makes the project portable without a credential
helper, but leaks the token in source control. Use only for private, non-shared repos
and prefer a credential helper in all other cases.

## Examples

Local development — SSH key in agent:

```console
$ ssh-add ~/.ssh/id_ed25519
$ uv add git+ssh://git@github.com/my-org/private-lib
```

Local development — HTTPS via credential helper:

```console
$ gh auth login
$ uv add git+https://github.com/my-org/private-lib
```

GitHub Actions — non-interactive PAT setup:

```yaml
steps:
  - name: Register the personal access token
    run: echo "${{ secrets.MY_PAT }}" | gh auth login --with-token
  - name: Configure the Git credential helper
    run: gh auth setup-git
  - name: Install dependencies
    run: uv sync --locked
```

Temporary workaround via environment credential (avoids embedding in files):

```console
# GIT_ASKPASS is a Git mechanism; uv delegates to git for cloning
$ GIT_ASKPASS=echo GIT_TERMINAL_PROMPT=0 uv sync
```

## Caveats / Common Mistakes

- `uv add` never writes credentials to `pyproject.toml` or `uv.lock`, even when they are
  supplied in the URL. A working `uv add` does not mean `uv sync` will succeed on a clean
  machine.
- `gh auth login --with-token` does not configure the Git credential helper on its own.
  Always follow it with `gh auth setup-git` in non-interactive contexts.
- SSH authentication requires the username `git`; using an account username will fail.
- `--raw` embeds credentials in committed files. Do not use in shared or public repositories.

## See Also

- config-git-auth
- dep-sources
- integration-github-actions
- config-index-auth
- ts-auth-network
