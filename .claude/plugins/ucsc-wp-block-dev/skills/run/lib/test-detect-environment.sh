#!/bin/bash
# implements: ADR-105-RUN-RUNTIME-MODE-SUPPORT-MULTIPLE-WP-LOCAL-RUNTIMES
# test-detect-environment.sh — Test suite for environment detection layer
#
# Usage: bash test-detect-environment.sh
# Tests the detect_environment function against all environment scenarios

set -uo pipefail

case "${1:-}" in
  --help|-h)
    echo "Usage: test-detect-environment.sh"
    echo "Runs the environment-detection test suite; takes no arguments."
    exit 0
    ;;
esac

# Source the detection script
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/detect-environment.sh"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

TESTS_PASSED=0
TESTS_FAILED=0
TMPDIR=""

# Cleanup on exit
cleanup() {
  [ -n "$TMPDIR" ] && [ -d "$TMPDIR" ] && rm -rf "$TMPDIR"
}
trap cleanup EXIT

# Test helper
test_detection() {
  local test_name="$1"
  local test_dir="$2"
  local expected="$3"

  local result
  result=$(detect_environment "$test_dir" 2>/dev/null || echo "unknown")

  if [ "$result" = "$expected" ]; then
    echo -e "${GREEN}✓${NC} $test_name (got: $result)"
    ((TESTS_PASSED++))
  else
    echo -e "${RED}✗${NC} $test_name (expected: $expected, got: $result)"
    ((TESTS_FAILED++))
  fi
}

echo "════════════════════════════════════════════════════════════════"
echo "  Environment Detection Test Suite"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Create temporary test directories
TMPDIR=$(mktemp -d)

# Test 1: wp-dev-ucsc environment
echo "Test Group 1: wp-dev-ucsc Detection"
test_dir="$TMPDIR/wp-dev-ucsc"
mkdir -p "$test_dir"
cat > "$test_dir/Dockerfile" << 'DOCKERFILE_EOF'
FROM wordpress:6.5.5-php8.1-apache
RUN apt-get update && apt-get install -y php-ldap
ENV LDAP_SERVER=ldap.example.test
DOCKERFILE_EOF
echo "version: '3.8'" > "$test_dir/docker-compose.yml"
test_detection "wp-dev-ucsc with Dockerfile + compose" "$test_dir" "wp-dev-ucsc"

# Test 2: wp-env detection via wp-env.json
echo ""
echo "Test Group 2: wp-env Detection"
test_dir="$TMPDIR/wp-env-json"
mkdir -p "$test_dir"
echo '{"core": "latest", "plugins": ["."]}' > "$test_dir/wp-env.json"
test_detection "wp-env with wp-env.json" "$test_dir" "wp-env"

# Test 3: wp-env detection via package.json
test_dir="$TMPDIR/wp-env-pkg"
mkdir -p "$test_dir"
cat > "$test_dir/package.json" << 'PKG_EOF'
{
  "name": "test",
  "devDependencies": {
    "@wordpress/env": "latest"
  }
}
PKG_EOF
test_detection "wp-env with package.json dependency" "$test_dir" "wp-env"

# Test 4: Local/LocalWP detection (marker file only, can't test GUI app)
echo ""
echo "Test Group 3: Local Detection"
echo -e "${YELLOW}⊘${NC} Local marker detection (requires \$HOME/.local/share/Local): skipped"
echo "  (Can be tested manually: mkdir -p \$HOME/.local/share/Local/sites)"

# Test 5: WP Engine detection (.wpe marker)
echo ""
echo "Test Group 4: WP Engine Detection"
test_dir="$TMPDIR/wpe"
mkdir -p "$test_dir"
touch "$test_dir/.wpe"
test_detection "WP Engine with .wpe marker" "$test_dir" "wpe"

# Test 6: Unknown environment
echo ""
echo "Test Group 5: Unknown Environment"
test_dir="$TMPDIR/unknown"
mkdir -p "$test_dir"
test_detection "Unknown/empty directory" "$test_dir" "unknown"

# Test 7: Precedence (wp-dev-ucsc should win over wp-env if both exist)
echo ""
echo "Test Group 6: Precedence Rules"
test_dir="$TMPDIR/precedence"
mkdir -p "$test_dir"
cat > "$test_dir/Dockerfile" << 'DOCKERFILE_EOF'
FROM wordpress:6.5.5-php8.1-apache
RUN apt-get install -y php-ldap
DOCKERFILE_EOF
echo "version: '3.8'" > "$test_dir/docker-compose.yml"
echo '{}' > "$test_dir/wp-env.json"
test_detection "wp-dev-ucsc wins over wp-env" "$test_dir" "wp-dev-ucsc"

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
  echo -e "${GREEN}SUCCESS${NC}: All tests passed!"
  exit 0
fi
