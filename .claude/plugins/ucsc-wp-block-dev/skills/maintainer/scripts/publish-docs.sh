#!/usr/bin/env bash
# implements: ADR-063-MAINTAINER-PUBLISH, ADR-107-MAINTAINER-DOCS-MODE-CONSOLIDATION
#
# Hardened orchestrator for `maintainer docs publish`.
#
# Usage:
#   publish-docs.sh --confirm                 # publish slides, then guide
#   publish-docs.sh --target slides --confirm # publish slides only
#   publish-docs.sh --target guide --confirm  # publish guide only
#   publish-docs.sh --dry-run                 # preflight + refresh + tests only

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: publish-docs.sh [--target both|slides|guide] [--confirm|--dry-run]

Hardened publisher for the ucsc-wp-block-dev maintainer documentation.

  --target VALUE  Output to publish: both (default), slides, or guide.
                  The compatibility value "deck" is accepted as slides.
  --confirm       Required before any Google Docs upload.
  --dry-run       Run preflight, refresh, and tests without uploading.
  --help, -h      Show this help.

Bare `docs publish` maps to:
  publish-docs.sh --target both --confirm
EOF
}

TARGET="both"
CONFIRM=0
DRY_RUN=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target)
      [ "$#" -ge 2 ] || { echo "ERROR: --target requires a value" >&2; exit 2; }
      TARGET="$2"
      shift 2
      ;;
    --confirm)
      CONFIRM=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

case "$TARGET" in
  both|slides|guide)
    ;;
  deck)
    TARGET="slides"
    ;;
  *)
    echo "ERROR: --target must be both, slides, guide, or deck" >&2
    exit 2
    ;;
esac

if [ "$CONFIRM" -eq 1 ] && [ "$DRY_RUN" -eq 1 ]; then
  echo "ERROR: use either --confirm or --dry-run, not both" >&2
  exit 2
fi

if [ "$CONFIRM" -ne 1 ] && [ "$DRY_RUN" -ne 1 ]; then
  echo "ERROR: publishing requires --confirm; use --dry-run for local validation" >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
PROJECT_ROOT="$(cd "$PLUGIN_ROOT/../../.." && pwd)"

SLIDES="$PLUGIN_ROOT/skills/maintainer/assets/ucsc-wp-block-dev-presentation.md"
GUIDE="$PLUGIN_ROOT/skills/maintainer/references/generate-docs-main.md"
PUBLISHER="$PROJECT_ROOT/.claude/scripts/publish_to_gdoc.py"
REFRESH_SLIDES="$SCRIPT_DIR/refresh-and-publish-slides.sh"
REFRESH_GUIDE="$SCRIPT_DIR/refresh-and-publish-docs.sh"
CHECK_REFS="$SCRIPT_DIR/check-skill-references.sh"
REGENERATE="$SCRIPT_DIR/regenerate-docs.sh"
PUBLISH_ENV="$SCRIPT_DIR/publish-env.sh"

PYTHON="$PROJECT_ROOT/.claude/scripts/.venv/bin/python"
[ -x "$PYTHON" ] || PYTHON="python3"

RUN_ID="$(date +%Y%m%d-%H%M%S)-$$"
LOG_DIR="${TMPDIR:-/tmp}/ucsc-wp-block-dev-publish-$RUN_ID"
mkdir -p "$LOG_DIR"

status_line() {
  printf "  %-8s %s\n" "$1" "$2"
}

fail() {
  status_line "[FAIL]" "$1" >&2
  printf "RESULT: FAIL (logs: %s)\n" "$LOG_DIR" >&2
  exit 1
}

require_file() {
  [ -f "$1" ] || fail "missing file: $1"
}

require_file "$PUBLISH_ENV"
# shellcheck disable=SC1090
. "$PUBLISH_ENV"
load_publish_env "$PROJECT_ROOT"

if [ "$TARGET" = "both" ] || [ "$TARGET" = "slides" ]; then
  require_google_doc_url UCSC_WP_BLOCK_DEV_SLIDES_DOC_URL "slides" || fail "slides destination is not configured"
fi
if [ "$TARGET" = "both" ] || [ "$TARGET" = "guide" ]; then
  require_google_doc_url UCSC_WP_BLOCK_DEV_GUIDE_DOC_URL "guide" || fail "guide destination is not configured"
fi
SLIDES_DOC_URL="${UCSC_WP_BLOCK_DEV_SLIDES_DOC_URL:-not requested}"
GUIDE_DOC_URL="${UCSC_WP_BLOCK_DEV_GUIDE_DOC_URL:-not requested}"

