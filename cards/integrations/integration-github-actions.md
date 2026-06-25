---
id: integration-github-actions
title: Using uv in GitHub Actions
category: integrations
tags: [integration, ci, installation, python, cache, publish, authentication]
source: https://docs.astral.sh/uv/guides/integration/github/
related: [concept-lockfile, python-versions, bp-trusted-publishing, config-git-auth, cmd-sync]
---

## Summary

The `astral-sh/setup-uv` action installs uv in GitHub Actions workflows, handles Python
setup, and optionally manages the package cache. Combined with `uv sync --locked` and
`uv run`, it provides fully reproducible CI builds with minimal configuration.

## Syntax / Usage

```yaml
- name: Install uv
  uses: astral-sh/setup-uv@08807647e7069bb48b6ef5acd8ec9567f424441b # v8.1.0
  with:
    version: "0.11.24"       # pin to a specific uv version
    python-version: "3.12"   # optional: set Python version
    enable-cache: true        # optional: persist uv cache between runs
```

## Details

**Installation**: `astral-sh/setup-uv` installs uv, adds it to PATH, and supports all
uv-supported platforms. Pin both the action SHA and the uv `version` input for
reproducible builds.

**Python setup**: Three options, in order of preference:

1. `uv python install` in a run step — respects the version pinned in `.python-version`
   or `pyproject.toml`.
2. `actions/setup-python` with `python-version-file: ".python-version"` — faster
   because GitHub caches Python versions alongside the runner.
3. `actions/setup-python` with `python-version-file: "pyproject.toml"` — uses the
   latest version matching `requires-python`.

**Matrix builds**: Pass `python-version: ${{ matrix.python-version }}` to `setup-uv`;
this overrides any pin in the project files. Alternatively set the `UV_PYTHON`
environment variable at the job level.

**Syncing and running**: Use `uv sync --locked` to install the project from the committed
lockfile, then `uv run <command>` to execute in the managed environment. The
`UV_PROJECT_ENVIRONMENT` setting can redirect the install to the system Python
environment instead of creating a virtualenv.

**Cache management**: `setup-uv` with `enable-cache: true` is the simplest path. For
manual control, set `UV_CACHE_DIR` to a fixed path and use `actions/cache` keyed on
`uv.lock` (or `requirements.txt` when using `uv pip`). After installing, run
`uv cache prune --ci` to trim the cache to what was actually used.

Self-hosted non-ephemeral runners require special handling: set `UV_CACHE_DIR` to a
path inside `${{ github.workspace }}` and clean it with a post-job hook script that
calls `uv cache clean`.

**`uv pip` with system Python**: The `uv pip` interface requires a virtual environment
by default. Set `UV_SYSTEM_PYTHON: 1` at workflow, job, or step scope to allow
installing into the system environment. Use `--no-system` to opt back out in individual
invocations.

**Private GitHub repos**: Create a PAT with read access to the private repositories,
store it as a repository secret, then configure the Git credential helper via the `gh`
CLI (pre-installed on GitHub Actions runners):

```yaml
- run: echo "${{ secrets.MY_PAT }}" | gh auth login --with-token
- run: gh auth setup-git
```

**Publishing to PyPI**: Use `uv build` then `uv publish` with OIDC trusted publishing —
no credentials needed. Requires a `pypi` environment in the repo with
`permissions: id-token: write` and a matching trusted publisher configured on PyPI.

## Examples

Minimal CI workflow (sync + test):

```yaml
name: CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6

      - name: Install uv
        uses: astral-sh/setup-uv@08807647e7069bb48b6ef5acd8ec9567f424441b # v8.1.0
        with:
          version: "0.11.24"
          enable-cache: true

      - name: Install the project
        run: uv sync --locked --all-extras --dev

      - name: Run tests
        run: uv run pytest tests
```

Matrix build across Python versions:

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: ["3.10", "3.11", "3.12"]
    steps:
      - uses: actions/checkout@v6

      - name: Install uv and set Python version
        uses: astral-sh/setup-uv@08807647e7069bb48b6ef5acd8ec9567f424441b # v8.1.0
        with:
          version: "0.11.24"
          python-version: ${{ matrix.python-version }}

      - run: uv sync --locked
      - run: uv run pytest tests
```

PyPI publish on tag push (trusted publishing):

```yaml
name: Publish release to PyPI

on:
  push:
    tags:
      - v*

jobs:
  run:
    runs-on: ubuntu-latest
    environment:
      name: pypi
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v6

      - name: Install uv
        uses: astral-sh/setup-uv@08807647e7069bb48b6ef5acd8ec9567f424441b # v8.1.0

      - name: Install Python 3.13
        run: uv python install 3.13

      - name: Build
        run: uv build

      - name: Smoke test (wheel)
        run: uv run --isolated --no-project --with dist/*.whl tests/smoke_test.py

      - name: Smoke test (source distribution)
        run: uv run --isolated --no-project --with dist/*.tar.gz tests/smoke_test.py

      - name: Publish
        run: uv publish
```

Manual cache management with `actions/cache`:

```yaml
jobs:
  install_job:
    env:
      UV_CACHE_DIR: /tmp/.uv-cache
    steps:
      - uses: actions/checkout@v6

      - name: Install uv
        uses: astral-sh/setup-uv@08807647e7069bb48b6ef5acd8ec9567f424441b # v8.1.0

      - name: Restore uv cache
        uses: actions/cache@v5
        with:
          path: /tmp/.uv-cache
          key: uv-${{ runner.os }}-${{ hashFiles('uv.lock') }}
          restore-keys: |
            uv-${{ runner.os }}-${{ hashFiles('uv.lock') }}
            uv-${{ runner.os }}

      - run: uv sync --locked

      - name: Minimize uv cache
        run: uv cache prune --ci
```

## Caveats / Common Mistakes

- Not pinning the `version` input to `setup-uv` means the uv version can change between
  runs and break reproducibility. Pin both the action SHA and the `version` input.
- Using `uv pip install` without `UV_SYSTEM_PYTHON: 1` or an active virtualenv will
  fail because `uv pip` requires an environment target by default.
- When caching manually with `actions/cache`, key on `uv.lock` for the project
  interface, but on `requirements.txt` when using `uv pip compile` output.
- Self-hosted non-ephemeral runners: the default cache directory grows unbounded if
  never cleaned. Move the cache into the workspace and clean it with a post-job hook.
- Trusted publishing requires the `pypi` GitHub environment to exist in repo settings
  and a matching trusted publisher entry on PyPI — both must be configured before the
  first publish.

## See Also

- concept-lockfile
- python-versions
- bp-trusted-publishing
- config-git-auth
- cmd-sync
