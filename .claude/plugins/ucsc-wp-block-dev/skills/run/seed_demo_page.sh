#!/bin/bash
# implements: ADR-095-RUN-WP-EVAL
# seed_demo_page.sh — upsert the registry-driven "UCSC Block Demo" page and print
# its URL. The PHP (helpers/seed_demo_page.php) runs in the container via wp-cli
# over STDIN — no host PHP, no inline PHP in a shell string. Idempotent.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
PHP="$HERE/helpers/seed_demo_page.php"
SOURCE_BASE="$HERE/../develop/scripts/source_base.sh"

case "${1:-}" in
  --help|-h|help) echo "Usage: seed_demo_page.sh   # upsert demo page, print URL"; exit 0 ;;
esac

ROOT="$(bash "$SOURCE_BASE" repo-root 2>/dev/null || true)"
[ -n "$ROOT" ] || { echo "ERROR: cannot locate wp-dev.ucsc root (set WP_DEV_ROOT=)" >&2; exit 2; }
cd "$ROOT" || exit 2

docker compose exec -T wpcli wp eval-file - < "$PHP"
