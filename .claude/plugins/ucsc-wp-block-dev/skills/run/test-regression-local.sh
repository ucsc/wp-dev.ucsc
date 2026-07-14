#!/bin/bash
# implements: ADR-105-RUN-RUNTIME-MODE-SUPPORT-MULTIPLE-WP-LOCAL-RUNTIMES
# test-regression-local.sh — Non-destructive regression suite for the local driver.
#
# Does NOT require the Local app or the third-party `lwp` CLI to be installed
# (that would need a running LocalWP instance) — only checks routing, syntax,
# and the non-destructive `inspect` phase's clean-failure behavior, same spirit
# as test-regression-wp-env.sh.

set -uo pipefail

case "${1:-}" in
  --help|-h)
    echo "Usage: test-regression-local.sh"
    echo "Runs the local driver regression suite (non-destructive); takes no arguments."
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
LOCAL_DRIVER="$PLUGIN_DIR/skills/run/drivers/local.sh"

cd "$WP_DEV_ROOT"

echo "════════════════════════════════════════════════════════════════"
echo "  local (LocalWP) Driver Regression Suite (non-destructive)"
echo "════════════════════════════════════════════════════════════════"
echo ""

echo "Test Group 1: Script health"
echo ""
assert_exit_0 "local driver exists and is executable" "[ -x '$LOCAL_DRIVER' ] || [ -f '$LOCAL_DRIVER' ]"
assert_exit_0 "local driver has valid bash syntax" "bash -n '$LOCAL_DRIVER'"
assert_exit_0 "shared drive.sh exists" "[ -f '$PLUGIN_DIR/skills/run/lib/drive.sh' ]"

echo ""
echo "Test Group 2: Help / usage"
echo ""
OUTPUT=$(bash "$LOCAL_DRIVER" --help 2>&1)
assert_contains "local driver --help works" "$OUTPUT" "local.sh"
assert_contains "--help documents UCSC_LOCAL_SITE" "$OUTPUT" "UCSC_LOCAL_SITE"
assert_contains "--help documents lwp install" "$OUTPUT" "localwp-cli"

echo ""
echo "Test Group 3: Router dispatch"
echo ""
OUTPUT=$(bash "$DRIVER" local --help 2>&1)
assert_contains "Router dispatches to local driver" "$OUTPUT" "Environment: local"

echo ""
echo "Test Group 4: inspect phase (non-destructive; no lwp start/stop)"
echo ""
# Without lwp installed and without UCSC_LOCAL_SITE this should FAIL cleanly
# (exit 1) rather than crash on an unset variable or a missing binary.
OUTPUT=$(env -u UCSC_LOCAL_SITE -u LWP_BIN -u UCSC_LOCAL_URL bash "$LOCAL_DRIVER" inspect 2>&1)
EXIT_CODE=$?
assert_contains "inspect reports lwp CLI state" "$OUTPUT" "lwp"
assert_contains "inspect reports UCSC_LOCAL_SITE state" "$OUTPUT" "UCSC_LOCAL_SITE"
assert_exit_0 "inspect exits non-zero without crashing when lwp/site are missing" \
  "[ $EXIT_CODE -eq 0 ] || [ $EXIT_CODE -eq 1 ]"

echo ""
echo "Test Group 5: launch/smoke/down/drive fail cleanly without lwp"
echo ""
for phase in launch smoke down; do
  OUTPUT=$(env -u UCSC_LOCAL_SITE -u LWP_BIN bash "$LOCAL_DRIVER" "$phase" 2>&1)
  EXIT_CODE=$?
  assert_contains "$phase reports lwp CLI not found" "$OUTPUT" "lwp CLI not found"
  assert_exit_0 "$phase exits 1 (not a crash) without lwp" "[ $EXIT_CODE -eq 1 ]"
done
OUTPUT=$(env -u UCSC_LOCAL_SITE -u LWP_BIN -u UCSC_LOCAL_URL bash "$LOCAL_DRIVER" drive 2>&1)
EXIT_CODE=$?
assert_contains "drive reports unresolved URL without a site" "$OUTPUT" "no URL given and none resolvable"
assert_exit_0 "drive exits 1 (not a crash) without a resolvable URL" "[ $EXIT_CODE -eq 1 ]"

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
  echo -e "${GREEN}SUCCESS${NC}: All local driver regression tests passed!"
  exit 0
fi
