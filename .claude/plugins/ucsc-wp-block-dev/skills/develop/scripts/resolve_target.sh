#!/bin/bash
# implements: ADR-093-DEVELOP-SESSION-TARGET
# resolve_target.sh — deterministically resolve the block target from a path
# (default $PWD) with ZERO LLM tokens and no filesystem globbing (ADR-093).
#
# This fills the "CWD inference" step of the ADR-093 resolution order that was
# previously left to the model. It derives the owning repo/plugin and the block
# slug from the path string alone, then validates the single resolved block dir
# with block_target_check.sh (a shallow, maxdepth-1 check — never a tree scan).
#
# Output: one line "<slug> <repo> <path>" matching session_target.sh's format,
# with empty fields where a part can't be inferred. Exit status:
#   0  repo resolved (slug may still be empty if not inside a block dir)
#   3  path is not under .../wp-content/plugins/<repo>/ at all
#
# Handles both repo layouts:
#   - ucsc-blocks:           .../src/blocks/<slug>/         (a directory)
#   - ucsc-gutenberg-blocks: .../src/blocks/<Name>.js       (a single file)
set -e

HERE="$(cd "$(dirname "$0")" && pwd)"

usage() {
  cat <<'EOF'
Usage: resolve_target.sh [path] [--persist]

Resolve the block target from a path (default: current directory) using pure
string operations on the path — no globbing, no token cost (ADR-093 CWD step).

Prints one line: "<slug> <repo> <path>"  (empty fields where unknown), e.g.
  calendar-feed ucsc-blocks /abs/.../ucsc-blocks/src/blocks/calendar-feed

Options:
  --persist   Also store the result via session_target.sh set (when a slug is
              resolved), so later skills reuse it instead of re-inferring.

Exit: 0 repo resolved (slug may be empty); 3 not under a plugins/<repo>/ path.
EOF
}

PATH_ARG=""
PERSIST=0
for a in "$@"; do
  case "$a" in
    --help|-h) usage; exit 0 ;;
    --persist) PERSIST=1 ;;
    *) PATH_ARG="$a" ;;
  esac
done

p="${PATH_ARG:-$PWD}"

# --- repo/plugin: segment immediately after wp-content/plugins/ -------------
repo=""
case "$p" in
  */wp-content/plugins/*)
    rest="${p#*/wp-content/plugins/}"
    repo="${rest%%/*}"
    ;;
  *)
    echo "resolve_target: '$p' is not under .../wp-content/plugins/<repo>/" >&2
    printf '%s %s %s\n' "" "" ""
    exit 3
    ;;
esac

# Absolute path to the plugin root, for building the block dir below.
plugin_root="${p%%/wp-content/plugins/*}/wp-content/plugins/$repo"

# --- slug + path: segment immediately after src/blocks/ --------------------
slug=""
blockpath=""
case "$p" in
  */src/blocks/*)
    after="${p#*/src/blocks/}"
    seg="${after%%/*}"          # first segment after src/blocks/
    case "$seg" in
      *.js|*.jsx|*.ts|*.tsx)    # single-file block (gutenberg layout)
        slug="${seg%.*}"
        blockpath="$plugin_root/src/blocks/$seg"
        ;;
      "")                       # cwd is exactly .../src/blocks (no block chosen)
        ;;
      *)                        # directory block (ucsc-blocks layout)
        slug="$seg"
        blockpath="$plugin_root/src/blocks/$seg"
        ;;
    esac
    ;;
esac

# Validate the one resolved path (shallow); on failure, drop the slug rather
# than emit a bogus target. Never scans beyond the block dir itself.
if [ -n "$blockpath" ]; then
  if ! bash "$HERE/block_target_check.sh" "$blockpath" >/dev/null 2>&1; then
    slug=""
    blockpath=""
  fi
fi

if [ "$PERSIST" -eq 1 ] && [ -n "$slug" ]; then
  bash "$HERE/session_target.sh" set "$slug" "$repo" "$blockpath" >/dev/null 2>&1 || true
fi

printf '%s %s %s\n' "$slug" "$repo" "$blockpath"
exit 0