echo "=== docs publish preflight ==="
status_line "[INFO]" "target: $TARGET"
status_line "[INFO]" "slides: $SLIDES_DOC_URL"
status_line "[INFO]" "guide:  $GUIDE_DOC_URL"
status_line "[INFO]" "logs:   $LOG_DIR"

require_file "$PUBLISHER"
require_file "$REFRESH_SLIDES"
require_file "$REFRESH_GUIDE"
require_file "$CHECK_REFS"
require_file "$REGENERATE"
require_file "$PLUGIN_ROOT/.claude-plugin/plugin.json"

if [ ! -f "$PROJECT_ROOT/.claude/scripts/service_account.json" ] \
  && [ ! -f "$PROJECT_ROOT/.claude/scripts/credentials.json" ] \
  && [ ! -f "$PROJECT_ROOT/.claude/scripts/token.json" ] \
  && [ ! -f "$HOME/.config/gcloud/application_default_credentials.json" ]; then
  fail "no supported Google credentials found"
fi

if ! "$PYTHON" -c 'import googleapiclient, markdown' >/dev/null 2>&1; then
  fail "publisher dependencies are unavailable in $PYTHON"
fi
status_line "[ OK ]" "local dependencies and Google credentials found"

echo "=== refresh and validate (no uploads) ==="
if [ "$TARGET" = "both" ] || [ "$TARGET" = "slides" ]; then
  if bash "$REFRESH_SLIDES" --no-publish >"$LOG_DIR/slides-refresh.log" 2>&1; then
    status_line "[ OK ]" "slides refreshed and tested"
  else
    tail -n 25 "$LOG_DIR/slides-refresh.log" >&2
    fail "slides refresh/tests failed"
  fi
  require_file "$SLIDES"
fi

if [ "$TARGET" = "both" ] || [ "$TARGET" = "guide" ]; then
  if bash "$REFRESH_GUIDE" --no-publish >"$LOG_DIR/guide-refresh.log" 2>&1; then
    status_line "[ OK ]" "guide refreshed and tested"
  else
    tail -n 25 "$LOG_DIR/guide-refresh.log" >&2
    fail "guide refresh/tests failed"
  fi
  require_file "$GUIDE"
fi

if bash "$CHECK_REFS" >"$LOG_DIR/references.log" 2>&1; then
  status_line "[ OK ]" "skill references pass"
else
  tail -n 25 "$LOG_DIR/references.log" >&2
  fail "skill reference check failed"
fi

if bash "$REGENERATE" --check >"$LOG_DIR/freshness.log" 2>&1; then
  status_line "[ OK ]" "generated documentation is fresh"
else
  cat "$LOG_DIR/freshness.log" >&2
  fail "generated documentation is stale"
fi

if [ "$DRY_RUN" -eq 1 ]; then
  echo "RESULT: PASS (dry-run; no external writes)"
  exit 0
fi

publish_one() {
  label="$1"
  source="$2"
  destination="$3"
  log="$LOG_DIR/$label-publish.log"

  status_line "[....]" "publishing $label"
  if "$PYTHON" "$PUBLISHER" --source "$source" --doc "$destination" >"$log" 2>&1; then
    status_line "[ OK ]" "$label published"
    return 0
  fi

  tail -n 25 "$log" >&2
  return 1
}

echo "=== publish ==="
SLIDES_RESULT="SKIP"
GUIDE_RESULT="SKIP"

if [ "$TARGET" = "both" ] || [ "$TARGET" = "slides" ]; then
  if publish_one "slides" "$SLIDES" "$SLIDES_DOC_URL"; then
    SLIDES_RESULT="PASS"
  else
    SLIDES_RESULT="FAIL"
  fi
fi

if [ "$SLIDES_RESULT" != "FAIL" ] && { [ "$TARGET" = "both" ] || [ "$TARGET" = "guide" ]; }; then
  if publish_one "guide" "$GUIDE" "$GUIDE_DOC_URL"; then
    GUIDE_RESULT="PASS"
  else
    GUIDE_RESULT="FAIL"
  fi
elif [ "$TARGET" = "both" ]; then
  GUIDE_RESULT="BLOCKED"
fi

echo "=== publish summary ==="
status_line "$SLIDES_RESULT" "slides"
status_line "$GUIDE_RESULT" "guide"

if [ "$SLIDES_RESULT" = "FAIL" ] || [ "$GUIDE_RESULT" = "FAIL" ] || [ "$GUIDE_RESULT" = "BLOCKED" ]; then
  echo "RESULT: FAIL (logs: $LOG_DIR)"
  exit 1
fi

echo "RESULT: PASS"
