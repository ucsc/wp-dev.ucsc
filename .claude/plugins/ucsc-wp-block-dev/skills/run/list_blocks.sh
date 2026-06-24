#!/bin/bash
# implements: ADR-095-RUN-WP-EVAL
# list_blocks.sh — list every `ucsc/*` block registered in the RUNNING
# wp-dev.ucsc WordPress (the runtime source of truth, spanning ALL activated
# plugins — ucsc-blocks AND ucsc-gutenberg-blocks — without reading either
# repo's source). Replaces the hand-built inline `wp eval` one-liner: the PHP
# lives in helpers/list_blocks.php and is piped to wp-cli over STDIN, so no PHP
# is ever embedded in a shell string (ADR-095).
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
PHP="$HERE/helpers/list_blocks.php"
SOURCE_BASE="$HERE/../develop/scripts/source_base.sh"

usage() {
  cat <<'EOF'
Usage: list_blocks.sh [--help]

List every ucsc/* block registered in the RUNNING wp-dev.ucsc WordPress, one per
line. Reads the live WP_Block_Type_Registry through wp-cli (helpers/list_blocks.php
piped over STDIN), so no PHP is embedded in a shell string and the result spans
every activated plugin.

Env: WP_DEV_ROOT=/path   override repo-root autodetection
EOF
}

case "${1:-}" in
  --help|-h|help) usage; exit 0 ;;
  "") ;;
  *) echo "list_blocks: unknown argument '$1'" >&2; usage >&2; exit 2 ;;
esac

# Locate the wp-dev.ucsc root: prefer the shared resolver (ADR-095), then walk up.
find_root() {
  local d
  if [ -f "$SOURCE_BASE" ]; then
    d="$(bash "$SOURCE_BASE" repo-root 2>/dev/null || true)"
    [ -n "$d" ] && { echo "$d"; return 0; }
  fi
  for d in "${WP_DEV_ROOT:-}" "$PWD" "$HERE"; do
    [ -n "$d" ] || continue
    while [ -n "$d" ] && [ "$d" != "/" ]; do
      [ -f "$d/docker-compose.yml" ] && { echo "$d"; return 0; }
      d=$(dirname "$d")
    done
  done
  return 1
}

ROOT="$(find_root)" || { echo "ERROR: could not locate wp-dev.ucsc root (set WP_DEV_ROOT=)" >&2; exit 2; }
cd "$ROOT" || exit 2

docker compose exec -T wpcli wp eval-file - < "$PHP"
