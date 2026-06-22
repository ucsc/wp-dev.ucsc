#!/bin/bash
# refresh_and_publish_docs.sh — one-call prose-guide refresh + publish (ADR-063).
# Token-frugal: 1) regenerate the portable Markdown artifacts from README + deck,
# 2) run the generate-docs contract tests, 3) publish the main guide to its
# Google Doc. Compact PASS/FAIL output; verbose detail goes to logfiles.
#
# Usage:
#   refresh_and_publish_docs.sh              # refresh + test + publish
#   refresh_and_publish_docs.sh --no-publish # refresh + test only (no upload)

set -uo pipefail

usage() {
  sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'
}

case "${1:-}" in
  --help|-h)
    usage
    exit 0
    ;;
esac

# Guide's destination Google Doc (the "main doc") — ADR-063.
GDOC_URL="https://docs.google.com/document/d/18Ozi1BJ60eH2_-mX5rpA08YsLtFwUAHC0nMErhsCxwo/edit"

# scripts/ -> maintainer -> skills -> plugin root; project root is three more up.
PLUGIN_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
PROJECT_ROOT="$(cd "$PLUGIN_ROOT/../../.." && pwd)"
REGEN="$PLUGIN_ROOT/skills/maintainer/scripts/regenerate-docs.sh"
GUIDE="$PLUGIN_ROOT/skills/maintainer/references/generate-docs-main.md"
PUBLISHER="$PROJECT_ROOT/.claude/scripts/publish_to_gdoc.py"
NO_PUBLISH=0
[ "${1:-}" = "--no-publish" ] && NO_PUBLISH=1

# 1. regenerate portable artifacts from README + canonical deck
[ -f "$REGEN" ] || { echo "  [FAIL] regenerate script not found: $REGEN"; exit 2; }
if bash "$REGEN" >/dev/null 2>&1; then
  echo "  [ OK ] regenerated documentation artifacts"
else
  echo "  [FAIL] regenerate artifacts"; exit 1
fi
[ -f "$GUIDE" ] || { echo "  [FAIL] guide not found: $GUIDE"; exit 2; }

# 2. generate-docs contract tests
PYTEST="$PLUGIN_ROOT/../ucsc-wp-block-dev-venv/bin/pytest"
[ -x "$PYTEST" ] || PYTEST="python3 -m pytest"
TLOG="/tmp/ucsc-docs-test-$(date +%H%M%S).log"
if ( cd "$PLUGIN_ROOT" && $PYTEST -q tests/test_plugin_structure.py -k "generate_docs or maintainer_reference" >"$TLOG" 2>&1 ); then
  echo "  [ OK ] generate-docs contract tests pass"
else
  echo "  [FAIL] generate-docs contract tests (log: $TLOG)"; tail -n 20 "$TLOG"; exit 1
fi

# 3. publish
if [ "$NO_PUBLISH" -eq 1 ]; then
  echo "  [SKIP] publish (--no-publish)"
  echo "RESULT: PASS (refresh only)"
  exit 0
fi
if [ "$GDOC_URL" = "<SET_GUIDE_DOC_URL>" ]; then
  echo "  [FAIL] guide Google Doc URL not set (edit GDOC_URL in this script — ADR-063)"
  echo "RESULT: FAIL"
  exit 1
fi
[ -f "$PUBLISHER" ] || { echo "  [FAIL] publisher not found: $PUBLISHER"; exit 2; }
PLOG="/tmp/ucsc-docs-publish-$(date +%H%M%S).log"
echo "  ...  publishing guide to Google Doc"
if python3 "$PUBLISHER" --source "$GUIDE" --doc "$GDOC_URL" >"$PLOG" 2>&1; then
  echo "  [ OK ] published"
  echo "RESULT: PASS"
else
  echo "  [FAIL] publish (log: $PLOG)"; tail -n 25 "$PLOG"
  echo "RESULT: FAIL"
  exit 1
fi
