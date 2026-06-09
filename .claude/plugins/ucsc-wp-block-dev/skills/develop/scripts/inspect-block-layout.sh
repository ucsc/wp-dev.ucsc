#!/usr/bin/env bash
# implements: ADR-095-DEVELOP-SOURCE-BASE
# Safely inspect a WordPress plugin's block layout (ADR-095).
#
# Replaces ad-hoc `base=/abs/path; ls $base; find $base -name block.json ...`
# snippets, which hardcode paths and risk unquoted-glob expansion. Resolves the
# plugin location through source-base.sh (no hardcoded paths), quotes every
# expansion, and prunes node_modules. Self-locates via ${BASH_SOURCE[0]} (ADR-094).
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
Usage: inspect-block-layout.sh <plugin-slug-or-path>

Inspect a WordPress plugin's block layout without hardcoded paths or ad-hoc find
(ADR-095). The argument is either:
  - a known plugin slug (e.g. ucsc-blocks, ucsc-gutenberg-blocks), resolved via
    source-base.sh plugin-dir <slug>, or
  - an absolute/relative path to a plugin directory.

Prints: the resolved path, a top-level listing, every block.json (node_modules
pruned), and any single-file blocks calling registerBlockType().

Exit 0 on success; 2 on missing argument or unresolvable path.
EOF
}

case "${1:-}" in
  --help|-h|help)
    usage
    exit 0
    ;;
  "")
    echo "missing <plugin-slug-or-path> argument" >&2
    usage >&2
    exit 2
    ;;
esac

arg="$1"

# Resolve to an on-disk directory: prefer an existing path, else treat as a slug.
if [ -d "$arg" ]; then
  base="$(cd -- "$arg" && pwd)"
else
  base="$(bash "$SCRIPT_DIR/source-base.sh" plugin-dir "$arg" 2>/dev/null || true)"
fi

if [ -z "${base:-}" ] || [ ! -d "$base" ]; then
  echo "ERROR: could not resolve a plugin directory from '$arg'" >&2
  echo "       pass a known slug (ucsc-blocks, ucsc-gutenberg-blocks) or an existing path." >&2
  exit 2
fi

echo "== resolved plugin dir =="
echo "$base"
echo
echo "== top level =="
ls -la "$base" | head -n 30
echo
echo "== block.json (node_modules pruned) =="
find "$base" -path '*/node_modules/*' -prune -o -name 'block.json' -print 2>/dev/null | head -n 20
echo
echo "== single-file blocks calling registerBlockType() =="
find "$base" -path '*/node_modules/*' -prune -o -name '*.js' -print 2>/dev/null \
  | while IFS= read -r f; do
      if grep -lq 'registerBlockType' "$f" 2>/dev/null; then
        echo "$f"
      fi
    done | head -n 20
