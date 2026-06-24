#!/bin/bash
# Persist and read the session block target (ADR-093).
#
# The resolved block target is shared across block-operating skills via a
# session cache file so a target is resolved once and reused, rather than
# re-asked by every skill.
#
# A secured target records three things (ADR-093, 2026-06-23 amendment):
#   - slug  : the canonical block slug (the "target")
#   - repo  : the owning repository / plugin (ucsc-blocks or ucsc-gutenberg-blocks)
#   - path  : the absolute filesystem path to the block dir (or single-file block)
# These are stored space-separated on one line: "<slug> <repo> <path>".
set -e

CACHE_DIR="${UCSC_WP_BLOCK_DEV_CACHE:-$HOME/.cache/ucsc-wp-block-dev}"
STATE_FILE="$CACHE_DIR/session-target"

usage() {
  cat <<'EOF'
Usage: session_target.sh <command> [args]

Persist and read the session block target shared across block skills (ADR-093).
A secured target specifies the repository AND the block target, plus the path on
the filesystem (ADR-093, 2026-06-23 amendment).

Commands:
  get             Print the persisted target as "<slug> <repo> <path>" (empty if unset).
  slug            Print only the persisted slug (empty if unset).
  repo            Print only the owning repository / plugin (empty if unset).
  dir             Print only the target's filesystem path (empty if unset).
  set <slug> <repo> [path]
                  Persist <slug>, its owning <repo>/plugin, and the optional
                  absolute filesystem <path> as the session target.
  clear           Remove the persisted target.
  path            Print the cache file path (not the target path; use `dir` for that).

Resolution order callers should follow (ADR-093):
  1. explicit ARGUMENTS target (wins, and should be written via `set`)
  2. this persisted value (`get`)
  3. CWD inference (.../src/blocks/<slug>)
  4. prompt from develop/references/targets.md

When securing a target, specify the repository and the target both, and record
the filesystem path; validate the path with block_target_check.sh first.

Cache dir: $UCSC_WP_BLOCK_DEV_CACHE (default ~/.cache/ucsc-wp-block-dev).
EOF
}

case "${1:-}" in
  --help|-h|help)
    usage
    exit 0
    ;;
  get)
    [ -f "$STATE_FILE" ] && cat "$STATE_FILE"
    exit 0
    ;;
  slug)
    [ -f "$STATE_FILE" ] && awk 'NR==1{print $1}' "$STATE_FILE"
    exit 0
    ;;
  repo|plugin)
    [ -f "$STATE_FILE" ] && awk 'NR==1{print $2}' "$STATE_FILE"
    exit 0
    ;;
  dir)
    [ -f "$STATE_FILE" ] && awk 'NR==1{print $3}' "$STATE_FILE"
    exit 0
    ;;
  set)
    slug="${2:-}"
    repo="${3:-}"
    target_path="${4:-}"
    if [ -z "$slug" ]; then
      echo "set requires a <slug> argument" >&2
      usage >&2
      exit 2
    fi
    if [ -z "$repo" ]; then
      echo "set requires a <repo> argument: specify the repository and the target both (ADR-093)" >&2
      usage >&2
      exit 2
    fi
    mkdir -p "$CACHE_DIR"
    printf '%s %s %s\n' "$slug" "$repo" "$target_path" > "$STATE_FILE"
    echo "session target set: $slug ($repo)${target_path:+ at $target_path}"
    exit 0
    ;;
  clear)
    rm -f "$STATE_FILE"
    echo "session target cleared"
    exit 0
    ;;
  path)
    echo "$STATE_FILE"
    exit 0
    ;;
  "")
    usage >&2
    exit 2
    ;;
  *)
    echo "Unknown command: $1" >&2
    usage >&2
    exit 2
    ;;
esac
