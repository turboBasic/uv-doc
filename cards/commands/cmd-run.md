---
id: cmd-run
title: uv run — execute commands in the project environment
category: commands
tags: [command, project, venv, script]
source: https://docs.astral.sh/uv/concepts/projects/run/
related: [concept-lockfile, project-structure, script-inline-metadata, tool-run, pip-install]
---

## Summary

`uv run` executes a command or script inside the project's virtual environment,
first ensuring that environment is up-to-date with the lockfile. It is the primary
way to run project code without manually activating `.venv`.

## Syntax / Usage

```bash
uv run [OPTIONS] <COMMAND> [ARGS]...
uv run <SCRIPT.py>
```

## Details

Before running, `uv run` resolves and locks dependencies if needed, then syncs the
project environment so the command sees the correct dependency versions — no manual
`source .venv/bin/activate` required.

Key flags:

- `--with <pkg>` — add a package (optionally pinned, e.g. `--with rich==13.7.0`) for
  this invocation only, without modifying `pyproject.toml`.
- `--no-sync` — run without syncing the environment first.
- `--frozen` — use the existing lockfile without checking whether it is up-to-date.
- `--locked` — error if the lockfile is out of date instead of updating it.
- `--isolated` — run in a fresh, isolated environment.
- `-m, --module` — run a module, like `python -m`.
- `--env-file <path>` — load environment variables from a file before running.

When the target is a script with PEP 723 inline metadata, uv runs it in an isolated
environment built from the script's own declared dependencies, ignoring the project.

On Unix, uv forwards most signals to the child process (except `SIGKILL`, `SIGCHLD`,
`SIGIO`, `SIGPOLL`).

## Examples

```bash
# Run a project entry point or installed CLI
uv run my-cli --help

# Run a Python module
uv run python -c "import httpx; print(httpx.__version__)"
uv run -m pytest

# Add a one-off dependency just for this run
uv run --with rich python script.py

# Use the lockfile as-is, fail if stale (good for CI)
uv run --locked pytest
```

## Caveats / Common Mistakes

- `uv run` always operates on the *project* environment. To run a standalone CLI tool
  in isolation from the project, use `uvx` / `uv tool run` instead.
- Use `--frozen`/`--locked` in CI to make runs deterministic; without them uv may
  re-resolve and update `uv.lock`.

## See Also

- concept-lockfile
- project-structure
- tool-run
- script-inline-metadata
- pip-install
