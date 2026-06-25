---
id: script-lockfile
title: Locking script dependencies
category: scripts
tags: [script, lockfile, command, dependency, resolution]
source: https://docs.astral.sh/uv/guides/scripts/
related: [script-inline-metadata, script-reproducibility, cmd-lock, cmd-run, concept-lockfile]
---

## Summary

`uv lock --script` produces a `<script>.lock` file that pins every transitive
dependency for a PEP 723 script. Once a lockfile exists, subsequent script
commands consume it to guarantee reproducible installs.

## Syntax / Usage

```bash
# Create or update the lockfile for a script
uv lock --script <script.py>

# Run using pinned lockfile versions (fail if stale or missing)
uv run --locked --script <script.py>

# Run using lockfile versions without checking staleness (fail if missing)
uv run --frozen --script <script.py>

# Other commands that consume the script lockfile
uv sync    --script <script.py>
uv export  --script <script.py>
uv tree    --script <script.py>
uv check   --script <script.py>
uv audit   --script <script.py>   # requires lockfile to exist
```

## Details

Unlike projects, scripts are **not** locked automatically. A lockfile is only
created when you explicitly run `uv lock --script`. The lockfile is written
adjacent to the script with the name `<script>.lock` (e.g., `example.py.lock`).

The lockfile format is the same `uv.lock` format used by projects.

**How commands consume the lockfile**

Once `example.py.lock` is present, the following commands reuse its pinned
versions and update the lockfile if the script's inline metadata has changed:

| Command | Behaviour when lockfile present | Behaviour when lockfile absent |
|---|---|---|
| `uv run --script` | Uses locked versions, updates if stale | Resolves fresh, no lockfile written |
| `uv sync --script` | Uses locked versions, updates if stale | Syncs from fresh resolution |
| `uv export --script` | Exports locked versions, updates if stale | Exports from fresh resolution, no lockfile written |
| `uv tree --script` | Shows locked dependency tree, updates if stale | Shows tree from fresh resolution |
| `uv check --script` | Uses locked environment | Uses fresh resolution |
| `uv audit --script` | Reads lockfile directly | **Errors** — lockfile is required |

**`--locked` flag**

Asserts the lockfile is up-to-date. If the lockfile is missing or would change
after re-resolution, uv exits with a non-zero error. Use this in CI to prevent
accidental drift.

**`--frozen` flag**

Skips the staleness check entirely and treats the lockfile as the source of
truth. If the lockfile is missing, uv exits with an error. If the script's
inline metadata has diverged from the lockfile, the locked (older) versions are
used — no warning is emitted.

`--frozen` implies `--locked` is not needed and is faster because no resolution
is performed; it is the right choice when reproducibility is required and the
lockfile is known to be current.

Both `--locked` and `--frozen` are also settable via environment variables:
`UV_LOCKED=1` and `UV_FROZEN=1`.

## Examples

Lock a script and then run it with strict lockfile enforcement:

```bash
# Initial lock
uv lock --script fetch_data.py

# Verify the lockfile is committed and up-to-date before running
uv run --locked fetch_data.py

# Run in a deployment context where updates are forbidden
uv run --frozen fetch_data.py
```

Export a locked script's dependencies to `requirements.txt`:

```bash
uv lock --script report.py
uv export --script report.py -o requirements.txt
```

Audit a locked script for known vulnerabilities:

```bash
uv lock --script pipeline.py
uv audit --script pipeline.py
```

CI check that the lockfile is not stale:

```bash
uv lock --check --script pipeline.py
```

## Caveats / Common Mistakes

- `uv audit --script` **requires a lockfile** — it will error if no
  `<script>.lock` file exists. Always run `uv lock --script` first.
- When no lockfile is present, `uv export --script` and `uv tree --script`
  still function but resolve fresh each time and do not persist a lockfile.
- `--locked` and `--frozen` apply to the **script's** lockfile, not a
  surrounding project's `uv.lock`. A script with inline metadata ignores the
  project lockfile regardless.
- The lockfile is written adjacent to the script. If the script is in a
  read-only directory, `uv lock --script` will fail.
- Script locking was introduced in uv 0.6.3. Earlier versions do not support
  `uv lock --script`.

## See Also

- script-inline-metadata
- script-reproducibility
- cmd-lock
- cmd-run
- concept-lockfile
