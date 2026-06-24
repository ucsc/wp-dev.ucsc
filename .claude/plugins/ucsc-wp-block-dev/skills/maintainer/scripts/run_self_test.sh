#!/bin/bash
# implements: ADR-078-MAINTAINER-CLI-VALIDATE, ADR-079-MAINTAINER-PLUGIN-DEV
# run_self_test.sh — deterministic self-test for the ucsc-wp-block-dev plugin.
#
# Runs:
#   1. The bundled pytest suite.
#   2. Upstream-inspired plugin and skill best-practice checks.
#
# Usage: run_self_test.sh [--help]

set -uo pipefail

case "${1:-}" in
  --help|-h)
    sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'
    exit 0
    ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
VENV_PYTEST="$PLUGIN_ROOT-venv/bin/pytest"
overall=0

echo "=== pytest contracts ==="
if [ -x "$VENV_PYTEST" ]; then
  ( cd "$PLUGIN_ROOT" && "$VENV_PYTEST" -q ) || overall=1
elif command -v pytest >/dev/null 2>&1; then
  ( cd "$PLUGIN_ROOT" && pytest -q ) || overall=1
else
  ( cd "$PLUGIN_ROOT" && python3 -m pytest -q ) || overall=1
fi

echo
echo "=== plugin best-practice checks ==="
python3 "$SCRIPT_DIR/check_plugin_best_practices.py" || overall=1

if [ "$overall" -eq 0 ]; then
  echo "SELF-TEST RESULT: PASS"
else
  echo "SELF-TEST RESULT: FAIL"
fi
exit "$overall"
