---
id: config-git-auth
title: Git dependency authentication
category: configuration
tags: [config, authentication, dependency, integration]
source: https://docs.astral.sh/uv/concepts/authentication/git/
related: [dep-sources, config-index-auth, ts-git-auth, integration-github-actions, config-env-vars]
---

## Summary

uv can install packages from private Git repositories using SSH or HTTPS authentication,
delegating credential lookup to Git credential helpers when no credentials are embedded in
the URL.

## Syntax / Usage

SSH URL form:

```
git+ssh://git@<hostname>/<owner>/<repo>
```

HTTPS URL forms (credentials embedded):

```
git+https://<user>:<token>@<hostname>/<owner>/<repo>
git+https://<token>@<hostname>/<owner>/<repo>
git+https://<user>@<hostname>/<owner>/<repo>
```

## Details

### SSH authentication

Use the `ssh://` protocol with the username `git`. The underlying SSH agent and `~/.ssh/config`
handle key selection, so no further uv configuration is needed.

### HTTPS / token authentication

Embed credentials directly in the URL using HTTP Basic authentication. For GitHub personal
access tokens (PATs), the username is arbitrary — GitHub does not accept account
passwords over HTTPS.

If credentials are absent from the URL and the host requires authentication, uv queries the
configured [Git credential helper](https://git-scm.com/doc/credential-helpers) before failing.

### Persistence rules

`uv add` strips credentials from Git URLs before writing to `pyproject.toml` and `uv.lock` —
these files are typically committed, so embedding secrets is unsafe. Subsequent fetches
succeed only if a credential helper resolves the credentials automatically.

To force uv to write credentials into the URL verbatim, pass `--raw` to `uv add`. This is
strongly discouraged; prefer a credential helper instead.

### Git credential helpers

Any helper understood by Git works. For GitHub, the simplest path is the `gh` CLI:

```console
$ gh auth login
```

Running `gh auth login` interactively configures the credential helper automatically.
When using a token non-interactively (e.g., in CI), run both steps:

```console
$ echo "$MY_PAT" | gh auth login --with-token
$ gh auth setup-git
```

### Git LFS

Git LFS objects are not fetched by default. Control this per-source with the `lfs` key in
`tool.uv.sources`, or globally via the `UV_GIT_LFS` environment variable for sources that
do not set `lfs` explicitly.

- `lfs = true` — always fetch LFS objects for this source.
- `lfs = false` — never fetch LFS objects for this source.
- omitted — falls back to `UV_GIT_LFS`.

Ensure the `git-lfs` binary is installed before enabling LFS fetching, otherwise the build
will fail.

### Hugging Face token propagation

If `HF_TOKEN` is set, uv automatically propagates it to requests targeting `huggingface.co`.
This enables fetching private scripts from Hugging Face Datasets without embedding the token
in a URL. Set `UV_NO_HF_TOKEN=1` to opt out.

## Examples

```console
# SSH (key-based)
$ uv add git+ssh://git@github.com/my-org/private-lib

# HTTPS with embedded PAT (not recommended for shared repos)
$ uv add "git+https://git:github_pat_xxx@github.com/my-org/private-lib"

# HTTPS without embedded credentials — relies on credential helper
$ uv add git+https://github.com/my-org/private-lib
```

```toml
# pyproject.toml — Git LFS enabled for one source
[tool.uv.sources]
my-lfs-lib = { git = "https://github.com/my-org/my-lfs-lib", lfs = true }
```

```console
# LFS globally via env var
$ UV_GIT_LFS=1 uv sync
```

```yaml
# GitHub Actions — private repo access via PAT
steps:
  - name: Register the personal access token
    run: echo "${{ secrets.MY_PAT }}" | gh auth login --with-token
  - name: Configure the Git credential helper
    run: gh auth setup-git
  - run: uv sync
```

```console
# Hugging Face private dataset script
$ HF_TOKEN=hf_... uv run https://huggingface.co/datasets/<user>/<name>/resolve/<branch>/main.py
```

## Caveats / Common Mistakes

- `uv add` never writes credentials to `pyproject.toml` or `uv.lock`. If no credential helper
  is set up, the next `uv sync` on a clean machine will fail silently with an auth error.
- `gh auth login --with-token` does not configure the credential helper on its own — you must
  also run `gh auth setup-git` in the same CI job.
- Git LFS objects are silently skipped (not an error) unless `lfs = true` or `UV_GIT_LFS` is
  set. The build may succeed but produce a broken wheel if LFS pointers are treated as source.
- `HF_TOKEN` propagation is automatic and unconditional unless `UV_NO_HF_TOKEN=1` is set.
  Be aware that this means the token is sent to any URL under `huggingface.co`.

## See Also

- dep-sources
- config-index-auth
- ts-git-auth
- integration-github-actions
- config-env-vars
