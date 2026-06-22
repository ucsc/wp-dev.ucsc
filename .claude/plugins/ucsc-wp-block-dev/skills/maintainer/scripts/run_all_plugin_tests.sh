#!/bin/bash
# implements: ADR-064-MAINTAINER-OPT-IN-AGENTS, ADR-078-MAINTAINER-CLI-VALIDATE
# run_all_plugin_tests.sh — run the `maintainer all` deterministic battery in one command.
#
# Battery (token-frugal, no agents):
#   1. self-test         — bundled pytest suite (venv pytest, else host python3)
#   2. check-references  — every skill support file linked from its SKILL.md
#   3. validate          — `claude plugin validate --strict` structural check
#
# Agent-backed checks (plugin-dev:plugin-validator / skill-reviewer) are
# deliberately excluded per ADR-064; request those explicitly.
#
# Runs from any cwd: paths resolve relative to this script. Prints a compact
# per-step PASS/FAIL and a final summary. Exit 0 only if every step passes.
#
# Usage:  run_all_plugin_tests.sh [--help]

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
VENV_PYTEST="$PLUGIN_ROOT-venv/bin/pytest"

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
  if [ -x "$VENV_PYTEST" ]; then
    ( cd "$PLUGIN_ROOT" && "$VENV_PYTEST" -q )
  elif command -v pytest >/dev/null 2>&1; then
    ( cd "$PLUGIN_ROOT" && pytest -q )
  else
    ( cd "$PLUGIN_ROOT" && python3 -m pytest -q )
  fi
}

check_references() {
  bash "$SCRIPT_DIR/check_skill_references.sh"
}

validate() {
  if ! command -v claude >/dev/null 2>&1; then
    echo "SKIP: claude CLI not on PATH"
    return 0
  fi
  claude plugin validate --strict "$PLUGIN_ROOT"
}

run_step "self-test (pytest)" self_test
run_step "check-references" check_references
run_step "validate (claude plugin validate --strict)" validate

echo "==== battery summary ===="
for s in "${step_status[@]}"; do
  echo "  $s"
done
[ "$overall" -eq 0 ] && echo "RESULT: PASS" || echo "RESULT: FAIL"
exit "$overall"
