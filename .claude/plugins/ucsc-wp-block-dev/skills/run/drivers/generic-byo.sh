#!/bin/bash
# implements: ADR-105-RUN-RUNTIME-MODE-SUPPORT-MULTIPLE-WP-LOCAL-RUNTIMES
# generic-byo.sh — "Bring Your Own" driver for manually-managed WordPress.
#
# Assumes WordPress is already running (user brings it up). Only supports
# `drive` — verify the URL responds, then drive it with headless Chrome
# (post-JS DOM + console capture, shared with every other environment driver
# via lib/drive.sh).

set -uo pipefail

usage() {
  cat <<EOF
usage: $(basename "$0") drive <URL>

Bring Your Own (BYO) driver — assumes WordPress is already running.

This driver only supports the 'drive' command (open browser and capture).
For other operations, start your WordPress environment first.

Examples:
  bash driver.sh byo drive http://localhost:8000/
  bash driver.sh byo drive https://mysite.local/

For help:
  bash driver.sh help
EOF
}

case "${1:-}" in
  --help|-h)
    usage
    exit 0
    ;;
esac

COMMAND="${1:-}"
URL="${2:-}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" && pwd)"
LOG="${UCSC_RUN_LOG:-/tmp/ucsc-run-byo-$(date +%Y%m%d-%H%M%S).log}"
FAILED=0
pass() { printf '  [ OK ] %s\n' "$1"; }
fail() { printf '  [FAIL] %s\n' "$1"; FAILED=1; }
# shellcheck source=../lib/drive.sh
source "$SCRIPT_DIR/../lib/drive.sh"

case "$COMMAND" in
  drive)
    if [ -z "$URL" ]; then
      echo "ERROR: URL required for 'drive' command"
      usage
      exit 1
    fi

    echo "→ Checking WordPress at $URL..."
    response=$(curl -s --max-time 2 "$URL/wp-admin/" 2>/dev/null || echo "")

    if echo "$response" | grep -q "wp-login\|wp-admin\|WordPress\|function wp_" 2>/dev/null; then
      pass "WordPress running at $URL"
      drive_url "$URL" "$LOG"
    else
      fail "WordPress not responding at $URL"
      echo ""
      echo "Make sure your development environment is running:"
      echo "  - wp-dev-ucsc: docker compose up -d"
      echo "  - wp-env: wp-env start"
      echo "  - LocalWP: Open the app and click 'Start'"
      echo "  - Manual: Bring WordPress online however you do"
      echo ""
      echo "Then try again:"
      echo "  bash driver.sh byo drive $URL"
      exit 1
    fi
    ;;
  *)
    if [ -n "$COMMAND" ]; then
      echo "ERROR: BYO driver only supports 'drive' command"
    fi
    usage
    exit 1
    ;;
esac

echo "----"
[ "$FAILED" -eq 0 ] && echo "RESULT: PASS" || echo "RESULT: FAIL  (log: $LOG)"
exit "$FAILED"
