---
id: script-with-deps
title: One-off script dependencies with --with
category: scripts
tags: [script, dependency, command, python]
source: https://docs.astral.sh/uv/guides/scripts/
related: [script-inline-metadata, cmd-run, script-managing-deps, script-python-version, tool-with-from]
---

## Summary

`uv run --with <pkg>` injects extra packages into a single invocation without modifying the
script's inline metadata. Use it for quick experiments, one-off debugging, or when you cannot
edit the script file.

## Syntax / Usage

```bash
uv run --with <pkg> <script.py>
uv run --with '<pkg><version-constraint>' <script.py>
uv run --with <pkg1> --with <pkg2> <script.py>
uv run --with-requirements <requirements.txt> <script.py>
```

## Details

`--with <pkg>` accepts any PEP 508 dependency specifier, including version constraints
(`'rich>12,<13'`), extras, and URL requirements. Repeat the flag to add multiple packages.

`--with-requirements <file>` reads packages from a file. Supported formats are
`requirements.txt`, `.py` files with inline metadata, and `pylock.toml`. Using
`pyproject.toml`, `setup.py`, or `setup.cfg` is not allowed.

**How `--with` layers on top of existing environments:**

- Inside a project: the `--with` packages are installed in a separate, ephemeral environment
  layered on top of the project environment. They are allowed to conflict with the project's
  own dependencies.
- With a script that has inline metadata (PEP 723): `--with` supplements the script's declared
  dependencies; both sets are available at runtime.
- With `--no-project`: the invocation runs in an isolated environment populated solely by the
  `--with` requirements (plus any inline metadata in the script).
- With `--isolated`: the project still gets a fresh environment, but the `--with` packages are
  still layered in a second ephemeral environment on top of it.

The `-w` short form is an alias for `--with`.

## Examples

Run a script that needs `rich` without editing the file:

```bash
uv run --with rich example.py
```

Pin a specific version range:

```bash
uv run --with 'rich>12,<13' example.py
```

Inject multiple packages:

```bash
uv run --with httpx --with 'pydantic>=2' example.py
```

Load extra packages from a requirements file:

```bash
uv run --with-requirements dev-extras.txt example.py
```

Combine with `--no-project` to run entirely in isolation (no project dependencies):

```bash
uv run --no-project --with requests example.py
```

Add `--with` on top of a script that already has inline metadata:

```python
# /// script
# dependencies = ["rich"]
# ///
import rich, httpx  # httpx injected via --with at runtime
```

```bash
uv run --with httpx example.py
```

## Caveats / Common Mistakes

- `--with` packages are allowed to conflict with project dependencies; resolution for the
  `--with` layer is independent. This means you can get a different version than what the
  project uses, but it will not break the project environment.
- `--with-requirements` does not accept `pyproject.toml`, `setup.py`, or `setup.cfg` — only
  `requirements.txt`, `.py` files with inline metadata, and `pylock.toml`.
- `--with` adds packages for the current invocation only; it does not persist to the script's
  inline metadata. Use `uv add --script` to make a dependency permanent.
- When a script has PEP 723 inline metadata, the project's dependencies are ignored; only the
  script's declared dependencies (plus any `--with` packages) apply.

## See Also

- script-inline-metadata
- cmd-run
- script-managing-deps
- script-python-version
- tool-with-from
