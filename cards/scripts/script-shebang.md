---
id: script-shebang
title: Shebang and executable scripts
category: scripts
tags: [script, command, python, integration]
source: https://docs.astral.sh/uv/guides/scripts/
related: [script-inline-metadata, script-run-basic, script-with-deps, cmd-run, script-python-version]
---

## Summary

Adding a shebang line to a Python script lets you execute it directly on Unix without
invoking `uv run` explicitly. On Windows, the `--gui-script` flag achieves windowless
execution via `pythonw.exe`.

## Syntax / Usage

```bash
# Unix shebang (first line of script file)
#!/usr/bin/env -S uv run --script

# Make executable, then run directly
chmod +x <script>
./<script>

# Windows: GUI (windowless) execution
uv run --gui-script <script.pyw>
```

## Details

**The shebang line.** `#!/usr/bin/env -S uv run --script` uses `env`'s `-S` flag to
split the arguments, passing `uv run --script` as the interpreter for the file. When
the kernel executes the script, it effectively runs `uv run --script <path>`.

**`--script` / `-s` flag behavior.** This flag tells uv to parse the given path as a
PEP 723 script, irrespective of its file extension. Without the flag, uv infers
script mode from the `.py` extension; with `--script` any extension (or no extension)
forces PEP 723 metadata parsing. This is why scripts intended to live on `PATH` without
a `.py` extension still get their inline metadata recognized.

**`chmod +x` requirement.** The script must be marked executable before the OS will
invoke the shebang. Without it, `./greet` fails with a permission error.

**Combining shebang with inline metadata.** A PEP 723 `# /// script` block can appear
immediately after the shebang line. uv respects `dependencies` and `requires-python`
declared there, resolving and installing them before running the script — no separate
`uv add` step needed for distribution.

**`--gui-script` on Windows.** The `--gui-script` flag runs the script with
`pythonw.exe` instead of `python.exe`, suppressing the console window. Like
`--script`, it forces PEP 723 parsing regardless of file extension. This flag is only
available on Windows; on Unix, `.pyw` detection and `--gui-script` have no effect.

## Examples

Minimal executable script with no dependencies:

```python
#!/usr/bin/env -S uv run --script

print("Hello, world!")
```

```bash
chmod +x greet
./greet
# Hello, world!
```

Executable script with inline metadata (dependencies resolved automatically):

```python
#!/usr/bin/env -S uv run --script
#
# /// script
# requires-python = ">=3.12"
# dependencies = ["httpx"]
# ///

import httpx

print(httpx.get("https://example.com"))
```

```bash
chmod +x fetch
./fetch
```

Windows GUI script (windowless, no console):

```powershell
uv run --gui-script example.pyw
```

## Caveats / Common Mistakes

- `env -S` is required to split the multi-word argument `uv run --script`. Without
  `-S`, the entire string `uv run --script` is treated as a single executable name and
  the shebang fails.
- Forgetting `chmod +x` results in a "Permission denied" error when executing the
  script directly.
- `--gui-script` is Windows-only; passing it on Linux or macOS will cause an error.
- The `--script` flag in the shebang forces PEP 723 parsing — if the file has no
  inline metadata block, uv still runs it but treats dependencies as empty.

## See Also

- script-inline-metadata
- script-run-basic
- script-with-deps
- cmd-run
- script-python-version
