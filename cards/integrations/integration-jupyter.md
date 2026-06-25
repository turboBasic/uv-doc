---
id: integration-jupyter
title: Using uv with Jupyter
category: integrations
tags: [integration, venv, tool, project, pip]
source: https://docs.astral.sh/uv/guides/integration/jupyter/
related: [cmd-run, tool-run, cmd-venv, project-run, pip-install]
---

## Summary

uv integrates with Jupyter in multiple modes: running Jupyter Lab against a project's virtual
environment via `uv run --with jupyter`, registering a per-project ipykernel for isolated package
installs, running Jupyter as a standalone `uvx` tool, and using a bare `uv pip`-managed venv when
no project exists.

## Syntax / Usage

```console
# Run Jupyter Lab against the current project's venv
$ uv run --with jupyter jupyter lab

# Run Jupyter as a standalone tool (no project required)
$ uv tool run jupyter lab          # or: uvx jupyter lab

# Register a project kernel
$ uv add --dev ipykernel
$ uv run ipython kernel install --user --env VIRTUAL_ENV $(pwd)/.venv --name=project
```

## Details

**Within a project (`uv run --with jupyter`):**
`uv run --with jupyter jupyter lab` starts the Jupyter server in an isolated environment while the
project's virtual environment is active for imports. Notebooks can `import` any package that is in
the project's `.venv` without additional configuration. The Jupyter server itself is not installed
into the project.

**Creating a kernel for package management:**
When notebooks need to install packages at runtime, register a named kernel tied to the project's
`.venv`. The kernel ensures `!uv add` and `!uv pip install` target the correct environment. Install
`ipykernel` as a dev dependency, then register it with `ipython kernel install --user
--env VIRTUAL_ENV $(pwd)/.venv --name=<name>`. After selecting the kernel in the UI, use:

- `!uv add <pkg>` — adds the package to `pyproject.toml` and `uv.lock`, installs it into `.venv`.
- `!uv pip install <pkg>` — installs into `.venv` only, no lockfile update.

**Without a kernel:**
`!uv add` still modifies the project's environment. However, `!uv pip install` targets the Jupyter
server's isolated environment, not the project's `.venv`, so installs persist only for the lifetime
of the server process.

**`%pip` magic / `--seed`:**
`%pip install` works when `pip` is present inside the project's `.venv`. Run `uv venv --seed` before
starting the server to include `pip`, `setuptools`, and `wheel` in the venv. Packages installed this
way are not reflected in `pyproject.toml` or `uv.lock`.

**Standalone tool (no project):**
`uv tool run jupyter lab` (or `uvx jupyter lab`) launches a fully isolated Jupyter server. Useful
for ad-hoc notebooks with no project context.

**Non-project venv:**
For a venv without a `pyproject.toml` or `uv.lock`, install Jupyter directly and launch from the
venv:

```console
$ uv venv --seed
$ uv pip install jupyterlab
$ .venv/bin/jupyter lab          # macOS/Linux
```

**VS Code kernel setup:**
VS Code requires `ipykernel` in the project environment. Add it as a dev dependency or install with
`uv pip install ipykernel`. Open the project in VS Code, create a new Jupyter notebook, and select
the `.venv` interpreter when prompted. To use `!uv add` from inside a VS Code notebook, also add
`uv` as an explicit dev dependency (`uv add --dev uv`).

## Examples

```console
# Start Jupyter Lab against a project
$ uv run --with jupyter jupyter lab

# Register a project kernel, then start Jupyter
$ uv add --dev ipykernel
$ uv run ipython kernel install --user --env VIRTUAL_ENV $(pwd)/.venv --name=myproject
$ uv run --with jupyter jupyter lab
# In notebook: select "myproject" kernel, then:
# !uv add pandas          -> updates pyproject.toml + uv.lock
# !uv pip install pandas  -> installs into .venv without lockfile update

# Enable %pip magic inside a project venv
$ uv venv --seed
$ uv run --with jupyter jupyter lab
# In notebook: %pip install pandas  (installs into project venv, no lockfile update)

# Standalone ad-hoc notebook
$ uvx jupyter lab

# Non-project venv (macOS/Linux)
$ uv venv --seed
$ uv pip install jupyterlab pydantic
$ .venv/bin/jupyter lab

# VS Code setup
$ uv init myproject
$ cd myproject
$ uv add --dev ipykernel
$ code .
# In VS Code: "Create: New Jupyter Notebook", then select .venv/bin/python as kernel
```

## Caveats / Common Mistakes

- **`!uv pip install` without a kernel targets Jupyter's env, not the project's `.venv`.** Installed
  packages disappear when the server restarts. Use a registered kernel or `!uv add` if the project
  env is the target.
- **`%pip` requires `pip` in the venv.** uv venvs do not include `pip` by default. Run
  `uv venv --seed` first, or use `!uv add` / `!uv pip install` instead of `%pip`.
- **VS Code `!uv add` requires `uv` in the project env.** Add it explicitly with `uv add --dev uv`;
  otherwise the shell command may not resolve `uv` from inside the kernel.
- **`ipykernel` version alignment.** The kernel registration command (`ipython kernel install`) must
  be run via `uv run` so it uses the project's Python, not a system Python.
- **Kernel registered to wrong venv.** Always pass `--env VIRTUAL_ENV $(pwd)/.venv` to bind the
  kernel to the project's exact venv path.

## See Also

- cmd-run
- tool-run
- cmd-venv
- project-run
- pip-install
