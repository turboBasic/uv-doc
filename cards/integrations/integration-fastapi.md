---
id: integration-fastapi
title: Using uv with FastAPI
category: integrations
tags: [integration, docker, project, dependency, installation]
source: https://docs.astral.sh/uv/guides/integration/fastapi/
related: [cmd-init, dep-add, project-run, integration-docker, concept-lockfile]
---

## Summary

uv manages FastAPI projects end-to-end: bootstrapping with `uv init --app`, adding
FastAPI via `uv add fastapi --extra standard`, running the dev server with `uv run fastapi dev`,
and deploying with a minimal Dockerfile using `uv sync --frozen --no-cache`.

## Syntax / Usage

```console
# Bootstrap
uv init --app
uv add fastapi --extra standard

# Development
uv run fastapi dev

# Docker deploy
uv sync --frozen --no-cache
```

## Details

### Bootstrapping

`uv init --app` creates an application-layout project (no `src/` layout, no build backend)
with a `pyproject.toml`. This is the appropriate template for web servers and scripts.

`uv add fastapi --extra standard` installs `fastapi[standard]`, which pulls in Uvicorn
and other optional runtime dependencies needed for the `fastapi` CLI.

### Running the dev server

`uv run fastapi dev` triggers uv's automatic lock-and-sync cycle before invoking the
command: uv resolves and writes `uv.lock`, creates `.venv`, and runs `fastapi dev` inside
it. No explicit `uv sync` or environment activation is required.

### Docker deployment

The recommended Dockerfile copies the uv binary from the official image, copies the full
project, and runs `uv sync --frozen --no-cache` to install dependencies:

- `--frozen` reads the committed `uv.lock` without checking whether it is up-to-date
  or re-resolving dependencies.
- `--no-cache` skips uv's download cache, keeping the image lean when no cache mount is
  used.

The application is then invoked directly from the virtual environment path
(`/app/.venv/bin/fastapi`), without activating the environment.

## Examples

### New project from scratch

```console
mkdir my-api && cd my-api
uv init --app
uv add fastapi --extra standard
uv run fastapi dev
```

The resulting `pyproject.toml` lists `fastapi[standard]` as a dependency:

```toml
[project]
name = "my-api"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = [
    "fastapi[standard]",
]
```

### Minimal Dockerfile

```dockerfile
FROM python:3.12-slim

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

COPY . /app
WORKDIR /app
RUN uv sync --frozen --no-cache

CMD ["/app/.venv/bin/fastapi", "run", "app/main.py", "--port", "80", "--host", "0.0.0.0"]
```

Build and run locally:

```console
docker build -t fastapi-app .
docker run -p 8000:80 fastapi-app
```

## Caveats / Common Mistakes

- `uv add fastapi` without `--extra standard` installs FastAPI without Uvicorn or the
  `fastapi` CLI. The dev server command `uv run fastapi dev` will fail. Always use
  `--extra standard` for application projects.
- The Dockerfile in this guide uses `--frozen` (not `--locked`). `--locked` errors when the
  lockfile is outdated; `--frozen` trusts the committed `uv.lock` unconditionally. Both
  prevent re-resolution at build time, but `--frozen` is more permissive.
- The official guide pins `:latest` for the uv image. For reproducible builds, pin a
  specific uv version (e.g., `ghcr.io/astral-sh/uv:0.11.24`). See `integration-docker`
  for the full best-practice Dockerfile pattern with cache mounts and multi-stage builds.

## See Also

- cmd-init
- dep-add
- project-run
- integration-docker
- concept-lockfile
