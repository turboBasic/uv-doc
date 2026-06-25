#!/usr/bin/env bash
set -euo pipefail

# Syncs uv documentation from upstream (astral-sh/uv) into src/.
# Mirrors every committed Markdown doc preserving structure, then best-effort
# generates the CLI / settings / environment reference files via the uv-dev
# `generate-all` tool (requires cargo + a compatible Rust toolchain). If cargo
# is missing or the build fails, those three files are skipped with a warning;
# the rest of the mirror is unaffected.

REPO_URL="https://github.com/astral-sh/uv.git"
DOCS_SUBDIR="docs"
GENERATED_REFS=(cli settings environment)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMPDIR_PREFIX="uv-docs-sync"

TARGET_DIR="$SCRIPT_DIR/src"

cleanup() {
  if [[ -n "${tmp_dir:-}" && -d "$tmp_dir" ]]; then
    rm -rf "$tmp_dir"
  fi
}
trap cleanup EXIT

have_cargo=0
if command -v cargo >/dev/null 2>&1; then
  have_cargo=1
fi

tmp_dir="$(mktemp -d -t "${TMPDIR_PREFIX}.XXXXXX")"
clone_dir="$tmp_dir/uv"

if [[ "$have_cargo" -eq 1 ]]; then
  # Full tree needed to build the uv-dev reference generator.
  echo "Cloning uv (shallow, full tree)..."
  git clone --depth 1 --filter=blob:none "$REPO_URL" "$clone_dir"
else
  echo "Cloning uv (shallow, docs only)..."
  git clone --depth 1 --filter=blob:none --sparse "$REPO_URL" "$clone_dir"
  git -C "$clone_dir" sparse-checkout set "$DOCS_SUBDIR"
fi

echo "Removing old docs from target..."
rm -rf "$TARGET_DIR"
mkdir -p "$TARGET_DIR"

echo "Copying committed Markdown files..."
src="$clone_dir/$DOCS_SUBDIR"
find "$src" -name "*.md" -type f | while read -r file; do
  rel="${file#"$src"/}"
  dest="$TARGET_DIR/$rel"
  mkdir -p "$(dirname "$dest")"
  cp "$file" "$dest"
done

if [[ "$have_cargo" -eq 1 ]]; then
  echo "Generating CLI / settings / environment reference (cargo build, may take several minutes)..."
  if (cd "$clone_dir" && cargo dev generate-all >/dev/null 2>&1); then
    mkdir -p "$TARGET_DIR/reference"
    for name in "${GENERATED_REFS[@]}"; do
      gen="$clone_dir/$DOCS_SUBDIR/reference/$name.md"
      if [[ -f "$gen" ]]; then
        cp "$gen" "$TARGET_DIR/reference/$name.md"
      else
        echo "WARNING: expected generated file missing: reference/$name.md" >&2
      fi
    done
    echo "Generated reference files synced."
  else
    echo "WARNING: reference generation failed (toolchain/build error)." >&2
    echo "         reference/{cli,settings,environment}.md were NOT generated;" >&2
    echo "         consult https://docs.astral.sh/uv/reference/ for those pages." >&2
  fi
else
  echo "NOTE: cargo not found — skipping generated reference files" >&2
  echo "      (reference/{cli,settings,environment}.md)." >&2
  echo "      Install Rust/cargo to mirror them, or see https://docs.astral.sh/uv/reference/." >&2
fi

count="$(find "$TARGET_DIR" -name "*.md" -type f | wc -l | tr -d ' ')"
echo "Done. $count Markdown files synced into src/."
