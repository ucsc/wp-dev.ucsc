#!/bin/bash
# implements: ADR-003-MAINTAINER-LOW-TOKEN, ADR-078-MAINTAINER-CLI-VALIDATE
# run-all-plugin-tests.sh — run the `maintainer all` deterministic battery in one command.
#
# Battery (token-frugal, no agents):
#   1. self-test         — pytest contracts + upstream-inspired best-practice checks
#   2. check-references  — every skill support file linked from its SKILL.md
#   3. validate          — `claude plugin validate --strict` structural check
#
# Agent-backed checks (plugin-dev:plugin-validator / skill-reviewer) are
# deliberately excluded per ADR-086; request those explicitly.
#
# Runs from any cwd: paths resolve relative to this script. Prints a compact
# per-step PASS/FAIL and a final summary. Exit 0 only if every step passes.
#
# Usage:  run-all-plugin-tests.sh [--help]

set -uo pipefail

case "${1:-}" in
  --help|-h)
    sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'
    exit 0
    ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# scripts -> maintainer -> skills -> plugin root
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

step_status=()
overall=0

run_step() {
  local label="$1"; shift
  echo "=== $label ==="
  if "$@"; then
    step_status+=("PASS  $label")
  else
    step_status+=("FAIL  $label")
    overall=1
  fi
  echo
}

self_test() {
  bash "$SCRIPT_DIR/run-self-test.sh"
}

check_references() {
  bash "$SCRIPT_DIR/check-skill-references.sh"
}

validate() {
  if ! command -v claude >/dev/null 2>&1; then
    echo "SKIP: claude CLI not on PATH"
    return 0
  fi
  claude plugin validate --strict "$PLUGIN_ROOT"
}

run_step "self-test" self_test
run_step "check-references" check_references
run_step "validate (claude plugin validate --strict)" validate

echo "==== battery summary ===="
for s in "${step_status[@]}"; do
  echo "  $s"
done
[ "$overall" -eq 0 ] && echo "RESULT: PASS" || echo "RESULT: FAIL"
exit "$overall"
