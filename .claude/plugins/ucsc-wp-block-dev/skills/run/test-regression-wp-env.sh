#!/bin/bash
# implements: ADR-105-RUN-RUNTIME-MODE-SUPPORT-MULTIPLE-WP-LOCAL-RUNTIMES
# test-regression-wp-env.sh — Non-destructive regression suite for the wp-env driver.
#
# Does NOT run `wp-env start` (downloads Docker images, can take minutes and
# needs network) — only checks routing, syntax, and the non-destructive
# `inspect` phase, same spirit as test-regression-wp-dev-ucsc.sh.

set -uo pipefail

case "${1:-}" in
  --help|-h)
    echo "Usage: test-regression-wp-env.sh"
    echo "Runs the wp-env driver regression suite (non-destructive); takes no arguments."
    exit 0
    ;;
esac

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0

assert_exit_0() {
  local test_name="$1"
  local cmd="$2"
  if eval "$cmd" &>/dev/null; then
    echo -e "${GREEN}✓${NC} $test_name"
    ((TESTS_PASSED++))
  else
    echo -e "${RED}✗${NC} $test_name"
    echo "  Command: $cmd"
    ((TESTS_FAILED++))
  fi
}

assert_contains() {
  local test_name="$1"
  local output="$2"
  local pattern="$3"
  if echo "$output" | grep -q "$pattern"; then
    echo -e "${GREEN}✓${NC} $test_name"
    ((TESTS_PASSED++))
  else
    echo -e "${RED}✗${NC} $test_name (expected pattern: $pattern)"
    ((TESTS_FAILED++))
  fi
}

find_wp_dev_root() {
  local d="$PWD"
  while [ -n "$d" ] && [ "$d" != "/" ]; do
    if [ -f "$d/docker-compose.yml" ] && [ -d "$d/.claude/plugins/ucsc-wp-block-dev" ]; then
      echo "$d"
      return 0
    fi
    d=$(dirname "$d")
  done
  return 1
}

WP_DEV_ROOT=$(find_wp_dev_root) || {
  echo "ERROR: Could not locate wp-dev.ucsc root"
  exit 1
}

PLUGIN_DIR="$WP_DEV_ROOT/.claude/plugins/ucsc-wp-block-dev"
DRIVER="$PLUGIN_DIR/skills/run/driver.sh"
WPENV_DRIVER="$PLUGIN_DIR/skills/run/drivers/wp-env.sh"

cd "$WP_DEV_ROOT"

echo "════════════════════════════════════════════════════════════════"
echo "  wp-env Driver Regression Suite (non-destructive)"
echo "════════════════════════════════════════════════════════════════"
echo ""

echo "Test Group 1: Script health"
echo ""
assert_exit_0 "wp-env driver exists and is executable" "[ -x '$WPENV_DRIVER' ]"
assert_exit_0 "wp-env driver has valid bash syntax" "bash -n '$WPENV_DRIVER'"
assert_exit_0 "shared drive.sh exists" "[ -f '$PLUGIN_DIR/skills/run/lib/drive.sh' ]"
assert_exit_0 "shared drive.sh has valid bash syntax" "bash -n '$PLUGIN_DIR/skills/run/lib/drive.sh'"
assert_exit_0 "wp-env-example.json exists" "[ -f '$PLUGIN_DIR/skills/run/wp-env-example.json' ]"

echo ""
echo "Test Group 2: Help / usage"
echo ""
OUTPUT=$(bash "$WPENV_DRIVER" --help 2>&1)
assert_contains "wp-env driver --help works" "$OUTPUT" "wp-env.sh"

echo ""
echo "Test Group 3: Router dispatch"
echo ""
OUTPUT=$(bash "$DRIVER" wp-env --help 2>&1)
assert_contains "Router dispatches to wp-env driver" "$OUTPUT" "Environment: wp-env"

echo ""
echo "Test Group 4: inspect phase (non-destructive; no wp-env start)"
echo ""
# Without .wp-env.json this should FAIL cleanly (exit 1) rather than crash.
OUTPUT=$(bash "$WPENV_DRIVER" inspect 2>&1)
EXIT_CODE=$?
assert_contains "inspect reports .wp-env.json state" "$OUTPUT" "wp-env.json"
assert_exit_0 "inspect exits non-zero without crashing when config is missing or exits 0 when present" \
  "[ $EXIT_CODE -eq 0 ] || [ $EXIT_CODE -eq 1 ]"

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  Test Results"
echo "════════════════════════════════════════════════════════════════"
echo "  Passed: ${GREEN}$TESTS_PASSED${NC}"
echo "  Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ "$TESTS_FAILED" -gt 0 ]; then
  echo -e "${RED}FAILED${NC}: $TESTS_FAILED test(s) did not pass"
  exit 1
else
  echo -e "${GREEN}SUCCESS${NC}: All wp-env regression tests passed!"
  exit 0
fi
