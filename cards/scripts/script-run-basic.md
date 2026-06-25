---
id: script-run-basic
title: Running scripts with uv run
category: scripts
tags: [script, command, python]
source: https://docs.astral.sh/uv/guides/scripts/
related: [cmd-run, script-inline-metadata, script-with-deps, script-shebang, project-run]
---

## Summary

`uv run` executes a Python script in an isolated environment without requiring a
pre-existing virtualenv or project. It handles scripts with no dependencies, scripts
that receive arguments, and scripts read from stdin.

## Syntax / Usage

```bash
uv run <script.py> [args...]   # run a script with optional arguments
uv run -                        # read script from stdin
uv run --no-project <script.py> # skip project discovery
```

## Details

When `uv run` is invoked with a `.py` file, uv finds an appropriate Python interpreter
and runs the script. No environment setup is required from the user.

**No-dependency scripts.** Scripts that only use the standard library run as-is. uv
does not install anything.

**Passing arguments.** Any arguments after the script name are forwarded to the script
unchanged via `sys.argv`.

**Reading from stdin.** Passing `-` as the script name tells uv to read the script
from standard input. Both a pipe and a shell here-document are supported.

**Project discovery.** When run inside a directory that contains a `pyproject.toml`,
uv installs the current project into the environment before running the script. Use
`--no-project` (alias `--no_workspace`) to skip this and run in an isolated, ephemeral
environment instead. The flag must appear **before** the script name. The environment
variable `UV_NO_PROJECT=1` provides the same effect. If a virtual environment is
already active, it is used regardless.

**GUI scripts on Windows.** Scripts with a `.pyw` extension are executed via `pythonw`
rather than `python`, suppressing the console window. This applies to both dependency-free
and `--with`-dependency invocations.

## Examples

Run a script with no dependencies:

```bash
uv run example.py
```

Pass arguments to the script:

```bash
uv run example.py hello world!
```

Read a script from stdin via pipe:

```bash
echo 'print("hello world!")' | uv run -
```

Read a script from a here-document:

```bash
uv run - <<EOF
print("hello world!")
EOF
```

Skip project installation when inside a project directory:

```bash
# --no-project must come before the script name
uv run --no-project example.py
```

Run a Windows GUI script (no console window):

```powershell
uv run example.pyw
```

## Caveats / Common Mistakes

- `--no-project` must be placed **before** the script name on the command line; placing
  it after the script name causes it to be passed as a script argument instead.
- Inside a project directory, uv installs the project by default even if the script
  does not use it; use `--no-project` to avoid the overhead when the script is
  independent of the project.
- Scripts with inline PEP 723 metadata automatically skip project dependencies — the
  `--no-project` flag is not needed in that case.

## See Also

- cmd-run
- script-inline-metadata
- script-with-deps
- script-shebang
- project-run
