#!/bin/bash
# implements: ADR-105-RUN-RUNTIME-MODE-SUPPORT-MULTIPLE-WP-LOCAL-RUNTIMES
# local.sh — LocalWP / Local by Flywheel driver (stub for Phase 4b)
#
# Phase 1: Minimal stub that prompts user to start the app.
# Phase 4b: Full implementation with Local API integration.

set -uo pipefail

usage() {
  cat <<'EOF'
Usage: local.sh [phase ...]

LocalWP / Local by Flywheel driver — Phase 1 stub. All invocations print BYO
guidance and exit 1; full lifecycle support arrives in Phase 4b. Start the site
in the LocalWP app, then use: bash driver.sh byo drive https://yoursite.local/
EOF
}

case "${1:-}" in
  --help|-h)
    usage
    exit 0
    ;;
esac

echo "→ LocalWP driver detected (Phase 1 stub)"
echo ""
echo "Phase 1 supports BYO approach: start your WordPress manually, then use:"
echo "  bash driver.sh byo drive https://yoursite.local/"
echo ""
echo "Full LocalWP integration coming in Phase 4b when team requests it."
echo ""
echo "For now, please:"
echo "  1. Open LocalWP app"
echo "  2. Click 'Start' on your WordPress site"
echo "  3. Use: bash driver.sh byo drive https://yoursite.local/"
echo ""
exit 1
