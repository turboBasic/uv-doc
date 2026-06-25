---
id: project-run
title: Running commands in a project with uv run
category: projects
tags: [command, project, venv, lockfile, workspace, script]
source: https://docs.astral.sh/uv/concepts/projects/run/
related: [cmd-run, project-sync-lock, project-workspaces, concept-lockfile, script-inline-metadata]
---

## Summary

`uv run` executes a command inside the project's virtual environment, automatically
locking and syncing before the run so the environment is always up-to-date. It is the
primary way to invoke project code without manually activating `.venv`.

## Syntax / Usage

```bash
uv run [OPTIONS] <COMMAND|SCRIPT> [ARGS]...
```

## Details

### Auto-sync before run

When `uv run` is invoked inside a project, uv locks the project (if the lockfile is
outdated) and syncs the environment before passing control to the command. This means
a clean checkout with no `.venv` works immediately — the environment is created on the
first `uv run`.

The project environment is isolated from the current shell, so commands that require
project packages must be invoked through `uv run` rather than relying on whatever is
active in the terminal.

By default `uv run` uses inexact syncing — it installs missing packages but does not
remove extraneous ones. Use `--exact` to also remove packages not in the lockfile.

### What can be run

- **Entry points and installed scripts** defined in `pyproject.toml`'s `[project.scripts]`
- **Arbitrary shell commands** that benefit from the project environment being available
  (e.g., `uv run bash scripts/foo.sh`)
- **Python scripts** passed directly by filename: `uv run file.py` is equivalent to
  `uv run python file.py`
- **Python modules** via `-m`/`--module`: `uv run -m pytest`

### Scripts with inline metadata (PEP 723)

When the target file contains a `# /// script` block, uv runs it in an **isolated,
ephemeral environment** built from the script's own declared dependencies. The project
environment is not used. See the `script-inline-metadata` card for the full workflow.

### `--with` — per-invocation extra dependencies

`--with <pkg>` layers additional packages on top of the project environment for a
single invocation. These extras go into a separate ephemeral environment; they are
allowed to conflict with the project's own requirements because they shadow them:

```bash
uv run --with httpx==0.26.0 python -c "import httpx; print(httpx.__version__)"
```

Multiple `--with` flags are accepted. `--with-requirements <file>` accepts a
requirements.txt, a `.py` file with inline metadata, or a `pylock.toml` file. Using
`pyproject.toml`, `setup.py`, or `setup.cfg` is not supported.

### `--isolated` — fully isolated run

`--isolated` forces a fresh environment for the project itself, enforcing strict
isolation between what is declared and what is installed. An editable install of the
project is still used. When combined with `--with`, the extra dependencies are still
layered in a second environment on top.

### `--package` — targeting a workspace member

In a workspace, `uv run` defaults to the workspace root. Pass `--package <name>` to
run the command in the context of a specific member:

```bash
uv run --package bird-feeder pytest
```

uv will error if the named package is not a workspace member. `--all-packages` installs
all workspace members into the environment before running.

### Controlling sync and lockfile checks

| Flag | Behavior |
|---|---|
| *(none)* | Lock and sync if outdated |
| `--locked` | Assert lockfile is current; error if not |
| `--frozen` | Use lockfile as-is without checking; error if missing |
| `--no-sync` | Skip syncing entirely (implies `--frozen`) |

`--locked` is recommended in CI to catch accidental drift. `--frozen` trades safety
for speed when the lockfile is known-good. `--no-sync` skips the environment update
entirely and is the fastest option.

### Signal handling

uv does not exec into the child process; it retains control to provide better error
messages. Signal forwarding behavior:

- **Unix:** uv forwards most signals to the child, excluding `SIGKILL`, `SIGCHLD`,
  `SIGIO`, and `SIGPOLL`. Because terminals send `SIGINT` to the foreground process
  group on Ctrl-C, uv forwards `SIGINT` to the child only if sent more than once or
  the child's process group differs from uv's.
- **Windows:** Ctrl-C events are ignored by uv; the child process handles them and
  exits cleanly on its own.

### Legacy setuptools scripts on Windows

Scripts installed by setuptools into `.venv\Scripts` with `.ps1`, `.cmd`, or `.bat`
extensions are supported. The extension can be omitted — uv searches in that order:

```bash
uv run --with nuitka==2.6.7 -- nuitka --version
```

## Examples

```bash
# Run a project entry point
uv run my-cli --help

# Run a Python module (like python -m)
uv run -m pytest tests/

# Add a one-off dependency for this invocation only
uv run --with rich python -c "from rich import print; print('[bold]hello[/bold]')"

# Assert the lockfile is up-to-date (CI pattern)
uv run --locked pytest

# Use the lockfile as-is, skip freshness check (fast, offline-safe)
uv run --frozen python -m myapp.server

# Skip environment sync entirely
uv run --no-sync python -c "print('fast')"

# Run in a specific workspace member
uv run --package my-lib python -c "import my_lib; print(my_lib.__version__)"

# Force a fresh isolated environment for this run
uv run --isolated python -c "import sys; print(sys.prefix)"
```

## Caveats / Common Mistakes

- `--no-sync` implies `--frozen`. The lockfile is not re-evaluated; if it is missing
  uv exits with an error.
- `--with` dependencies are layered in a second ephemeral environment on top of the
  project environment, not merged into it. They can shadow project-pinned versions.
- Scripts with PEP 723 inline metadata are automatically run isolated from the project
  environment. Adding `--with` still layers into a separate environment on top of the
  script's own environment.
- `uv run` uses inexact syncing by default (unlike `uv sync` which is exact). Pass
  `--exact` if you need extraneous packages removed during the run.
- On Unix, a single Ctrl-C may not reach the child process if it shares uv's process
  group; press it twice or use `kill` if the child appears unresponsive.

## See Also

- cmd-run
- project-sync-lock
- project-workspaces
- concept-lockfile
- script-inline-metadata
