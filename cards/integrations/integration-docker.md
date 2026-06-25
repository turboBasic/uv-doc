---
id: integration-docker
title: Using uv in Docker
category: integrations
tags: [integration, docker, installation, cache, performance]
source: https://docs.astral.sh/uv/guides/integration/docker/
related: [concept-lockfile, project-structure, bp-build-publish, python-versions, config-installation, concept-platform-support]
---

## Summary

uv ships official Docker images and integrates cleanly into Dockerfiles. Best practice is
to copy the uv binary from a pinned image, cache the uv download dir, and `uv sync
--locked` against the committed lockfile for reproducible, fast builds.

## Syntax / Usage

```dockerfile
COPY --from=ghcr.io/astral-sh/uv:0.11.24 /uv /uvx /bin/
RUN uv sync --locked
```

## Details

Images live under `ghcr.io/astral-sh/uv` — distroless (`:latest`, just the binaries),
plus OS- and Python-based variants (`:debian`, `:alpine`, `:python3.12-alpine`). Pin a
specific uv version rather than `:latest`.

Key practices:

- **Install via COPY** from the distroless image into a Python base image.
- **Layer caching:** split dependency install from app code with
  `uv sync --locked --no-install-project`, then copy code and `uv sync --locked` again.
- **Cache mount:** `--mount=type=cache,target=/root/.cache/uv` with
  `ENV UV_LINK_MODE=copy` (required when the cache is on a different filesystem).
- **Bytecode:** `ENV UV_COMPILE_BYTECODE=1` to precompile for faster startup.
- **Multi-stage:** build with `uv sync --locked --no-editable`, then copy only
  `/app/.venv` into the final image.
- Add `.venv` to `.dockerignore` — it is platform-specific.

Useful env vars: `UV_NO_DEV=1` (skip dev deps), `UV_COMPILE_BYTECODE=1`,
`UV_LINK_MODE=copy`, `UV_PYTHON_DOWNLOADS=0` (system Python only),
`UV_PROJECT_ENVIRONMENT` (install to a chosen environment).

## Examples

```dockerfile
FROM python:3.12-slim

COPY --from=ghcr.io/astral-sh/uv:0.11.24 /uv /uvx /bin/
WORKDIR /app

# Install dependencies in a cached, code-independent layer
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --locked --no-install-project

# Add the project and install it
COPY . /app
ENV UV_COMPILE_BYTECODE=1
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked

ENV PATH="/app/.venv/bin:$PATH"
CMD ["python", "-m", "my_app"]
```

## Caveats / Common Mistakes

- Forgetting `UV_LINK_MODE=copy` with a cache mount on a separate filesystem produces
  hardlink warnings/failures.
- Not pinning the uv image tag makes builds non-reproducible; pin `ghcr.io/astral-sh/uv:<version>`.
- Copying a host `.venv` into the image breaks it — it is platform-specific; rebuild with
  `uv sync` instead and `.dockerignore` it.

## See Also

- concept-lockfile
- project-structure
- bp-build-publish
- python-versions
- config-installation
- concept-platform-support
