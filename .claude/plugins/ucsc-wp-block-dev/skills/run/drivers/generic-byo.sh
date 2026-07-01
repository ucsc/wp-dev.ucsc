#!/bin/bash
# implements: ADR-105-RUN-RUNTIME-MODE-SUPPORT-MULTIPLE-WP-LOCAL-RUNTIMES
# generic-byo.sh — "Bring Your Own" driver for manually-managed WordPress.
#
# Assumes WordPress is already running (user brings it up).
# Only supports `drive` command to interact with blocks in the browser.

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

case "$COMMAND" in
  drive)
    if [ -z "$URL" ]; then
      echo "ERROR: URL required for 'drive' command"
      usage
      exit 1
    fi
    
    # Verify WordPress is running (HTTP probe)
    echo "→ Checking WordPress at $URL..."
    
    # Probe for WordPress login page or wp-admin
    local response
    response=$(curl -s --max-time 2 "$URL/wp-admin/" 2>/dev/null || echo "")
    
    if echo "$response" | grep -q "wp-login\|wp-admin\|WordPress\|function wp_" 2>/dev/null; then
      echo "✓ WordPress running at $URL"
      
      # TODO: Call existing drive logic (Playwright, screenshot, console capture)
      # For now, stub it with a message
      echo "✓ Would now open browser and capture block in action"
      echo "  (Full Playwright integration: Phase 1b coming soon)"
    else
      echo "ERROR: WordPress not responding at $URL"
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
