---
id: concept-platform-support
title: Platform support tiers and Linux/Windows/macOS requirements
category: concepts
tags: [installation, performance, docker]
source: https://docs.astral.sh/uv/reference/policies/platforms/
related: [python-support-matrix, config-installation, integration-docker, dep-platform-environments]
---

## Summary

uv sorts the operating systems and architectures it runs on into three support tiers and
publishes prebuilt binaries and wheels for Tier 1 and Tier 2. The tier, plus the libc and
OS-version minimums, determine whether uv runs on a given machine.

## Details

### Support tiers

| Tier | Platforms | Meaning |
|---|---|---|
| Tier 1 | macOS (Apple Silicon), macOS (x86_64), Linux (x86_64), Windows (x86_64) | "Guaranteed to work" — continuously built, tested, and developed against. |
| Tier 2 | Linux (PPC64LE, RISC-V64, aarch64, armv7, i686, s390x), Windows (arm64) | "Guaranteed to build" — continuously built but not run through the test suite; stability may vary. |
| Tier 3 | FreeBSD (x86_64), Windows (i686) | "Best effort" — may not be built or tested; patches accepted. |

Official binaries (GitHub) and prebuilt wheels (PyPI) are provided for Tier 1 and Tier 2.

### Linux: glibc vs musl

On Linux, compatibility is determined by libc version. uv publishes both:

- **glibc** — manylinux-compatible wheels and binaries that depend on host glibc. The
  manylinux tag encodes the minimum glibc, e.g. `manylinux_2_17_x86_64` requires glibc 2.17+.
  Targets include `x86_64` (`manylinux_2_17`), `aarch64` (`manylinux_2_28`), `armv7`, `i686`,
  `ppc64le`, `s390x` (all `manylinux_2_17`), and `riscv64` (`manylinux_2_31`).
- **musl** — musllinux-tagged wheels plus fully statically linked binaries. The embedded uv
  binary is statically linked and does **not** require musl libc on the host. Targets include
  `x86_64`, `aarch64`, `armv7`, `i686`, `riscv64` (`musllinux_1_1`), and `arm` (`linux_armv6l`).

The official Docker images (see `integration-docker`) ship the statically linked musl uv
binaries for amd64 and arm64.

### Windows and macOS minimums

- **Windows:** minimum supported is Windows 10 / Windows Server 2016 (following Rust's Tier 1
  support).
- **macOS:** supports macOS 13+ (Ventura). Known to work on macOS 12, but that requires a
  `realpath` executable to be installed.

## Examples

```bash
# Tier 1 — prebuilt binary, fully supported
curl -LsSf https://astral.sh/uv/install.sh | sh   # x86_64 Linux / macOS / Windows

# Tier 2 — prebuilt binary exists (built, not test-suite-verified)
#   e.g. Linux aarch64, s390x, Windows arm64

# Statically linked musl binary needs no musl libc on the host
docker run --rm ghcr.io/astral-sh/uv:latest uv --version
```

## Caveats / Common Mistakes

- Tier 2 platforms are built but **not** run through uv's test suite — treat them as
  "guaranteed to build", not "guaranteed to work".
- Tier 3 (FreeBSD x86_64, Windows i686) may have no prebuilt artifacts at all; you may need
  to build from source.
- `SSL`/wheel tags: the manylinux tag's embedded version is the *minimum* glibc, so a
  `manylinux_2_28` artifact will not run on a host with glibc older than 2.28.
- macOS 12 works only with a separately installed `realpath`; macOS 13+ has no such caveat.

## See Also

- python-support-matrix
- config-installation
- integration-docker
- dep-platform-environments
