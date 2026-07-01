#!/bin/bash
# implements: ADR-105-RUN-RUNTIME-MODE-SUPPORT-MULTIPLE-WP-LOCAL-RUNTIMES
# wp-env.sh — WordPress.org wp-env driver (stub for Phase 4a)
#
# Phase 1: Minimal stub that routes to BYO approach.
# Phase 4a: Full implementation with wp-env lifecycle management.

set -uo pipefail

echo "→ wp-env driver detected (Phase 1 stub)"
echo ""
echo "Phase 1 supports BYO approach: start wp-env manually, then use:"
echo "  wp-env start  (or: npm run env:start)"
echo "  bash driver.sh byo drive http://localhost:8888/"
echo ""
echo "Full wp-env integration coming in Phase 4a when team requests it."
echo "Phase 4a will automate: wp-env start → build → activate plugin → drive"
echo ""
echo "For now, please:"
echo "  1. Run: wp-env start (or npm run env:start)"
echo "  2. Run: wp-env run cli wp plugin activate ucsc-gutenberg-blocks"
echo "  3. Use: bash driver.sh byo drive http://localhost:8888/"
echo ""
exit 1
