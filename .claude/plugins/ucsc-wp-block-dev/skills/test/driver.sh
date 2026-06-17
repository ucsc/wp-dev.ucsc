#!/bin/bash
# driver.sh — token-frugal test harness for ucsc-gutenberg-blocks in the
# wp-dev.ucsc Docker environment. One call runs PHP and/or Jest unit tests
# and prints a compact PASS/FAIL summary; verbose output goes to a logfile.
#
# Usage:
#   driver.sh php       # Run only PHP tests (in docker container)
#   driver.sh jest      # Run only Jest unit tests (via plugin_npm_start service)
#   driver.sh e2e       # Run end-to-end tests (placeholder/check)
#   driver.sh all       # Run PHP and Jest tests (default)
#
# Override the project root with WP_DEV_ROOT=/path if autodetection fails.
# Full log path is printed on every run; read it only when a step FAILs.

set -uo pipefail

PLUGIN="ucsc-gutenberg-blocks"
LOG="${UCSC_TEST_LOG:-/tmp/ucsc-test-$(date +%Y%m%d-%H%M%S).log}"
FAILED=0

# --- locate the wp-dev.ucsc root -------------------------------------------
find_root() {
  local d
  for d in "${WP_DEV_ROOT:-}" "$PWD" "$(cd "$(dirname "$0")" && pwd)"; do
    [ -n "$d" ] || continue
    while [ -n "$d" ] && [ "$d" != "/" ]; do
      if [ -f "$d/docker-compose.yml" ] && [ -d "$d/public/wp-content/plugins/${PLUGIN}" ]; then
        echo "$d"; return 0
      fi
      d=$(dirname "$d")
    done
  done
  return 1
}

ROOT="$(find_root)" || { echo "ERROR: could not locate wp-dev.ucsc root (set WP_DEV_ROOT=)"; exit 2; }
cd "$ROOT" || exit 2
PDIR="$ROOT/public/wp-content/plugins/${PLUGIN}"

dc() { docker compose "$@"; }

# output formatting
pass() { printf '  [ OK ] %s\n' "$1"; }
fail() { printf '  [FAIL] %s\n' "$1"; FAILED=1; }
warn() { printf '  [WARN] %s\n' "$1"; }

# --- PHP Tests runner and parser -------------------------------------------
run_php() {
  echo "test php"
  
  # Find all php test files
  local test_files
  test_files=$(find "public/wp-content/plugins/${PLUGIN}/tests/php" -name "*Test.php" -o -name "*.php" 2>/dev/null | sort)
  if [ -z "$test_files" ]; then
    warn "No PHP tests found in public/wp-content/plugins/${PLUGIN}/tests/php"
    return
  fi

  # Run all tests in a single docker run command for performance, printing markers
  if ! docker run --rm -v "$PDIR:/plugin" -w /plugin php:8.1-cli sh -c '
    for f in tests/php/*Test.php; do
      [ -f "$f" ] || continue
      echo "FILE: $f"
      php "$f"
      echo "STATUS: $?"
    done
  ' > "$LOG" 2>&1; then
    FAILED=1
    fail "PHP Docker execution failed (see log)"
    return
  fi

  # Parse the log file
  local current_file=""
  local file_failed_tests=()
  local passed=0
  local total=0

  while IFS= read -r line; do
    # Strip carriage returns
    line=$(echo "$line" | tr -d '\r')
    
    if [[ "$line" =~ ^FILE:\ (.*) ]]; then
      current_file="${BASH_REMATCH[1]}"
      file_failed_tests=()
      passed=0
      total=0
    elif [[ "$line" =~ ^[[:space:]]*FAIL[[:space:]]+(.*) ]]; then
      file_failed_tests+=("${BASH_REMATCH[1]}")
    elif [[ "$line" =~ ^([0-9]+)/([0-9]+)\ passed ]]; then
      passed="${BASH_REMATCH[1]}"
      total="${BASH_REMATCH[2]}"
    elif [[ "$line" =~ ^STATUS:\ ([0-9]+) ]]; then
      local status="${BASH_REMATCH[1]}"
      local fname
      fname=$(basename "$current_file")
      if [ "$status" -ne 0 ] || [ ${#file_failed_tests[@]} -gt 0 ]; then
        FAILED=1
        local failed_count=$((total - passed))
        if [ "$failed_count" -le 0 ]; then failed_count=1; fi
        fail "${fname} ($failed_count failed)"
        for t in "${file_failed_tests[@]}"; do
          echo "    - FAIL: $t"
        done
      else
        pass "${fname} ($passed/$total passed)"
      fi
    fi
  done < "$LOG"
}

# --- Jest Tests runner and parser ------------------------------------------
run_jest() {
  echo "test jest"

  # Run Jest unit tests in Docker
  local exit_code=0
  dc -f docker-compose.yml -f docker-compose-start.yml run --rm \
    -e CI=true \
    -w "/var/www/html/wp-content/plugins/${PLUGIN}" \
    plugin_npm_start npm test > "$LOG" 2>&1 || exit_code=$?

  # Parse the log file
  local jest_failed_tests=()
  local jest_passed=0
  local jest_failed=0
  local jest_total=0

  while IFS= read -r line; do
    # Strip carriage returns
    line=$(echo "$line" | tr -d '\r')
    
    # Match Jest failure bullet (which could be the raw unicode black circle or dot)
    if [[ "$line" =~ ^[[:space:]]*[●•\*][[:space:]]+(.*) ]]; then
      jest_failed_tests+=("${BASH_REMATCH[1]}")
    elif [[ "$line" =~ Tests:[[:space:]]+([0-9]+)\ failed,[[:space:]]+([0-9]+)\ passed ]]; then
      jest_failed="${BASH_REMATCH[1]}"
      jest_passed="${BASH_REMATCH[2]}"
    elif [[ "$line" =~ Tests:[[:space:]]+([0-9]+)\ passed ]]; then
      jest_passed="${BASH_REMATCH[1]}"
      jest_failed=0
    fi
  done < "$LOG"

  if [ "$exit_code" -ne 0 ]; then
    FAILED=1
    if [ ${#jest_failed_tests[@]} -gt 0 ]; then
      fail "Jest tests ($jest_failed failed, $jest_passed passed)"
      for t in "${jest_failed_tests[@]}"; do
        echo "    - FAIL: $t"
      done
    else
      fail "Jest suite execution failed with exit code ${exit_code} (see log)"
    fi
  else
    pass "Jest tests passed ($jest_passed/$jest_passed passed)"
  fi
}

# --- E2E Tests runner/placeholder ------------------------------------------
run_e2e() {
  echo "test e2e"
  warn "No end-to-end (e2e) tests configured in the current project."
}

# --- dispatch ---------------------------------------------------------------
cmd="${1:-all}"
case "$cmd" in
  php)  run_php ;;
  jest) run_jest ;;
  e2e)  run_e2e ;;
  all)  run_php; run_jest ;;
  *) echo "usage: driver.sh [php|jest|e2e|all]"; exit 2 ;;
esac

echo "----"
if [ "$FAILED" -eq 0 ]; then
  echo "RESULT: PASS"
else
  echo "RESULT: FAIL  (log: $LOG)"
  # Print the last few lines of log on failure for direct context
  tail -n 15 "$LOG" 2>/dev/null
fi
echo "log: $LOG"
exit "$FAILED"
