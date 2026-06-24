#!/bin/bash
# implements: ADR-095-RUN-WP-EVAL
# wp_eval.sh — run a bundled PHP file inside the wpcli container via wp-cli over
# STDIN. The single, reviewed substrate for runtime introspection: it locates the
# wp-dev.ucsc root and pipes <php-file> to `wp eval-file -`, so NO PHP is ever
# embedded in a shell string (ADR-095). The thin tool wrappers in this skill
# (block_doctor.sh, wp_facts.sh, list_blocks.sh-style helpers) call this.
#
# Usage:
#   wp_eval.sh <php-file> [KEY=VAL ...]
#
# Each KEY=VAL is forwarded into the container as an env var the PHP can read via
# getenv(). Example:
#   wp_eval.sh helpers/block_doctor.php DOCTOR_BLOCK=ucscblocks/classschedule
#
# Env: WP_DEV_ROOT=/path   override repo-root autodetection
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SOURCE_BASE="$HERE/../develop/scripts/source_base.sh"

usage() {
  sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'
}

case "${1:-}" in
  --help|-h|help|"") usage; [ "${1:-}" = "" ] && exit 2 || exit 0 ;;
esac

PHP_FILE="$1"; shift || true
# Resolve to absolute BEFORE any cd, so a path relative to the caller still works.
case "$PHP_FILE" in
  /*) : ;;
  *) PHP_FILE="$(cd "$(dirname "$PHP_FILE")" 2>/dev/null && pwd)/$(basename "$PHP_FILE")" ;;
esac
[ -f "$PHP_FILE" ] || { echo "wp_eval: no such PHP file: $PHP_FILE" >&2; exit 2; }

# Forward KEY=VAL args as container env (-e). Guard empty array for bash 3.2 + set -u.
ENVARGS=()
for kv in "$@"; do
  case "$kv" in
    *=*) ENVARGS+=( -e "$kv" ) ;;
    *) echo "wp_eval: ignoring non KEY=VAL arg '$kv'" >&2 ;;
  esac
done

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

docker compose exec -T ${ENVARGS[@]+"${ENVARGS[@]}"} wpcli wp eval-file - < "$PHP_FILE"
