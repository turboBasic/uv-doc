---
id: pip-inspect
title: uv pip list / freeze / show / check — inspecting environments
category: pip
tags: [command, pip, dependency, troubleshooting]
source: https://docs.astral.sh/uv/pip/inspection/
related: [pip-install, pip-sync, pip-compatibility, pip-tree, ts-resolution-conflict]
---

## Summary

Four read-only commands for auditing a virtual environment: `uv pip list` enumerates
installed packages in tabular or machine-readable form, `uv pip freeze` emits a
`requirements.txt`-compatible snapshot, `uv pip show` prints per-package metadata, and
`uv pip check` validates the environment for dependency conflicts and missing packages.

## Syntax / Usage

```bash
uv pip list [--format columns|freeze|json] [--outdated] [--editable] [--exclude <pkg>]
uv pip freeze [--exclude <pkg>] [--exclude-editable]
uv pip show [--files] <package> [<package> ...]
uv pip check
```

## Details

### uv pip list

Lists all packages installed in the active or discovered virtual environment in a
human-readable two-column table (name, version) by default.

Output format is controlled by `--format`:

- `columns` (default): aligned table suitable for reading in a terminal.
- `freeze`: one `name==version` per line, identical to `uv pip freeze` output.
- `json`: machine-readable array of `{"name": ..., "version": ...}` objects.

`--outdated` augments the output with the latest available version of each package.
Only packages that have a newer version on the index are shown; up-to-date packages are
omitted.

`--editable` / `-e` restricts output to editable installs only.
`--exclude <pkg>` removes a specific package from output.
`--exclude-editable` removes editable packages from the listing.

### uv pip freeze

Prints installed packages in `requirements.txt` pin format (`name==version`), one per
line. Suitable for capturing the current environment state to a file:

```bash
uv pip freeze > requirements.txt
```

`--exclude <pkg>` omits a named package; `--exclude-editable` strips editable entries
from the output.

### uv pip show

Prints package metadata sourced from the installed `METADATA` file. Fields displayed
include: Name, Version, Location, Requires-Python, Summary, Author, License, Homepage,
Requires (runtime dependencies), Required-By (reverse dependencies).

Multiple packages can be passed in a single invocation. `--files` / `-f` additionally
lists every file installed by the package.

### uv pip check

Scans the environment and reports any of the following diagnostics:

- A package has no `METADATA` file or the file cannot be parsed.
- A package's `Requires-Python` does not match the running interpreter's version.
- A package depends on another package that is not installed.
- A package depends on another package that is installed at an incompatible version.
- Multiple versions of the same package are installed in the environment.

Exits with a non-zero status code when any issue is found, making it suitable for use
in CI pipelines. `uv pip check` will surface the multiple-versions-installed diagnostic
that `pip check` does not.

### Package name normalization

All four commands display package names in their
[PEP 503-normalized](https://packaging.python.org/en/latest/specifications/name-normalization/)
form (lowercase, hyphens). This differs from `pip`, which preserves the verbatim name
as published on the registry. For example, `docstring_parser` appears as
`docstring-parser`, and `PyMuPDFb` appears as `pymupdfb`.

## Examples

```bash
# List all packages in default tabular form
uv pip list

# Machine-readable JSON output
uv pip list --format json

# Show only editable installs
uv pip list --editable

# Show outdated packages with their latest available versions
uv pip list --outdated

# Capture a requirements.txt snapshot of the current environment
uv pip freeze > constraints.txt

# Exclude a package from the freeze output
uv pip freeze --exclude pip

# Show metadata for a single package
uv pip show flask

# Show metadata and installed file list for multiple packages
uv pip show --files flask werkzeug

# Validate the environment for conflicts and missing deps
uv pip check
```

## Caveats / Common Mistakes

- `uv pip list` and `uv pip freeze` will also list `.egg-info`- and
  `.egg-link`-style distributions that are already present in the environment, but uv
  cannot install new ones of those types.
- Package names in all output are PEP 503-normalized. Scripts that parse the output
  and compare against verbatim PyPI names (e.g., `PyMuPDFb`) must account for the
  normalized form (`pymupdfb`).
- `uv pip check` may report diagnostics that `pip check` would not (e.g., multiple
  versions of the same package installed), and may also miss diagnostics that `pip check`
  surfaces, as coverage is not identical.
- Conflicts detected by `uv pip check` can arise when packages are installed in
  separate `uv pip install` invocations without a combined resolution step — use
  `uv pip sync` with a compiled requirements file to prevent this.

## See Also

- pip-install
- pip-sync
- pip-compatibility
- pip-tree
- ts-resolution-conflict
