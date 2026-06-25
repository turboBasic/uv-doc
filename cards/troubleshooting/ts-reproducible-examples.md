---
id: ts-reproducible-examples
title: Writing minimal reproducible examples for uv bug reports
category: troubleshooting
tags: [troubleshooting, docker, integration, config]
source: https://docs.astral.sh/uv/reference/troubleshooting/reproducible-examples/
related: [ts-verbose-debugging, ts-resolution-conflict, integration-docker, ts-build-failure, ts-lockfile-errors]
---

## Summary

A minimal reproducible example (MRE) lets maintainers debug and verify fixes for uv
issues. Without one, the root cause cannot be isolated; without minimisation, it takes
significantly longer to identify.

## Syntax / Usage

```console
# Build a Docker MRE with full output
docker build . --progress plain --no-cache

# Clone a Git-repository MRE and reproduce
git clone https://github.com/<user>/<project>.git
cd <project>
git checkout <commit>
<commands to produce error>
```

## Details

### Context to include

Every report — regardless of strategy — needs:

- Platform: OS, architecture (e.g. `linux/amd64`, `darwin/arm64`)
- Relevant environment variables (any that affect uv behaviour)
- uv version (`uv --version`)
- Versions of other relevant tools (Python runtime, Docker, shell)
- Relevant files: `pyproject.toml`, `uv.lock`, `uv.toml`
- The exact commands to run
- Verbose logs (`-v` flag) of the failure and the complete error message

Minimise by removing dependencies, settings, and files not required to reproduce the
problem. Test the reproduction before sharing it.

### Strategy 1: Docker image

Best for issues reproducible on Linux. A Docker image is entirely self-contained so
the reproducer's system state cannot interfere.

Start from one of [uv's official Docker images](https://docs.astral.sh/uv/guides/integration/docker/#available-images)
and **pin the uv version**:

```dockerfile
FROM ghcr.io/astral-sh/uv:0.5.24-debian-slim
```

Docker builds use the host's architecture by default. Set `--platform` explicitly so
the reproducer gets consistent behaviour. uv publishes images for `linux/amd64` (Intel/AMD)
and `linux/arm64` (Apple M-series, ARM):

```dockerfile
FROM --platform=linux/amd64 ghcr.io/astral-sh/uv:0.5.24-debian-slim
```

Construct the scenario with commands:

```dockerfile
FROM --platform=linux/amd64 ghcr.io/astral-sh/uv:0.5.24-debian-slim

RUN uv init /mre
WORKDIR /mre
RUN uv add pydantic
RUN uv sync
RUN uv run -v python -c "import pydantic"
```

Or write files inline with a heredoc:

```dockerfile
FROM --platform=linux/amd64 ghcr.io/astral-sh/uv:0.5.24-debian-slim

COPY <<EOF /mre/pyproject.toml
[project]
name = "example"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = ["pydantic"]
EOF

WORKDIR /mre
RUN uv lock
```

When sharing, include build logs with caching disabled:

```console
docker build . --progress plain --no-cache
```

### Strategy 2: Shell script

Use when the bug is platform-specific (macOS, Windows) and cannot be reproduced in a
container. Include `-v` (verbose) output alongside the script:

```bash
uv init
uv add pydantic
uv sync
uv run -v python -c "import pydantic"
```

Document all external state the script relies on: OS version, Python source (e.g.
installed via `choco`), shell and its version.

### Strategy 3: Git repository

Use when the scenario involves many files. Always combine with a script or Dockerfile
so the reproducer knows which commands trigger the problem. Pin to a specific commit:

```console
git clone https://github.com/<user>/<project>.git
cd <project>
git checkout <commit>
<commands to produce error>
```

Create a new repository quickly with the `gh` CLI:

```console
gh repo create uv-mre-1234 --clone
```

## Examples

Self-contained Dockerfile MRE for a lock failure on AMD64:

```dockerfile
FROM --platform=linux/amd64 ghcr.io/astral-sh/uv:0.5.24-debian-slim

COPY <<EOF /mre/pyproject.toml
[project]
name = "example"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = ["package-a==1.0", "package-b==2.0"]
EOF

WORKDIR /mre
RUN uv lock
```

Build and capture full output:

```console
docker build . --progress plain --no-cache 2>&1 | tee mre-build.log
```

Shell-script MRE for a macOS-specific issue:

```bash
# Requires: macOS 14.5 arm64, uv 0.5.24, Python 3.12 from python.org
uv init mre && cd mre
uv add some-package
uv run -v python -c "import some_package"
```

## Caveats / Common Mistakes

- **Not pinning the uv version in Docker** — floating tags (`latest`) make the
  reproduction non-deterministic. Always use a versioned tag such as
  `uv:0.5.24-debian-slim`.
- **Forgetting `--platform`** — Docker defaults to the host architecture, so an
  arm64 Mac silently builds an arm64 image. If the bug is amd64-specific the
  reproduction will not trigger.
- **Omitting verbose logs** — the `-v` output often reveals critical differences
  (index selection, cache hits, platform markers) that plain output hides.
- **Not testing before sharing** — an untested MRE that does not reproduce the problem
  wastes maintainer time. Always run it in a clean environment first.
- **Including unrelated files or settings** — excess noise makes root-cause analysis
  harder. Remove everything not required to trigger the failure.

## See Also

- ts-verbose-debugging
- ts-resolution-conflict
- integration-docker
- ts-build-failure
- ts-lockfile-errors
