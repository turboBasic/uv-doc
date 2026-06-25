---
id: integration-gitlab-ci
title: Using uv in GitLab CI/CD
category: integrations
tags: [integration, ci, docker, cache, performance, pip]
source: https://docs.astral.sh/uv/guides/integration/gitlab/
related: [integration-docker, concept-cache, cmd-cache, integration-github-actions, pip-install]
---

## Summary

uv runs inside GitLab CI/CD jobs by using the official uv Docker images. Cache the
`uv.lock`-keyed cache directory between runs, set `UV_LINK_MODE=copy` to work around
GitLab's separate build mountpoint, and call `uv cache prune --ci` at the end of each
job to keep the cache lean.

## Syntax / Usage

```yaml
# Minimal job using the uv Python image
uv:
  image: ghcr.io/astral-sh/uv:0.11.24-python3.12-trixie-slim
  variables:
    UV_LINK_MODE: copy
  script:
    - uv sync --locked
```

## Details

**Image selection.** Astral publishes images at `ghcr.io/astral-sh/uv` in the same
variants as for Docker: distroless (binary-only), Debian, Alpine, and combined
Python+OS images (e.g. `:0.11.24-python3.12-trixie-slim`). Pin an explicit version
rather than `:latest` for reproducible pipelines.

**Distroless images.** When using the binary-only image you must clear the entrypoint,
because the distroless image has no shell:

```yaml
uv:
  image:
    name: ghcr.io/astral-sh/uv:0.11.24
    entrypoint: [""]
```

**`UV_LINK_MODE=copy`.** GitLab CI mounts the build directory on a separate filesystem
from the runner's cache volume. uv defaults to hardlinking cached wheels into the
environment, which fails across mountpoints. Setting `UV_LINK_MODE=copy` makes uv copy
files instead. Set it as a top-level pipeline variable so every job inherits it.

**Caching.** GitLab's cache system is keyed by a `key:` block. Key on `uv.lock` so the
cache is invalidated only when dependencies actually change. Set `UV_CACHE_DIR` to a
relative path inside the project (e.g. `.uv-cache`) so GitLab can persist it:

```yaml
variables:
  UV_CACHE_DIR: .uv-cache

cache:
  - key:
      files:
        - uv.lock
    paths:
      - $UV_CACHE_DIR
```

**`uv cache prune --ci`.** In CI, pre-built wheels downloaded from the registry are
cheap to re-download; wheels built from source (e.g. C extensions) are expensive.
`uv cache prune --ci` removes pre-built wheels and unzipped source distributions from
the cache while keeping source-built wheels. Run it in `after_script` so the trimmed
cache is what gets uploaded.

**`UV_SYSTEM_PYTHON` for `uv pip`.** When using the pip-compatible interface (`uv pip
install`, `uv pip compile`) rather than the project interface, uv requires a virtual
environment by default. To install into the system Python provided by the CI image,
set `UV_SYSTEM_PYTHON=1` as a pipeline variable. Use `--no-system` on individual
invocations to opt back out.

When caching with the pip interface, key on `requirements.txt` or `pyproject.toml`
instead of `uv.lock` because `uv.lock` may not exist in that workflow.

## Examples

**Full pipeline with caching and cache pruning:**

```yaml
variables:
  UV_VERSION: "0.11.24"
  PYTHON_VERSION: "3.12"
  BASE_LAYER: trixie-slim
  UV_LINK_MODE: copy
  UV_CACHE_DIR: .uv-cache

uv-install:
  image: ghcr.io/astral-sh/uv:$UV_VERSION-python$PYTHON_VERSION-$BASE_LAYER
  cache:
    - key:
        files:
          - uv.lock
      paths:
        - $UV_CACHE_DIR
  script:
    - uv sync --locked
    - uv run pytest
  after_script:
    - uv cache prune --ci
```

**Using the pip interface with system Python:**

```yaml
variables:
  UV_SYSTEM_PYTHON: 1
  UV_LINK_MODE: copy

pip-job:
  image: ghcr.io/astral-sh/uv:0.11.24-python3.12-trixie-slim
  script:
    - uv pip install -r requirements.txt
    - python -m pytest
```

## Caveats / Common Mistakes

- Forgetting `UV_LINK_MODE=copy` causes hardlink failures when the uv cache and the
  build directory are on different mountpoints — set it at the top-level `variables`
  block so all jobs inherit it automatically.
- Using the distroless image without clearing the `entrypoint` results in a GitLab
  runner error; set `entrypoint: [""]` in the image config.
- Not pinning the uv image tag (`ghcr.io/astral-sh/uv:latest`) makes pipelines
  non-reproducible; pin a specific version.
- With the `uv pip` interface, omitting `UV_SYSTEM_PYTHON=1` or `--system` causes uv
  to refuse to install because no virtual environment is active.
- When using `uv pip`, keying the cache on `uv.lock` is incorrect if a lockfile is not
  generated in that workflow; use `requirements.txt` or `pyproject.toml` instead.

## See Also

- integration-docker
- concept-cache
- cmd-cache
- integration-github-actions
- pip-install
