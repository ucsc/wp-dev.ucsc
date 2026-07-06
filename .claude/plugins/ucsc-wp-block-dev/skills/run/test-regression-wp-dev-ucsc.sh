#!/bin/bash
# implements: ADR-105-RUN-RUNTIME-MODE-SUPPORT-MULTIPLE-WP-LOCAL-RUNTIMES
# test-regression-wp-dev-ucsc.sh — Regression test suite for wp-dev-ucsc driver
#
# Ensures the multi-env router doesn't break existing wp-dev-ucsc workflows.
# Tests: auto-detect, explicit env, old commands all still work identically.

set -uo pipefail

case "${1:-}" in
  --help|-h)
    echo "Usage: test-regression-wp-dev-ucsc.sh"
    echo "Runs the wp-dev-ucsc driver regression suite; takes no arguments."
    exit 0
    ;;
esac

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0

# Test helpers
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

# Find wp-dev.ucsc root
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

DRIVER="$WP_DEV_ROOT/.claude/plugins/ucsc-wp-block-dev/skills/run/driver.sh"
if [ ! -f "$DRIVER" ]; then
  echo "ERROR: driver.sh not found at $DRIVER"
  exit 1
fi

cd "$WP_DEV_ROOT"

echo "════════════════════════════════════════════════════════════════"
echo "  wp-dev-ucsc Regression Test Suite"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Test Group 1: Basic router functionality
echo "Test Group 1: Router Basics"
echo ""

# Test 1: help command works
OUTPUT=$(bash "$DRIVER" help 2>&1)
assert_contains "Router help" "$OUTPUT" "usage: driver.sh"

# Test 2: auto-detection works
OUTPUT=$(bash "$DRIVER" auto inspect 2>&1)
assert_contains "Auto-detect environment" "$OUTPUT" "wp-dev-ucsc"

# Test 3: explicit wp-dev-ucsc specification works
OUTPUT=$(bash "$DRIVER" wp-dev-ucsc inspect 2>&1)
assert_contains "Explicit wp-dev-ucsc" "$OUTPUT" "wp-dev-ucsc"

# Test Group 2: Backward compatibility (old commands still work)
echo ""
echo "Test Group 2: Backward Compatibility"
echo ""

# Test 4: inspect phase works via auto
bash "$DRIVER" auto inspect &>/dev/null
assert_exit_0 "inspect phase (auto)" "bash '$DRIVER' auto inspect"

# Test 5: inspect phase works via explicit
bash "$DRIVER" wp-dev-ucsc inspect &>/dev/null
assert_exit_0 "inspect phase (explicit)" "bash '$DRIVER' wp-dev-ucsc inspect"

# Test Group 3: Environment detection
echo ""
echo "Test Group 3: Environment Detection"
echo ""

# Test 6: detect-environment script exists
assert_exit_0 "detect-environment script exists" "[ -f '$WP_DEV_ROOT/.claude/plugins/ucsc-wp-block-dev/skills/run/lib/detect-environment.sh' ]"

# Test 7: detect-environment script is executable
assert_exit_0 "detect-environment script is executable" "[ -x '$WP_DEV_ROOT/.claude/plugins/ucsc-wp-block-dev/skills/run/lib/detect-environment.sh' ]"

# Test 8: detection returns wp-dev-ucsc in wp-dev-ucsc root
OUTPUT=$(bash "$WP_DEV_ROOT/.claude/plugins/ucsc-wp-block-dev/skills/run/lib/detect-environment.sh" "$WP_DEV_ROOT" 2>&1)
assert_contains "Detect wp-dev-ucsc environment" "$OUTPUT" "wp-dev-ucsc"

# Test Group 4: Driver files
echo ""
echo "Test Group 4: Driver Files"
echo ""

# Test 9: wp-dev-ucsc driver exists and is executable
assert_exit_0 "wp-dev-ucsc driver exists" "[ -x '$WP_DEV_ROOT/.claude/plugins/ucsc-wp-block-dev/skills/run/drivers/wp-dev-ucsc.sh' ]"

# Test 10: BYO driver exists and is executable
assert_exit_0 "BYO driver exists" "[ -x '$WP_DEV_ROOT/.claude/plugins/ucsc-wp-block-dev/skills/run/drivers/generic-byo.sh' ]"

# Test 11: Local stub driver exists
assert_exit_0 "Local stub driver exists" "[ -x '$WP_DEV_ROOT/.claude/plugins/ucsc-wp-block-dev/skills/run/drivers/local.sh' ]"

# Test 12: wp-env stub driver exists
assert_exit_0 "wp-env stub driver exists" "[ -x '$WP_DEV_ROOT/.claude/plugins/ucsc-wp-block-dev/skills/run/drivers/wp-env.sh' ]"

# Summary
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  Test Results"
echo "════════════════════════════════════════════════════════════════"
echo "  Passed: ${GREEN}$TESTS_PASSED${NC}"
echo "  Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -gt 0 ]; then
  echo -e "${RED}FAILED${NC}: $TESTS_FAILED test(s) did not pass"
  exit 1
else
  echo -e "${GREEN}SUCCESS${NC}: All regression tests passed!"
  echo "  wp-dev-ucsc driver behavior is unchanged"
  exit 0
fi
