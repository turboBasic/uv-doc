---
id: cmd-venv
title: uv venv — create a virtual environment
category: commands
tags: [command, venv, python, pip]
source: https://docs.astral.sh/uv/reference/cli/#uv-venv
related: [pip-install, pip-environments, python-versions, concept-project-environment, cmd-sync]
---

## Summary

`uv venv` creates a virtual environment at a given path (default `.venv`) and is the
standalone venv creation command used in the pip-compatible workflow. The project
interface (`uv sync`, `uv run`) manages its own environment automatically; `uv venv`
is for explicit control.

## Syntax / Usage

```bash
uv venv [OPTIONS] [PATH]
```

## Details

By default, `uv venv` creates `.venv` in the working directory. An alternative path
can be provided positionally. If the target path already exists and is non-empty, uv
exits with an error unless `--allow-existing`, `--clear`, or `--force` is used.

When run inside a project, uv reads `pyproject.toml` and `.python-version` files to
apply Python version constraints. Use `--no-project` to skip project discovery entirely.

Key flags:

- `--python`, `-p` — specify the Python interpreter. Accepts a version string (`3.11`),
  a path, or any format supported by `uv python` (e.g., `cpython@3.12`). uv will
  download the requested Python if it is not already installed.
- `--seed` — install seed packages (`pip`, `setuptools`, `wheel`) into the environment.
  On Python 3.12+, `setuptools` and `wheel` are not included.
- `--prompt` — set an alternative prompt prefix shown when the environment is activated.
  Defaults to the directory name of the created venv. Pass `"."` to always use the
  current working directory name.
- `--system-site-packages` — grant the venv access to the system site-packages at
  runtime. Unlike `pip`, uv commands (`uv pip list`, `uv pip install`) will still
  ignore system site-packages when operating on this venv.
- `--relocatable` — write relative paths in entrypoints and activation scripts so the
  venv can be moved without breaking. Only `console_scripts`/`gui_scripts` are fully
  guaranteed; binaries are left as-is.
- `--clear`, `-c` — remove any existing contents at the target path before creating the
  new environment. Also settable via `UV_VENV_CLEAR`.
- `--allow-existing` — write into the target path without clearing it first. Can cause
  unexpected behavior if the existing venv was linked to a different Python interpreter.
- `--force` — allow `--clear` to remove a non-virtual-environment directory (removes
  all files and directories at the target path).

**Automatic venv discovery:** when running `uv pip install` or `uv pip sync`, uv looks
for a venv in this order: `VIRTUAL_ENV` env var, `CONDA_PREFIX` env var, then `.venv`
in the current or any parent directory. If none is found, uv prompts the user to run
`uv venv`.

**Project environment override:** when inside a project root, the default `.venv` name
can be changed by setting `UV_PROJECT_ENVIRONMENT` to an alternative path.

## Examples

```bash
# Create .venv in the current directory, then install into it
uv venv
uv pip install httpx

# Specify a Python version
uv venv --python 3.11

# Named environment with seed packages
uv venv .venv-test --seed

# Custom prompt shown on activation
uv venv --prompt myproject

# Relocatable environment (e.g. for packaging into a Docker image)
uv venv --relocatable /opt/app/.venv

# Recreate an existing environment from scratch
uv venv --clear

# Allow adding to an existing environment without wiping it
uv venv --allow-existing
```

## Caveats / Common Mistakes

- `--allow-existing` is unsafe if the existing venv and the new one target different
  Python versions — entrypoints may be silently broken.
- `--system-site-packages` only affects runtime visibility; uv commands continue to
  operate as if system packages do not exist. Do not use it expecting `uv pip list` to
  show system packages.
- `--seed` does not install `setuptools` or `wheel` on Python 3.12+ — tools that
  require them must declare an explicit dependency.
- `uv venv` is for the pip-compatible workflow. The project interface (`uv sync`,
  `uv run`) creates and manages the project environment automatically; calling
  `uv venv` manually in a project directory is rarely needed and can interfere with
  `UV_PROJECT_ENVIRONMENT` expectations.

## See Also

- pip-install
- pip-environments
- python-versions
- concept-project-environment
- cmd-sync
