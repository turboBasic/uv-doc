---
id: bp-uv-build-options
title: "uv build flags and options reference"
category: build-publish
tags: [command, build, publish, workspace, config]
source: https://docs.astral.sh/uv/reference/cli/#uv-build
related: [bp-build-publish, bp-uv-build-backend, bp-build-system-config, dep-sources, project-workspaces]
---

## Summary

`uv build` turns a project source tree or an sdist archive into distributable artifacts (sdist
and/or wheel). This card documents every meaningful flag grouped by purpose so you can reach for
the right option without scanning the full CLI reference.

## Syntax / Usage

```bash
uv build [OPTIONS] [SRC]
```

`SRC` is an optional path to a directory (builds both sdist and wheel by default) or a path to an
existing source distribution archive (builds a wheel from it). Defaults to the current working
directory.

## Details

### Artifact selection

| Flag | Effect |
|---|---|
| `--sdist` | Build only a source distribution. |
| `--wheel` | Build only a binary distribution (wheel). |
| `--sdist --wheel` | Build both from source (not wheel-from-sdist). |
| _(default, no flag)_ | Build sdist first, then wheel from that sdist. |

When `--wheel` is passed with a source distribution as `SRC`, the wheel is built from that sdist
rather than from the directory source.

### Output control

| Flag | Effect |
|---|---|
| `--out-dir`, `-o` | Directory to write artifacts into. Defaults to `dist/` inside the source directory (or next to the sdist archive when building a wheel from an archive). |
| `--clear` | Delete stale artifacts from the output directory before building. |
| `--no-create-gitignore` | Skip creating a `.gitignore` in the output directory. By default uv creates one to exclude build artifacts from version control. |

### Workspace / multi-package targeting

| Flag | Effect |
|---|---|
| `--package <name>` | Build a specific member of the workspace. The workspace is discovered from `SRC` or the current directory. Exits with an error if the member does not exist. |
| `--all-packages`, `--all` | Build every member of the workspace. Same discovery logic as `--package`. |

### Reproducibility: build constraints and hash enforcement

`--build-constraints` / `--build-constraint` / `-b <file>` constrains the versions of build
dependencies (those in `[build-system].requires`) used during the build. The file follows the
same format as a `requirements.txt` constraints file: it controls versions but does not
introduce packages on its own.

`--require-hashes` enforces that every build dependency matches a hash declared in the constraints
file. Combined with `--build-constraints`, this makes the build fully reproducible and tamper-evident.

Both flags can also be set via environment variables: `UV_BUILD_CONSTRAINT` and
`UV_REQUIRE_HASHES`.

### Source override

`--no-sources` ignores the `[tool.uv.sources]` table when resolving build dependencies, locking
against the standards-compliant package metadata instead of any workspace, Git, URL, or local path
sources. Use this before publishing to confirm the package builds correctly for consumers who do not
have access to your `tool.uv.sources` configuration.

Also settable via `UV_NO_SOURCES`.

### PEP 517 fast path override

`--force-pep517` always invokes the build backend through a full PEP 517 build environment. By
default, when the project uses the `uv_build` backend, uv skips creating an isolated virtual
environment and calls the build backend directly for speed. Pass `--force-pep517` to disable this
optimisation and always use the standard PEP 517 protocol.

### Preventing accidental publish to PyPI

This is not a `uv build` flag but a project metadata classifier. Add the following to
`pyproject.toml` to make PyPI reject the package if it is ever uploaded:

```toml
[project]
classifiers = ["Private :: Do Not Upload"]
```

This classifier causes PyPI to reject the upload. It has no effect on alternative registries and
does not replace access controls or token management.

## Examples

Build both sdist and wheel into `dist/`:

```bash
uv build
```

Build only a wheel from an existing sdist:

```bash
uv build dist/mypackage-1.0.0.tar.gz --wheel
```

Build into a custom directory, clearing stale artifacts first:

```bash
uv build --out-dir /tmp/artifacts --clear
```

Build a specific workspace member:

```bash
uv build --package my-lib
```

Build all workspace members:

```bash
uv build --all-packages
```

Verify the package builds without uv-specific sources (recommended before publishing):

```bash
uv build --no-sources
```

Reproducible build with pinned hashes for build dependencies:

```bash
# constraints.txt
# setuptools==68.2.2 --hash=sha256:b454a35605876da60632df1a60f736524eb73cc47bbc9f3f1ef1b644de74fd2a

uv build --build-constraint constraints.txt --require-hashes
```

Force the full PEP 517 path even for `uv_build` projects:

```bash
uv build --force-pep517
```

## Caveats / Common Mistakes

- **Always test with `--no-sources` before publishing.** The `[tool.uv.sources]` table is uv-only.
  Other tools (pip, build, CI installs) will not apply it, so a package that only builds with
  `tool.uv.sources` active will be broken for consumers.
- **`--build-constraints` does not install packages.** It only constrains versions of build
  dependencies that are already being fetched. A package not listed elsewhere will not be pulled in
  just because it appears in the constraints file.
- **`--require-hashes` requires exact pinning.** Every build dependency must be pinned to an exact
  version (e.g. `==1.0.0`) or specified via direct URL. Git dependencies, editable installs, and
  local directory dependencies are not supported under hash-checking mode.
- **The `Private :: Do Not Upload` classifier only works on PyPI.** Alternative registries may
  accept the upload regardless of this classifier. Pair it with per-project API tokens and
  `uv publish --index <name>` targeting to prevent accidental uploads.
- **`--force-pep517` is slower.** The fast path for `uv_build` avoids spinning up an isolated
  environment. Only use `--force-pep517` when debugging build backend behaviour or when the fast
  path produces unexpected results.

## See Also

- bp-build-publish
- bp-uv-build-backend
- bp-build-system-config
- dep-sources
- project-workspaces
