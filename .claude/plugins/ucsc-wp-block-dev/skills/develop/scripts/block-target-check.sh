#!/bin/bash
# Inexpensive check that a path looks like a WordPress (Gutenberg) block code
# set, not just an arbitrary folder (ADR-093). Handles both repo layouts:
#   - ucsc-blocks:            src/blocks/<slug>/ with a block.json
#   - ucsc-gutenberg-blocks:  src/blocks/<Name>.js calling registerBlockType()
set -e

usage() {
  cat <<'EOF'
Usage: block-target-check.sh <path>

Cheaply verify that <path> (a directory or a single .js file) looks like a
WordPress block code set rather than an arbitrary folder (ADR-093).

A path PASSES when any of these hold:
  - it (or, for a directory, a file directly inside it) is a block.json, or
  - a JS file at <path> (or directly inside it) calls registerBlockType().

Prints the markers found and exits 0 on PASS, non-zero on FAIL. Only the path's
own level is inspected (maxdepth 1), so node_modules/build are not scanned.
EOF
}

case "${1:-}" in
  --help|-h) usage; exit 0 ;;
  "") echo "A <path> argument is required." >&2; usage >&2; exit 2 ;;
esac

target="$1"
markers=""

add_marker() { markers="${markers:+$markers, }$1"; }

has_register_block() {
  # grep a single file for the registration call
  grep -ql "registerBlockType" "$1" 2>/dev/null
}

if [ -f "$target" ]; then
  case "$(basename "$target")" in
    block.json) add_marker "block.json" ;;
  esac
  if has_register_block "$target"; then add_marker "registerBlockType()"; fi
elif [ -d "$target" ]; then
  [ -f "$target/block.json" ] && add_marker "block.json"
  # Shallow scan for a JS file that registers a block.
  while IFS= read -r js; do
    if has_register_block "$js"; then add_marker "registerBlockType() in $(basename "$js")"; break; fi
  done <<EOF
$(find "$target" -maxdepth 1 -type f \( -name '*.js' -o -name '*.jsx' -o -name '*.ts' -o -name '*.tsx' \) 2>/dev/null)
EOF
  # Note other typical block files for context (do not affect PASS/FAIL).
  for f in render.php edit.js view.js; do
    [ -f "$target/$f" ] && add_marker "$f"
  done
else
  echo "FAIL: path not found: $target" >&2
  exit 2
fi

if [ -z "$markers" ]; then
  echo "FAIL: $target does not look like a WordPress block (no block.json and no registerBlockType())." >&2
  exit 1
fi

echo "PASS: $target looks like a WordPress block — markers: $markers"
exit 0
