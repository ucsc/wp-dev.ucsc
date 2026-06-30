#!/bin/bash
# refresh-and-publish-slides.sh — one-call slide refresh + publish (ADR-015, ADR-018, ADR-088).
# Token-frugal: 1) bump the deck's Generated: date to today, 2) run the deck-contract
# tests, 3) publish to the canonical Google Doc. Compact PASS/FAIL output; verbose
# detail goes to logfiles named on exit.
#
# Usage:
#   refresh-and-publish-slides.sh              # refresh + test + publish
#   refresh-and-publish-slides.sh --no-publish # refresh + test only (no upload)

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

# scripts/ -> maintainer -> skills -> plugin root; project root is three more up.
PLUGIN_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
PROJECT_ROOT="$(cd "$PLUGIN_ROOT/../../.." && pwd)"
PUBLISH_ENV="$PLUGIN_ROOT/skills/maintainer/scripts/publish-env.sh"
DECK="$PLUGIN_ROOT/skills/maintainer/assets/ucsc-wp-block-dev-presentation.md"
PUBLISHER="$PROJECT_ROOT/.claude/scripts/publish_to_gdoc.py"
TODAY="$(date +%Y-%m-%d)"
NO_PUBLISH=0
[ "${1:-}" = "--no-publish" ] && NO_PUBLISH=1

[ -f "$DECK" ] || { echo "  [FAIL] deck not found: $DECK"; exit 2; }

# 1. bump Generated: date (idempotent; perl for macOS/Linux portability)
if grep -qE '\*\*Generated:\*\* [0-9]{4}-[0-9]{2}-[0-9]{2}<br />' "$DECK"; then
  perl -pi -e "s{\\*\\*Generated:\\*\\* \\d{4}-\\d{2}-\\d{2}<br />}{**Generated:** ${TODAY}<br />}" "$DECK"
  echo "  [ OK ] Generated date = $TODAY"
else
  echo "  [FAIL] Generated: line not found in deck"; exit 1
fi

# 2. deck-contract tests (maintainer-owned path, every skill listed, date format)
PYTEST="$PLUGIN_ROOT/../ucsc-wp-block-dev-venv/bin/pytest"
[ -x "$PYTEST" ] || PYTEST="python3 -m pytest"
TLOG="/tmp/ucsc-slides-test-$(date +%H%M%S).log"
if ( cd "$PLUGIN_ROOT" && $PYTEST -q tests/test_plugin_structure.py::TestMaintainerSlideDeck >"$TLOG" 2>&1 ); then
  echo "  [ OK ] deck-contract tests pass"
else
  echo "  [FAIL] deck-contract tests (log: $TLOG)"; tail -n 20 "$TLOG"; exit 1
fi

# 3. publish
if [ "$NO_PUBLISH" -eq 1 ]; then
  echo "  [SKIP] publish (--no-publish)"
  echo "RESULT: PASS (refresh only)"
  exit 0
fi
[ -f "$PUBLISH_ENV" ] || { echo "  [FAIL] publish environment helper not found: $PUBLISH_ENV"; exit 2; }
# shellcheck disable=SC1090
. "$PUBLISH_ENV"
load_publish_env "$PROJECT_ROOT"
require_google_doc_url UCSC_WP_BLOCK_DEV_SLIDES_DOC_URL "slides" || exit $?
GDOC_URL="$UCSC_WP_BLOCK_DEV_SLIDES_DOC_URL"
[ -f "$PUBLISHER" ] || { echo "  [FAIL] publisher not found: $PUBLISHER"; exit 2; }
PLOG="/tmp/ucsc-slides-publish-$(date +%H%M%S).log"
echo "  ...  publishing to Google Doc"
if python3 "$PUBLISHER" --doc "$GDOC_URL" >"$PLOG" 2>&1; then
  echo "  [ OK ] published"
  echo "RESULT: PASS"
else
  echo "  [FAIL] publish (log: $PLOG)"; tail -n 25 "$PLOG"
  echo "RESULT: FAIL"
  exit 1
fi
