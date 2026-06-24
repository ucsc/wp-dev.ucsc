#!/bin/bash
# verify/driver.sh — deterministic runtime checks for a ucsc-gutenberg-blocks
# change, in one token-frugal call. This is the *substrate* of a verification:
# it proves the code is built, active, and server-side registered/rendering.
# It does NOT replace the browser/editor acceptance check in SKILL.md — visual
# and interaction behavior still needs the live app.
#
# Usage:
#   driver.sh [block-slug] [--url URL] [--needle STRING]
#
# Examples:
#   driver.sh                                   # env + build freshness + list ucsc* blocks
#   driver.sh course-catalog                    # also assert a course-catalog block is registered
#   driver.sh course-catalog --url https://wp-dev.ucsc/catalog/ --needle wp-block
#
# Override project root with WP_DEV_ROOT=/path. Full log path printed on exit;
# read it only on FAIL.

set -uo pipefail

usage() {
  sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'
}

case "${1:-}" in
  --help|-h)
    usage
    exit 0
    ;;
esac

PLUGIN="ucsc-gutenberg-blocks"
APP_HOST="wp-dev.ucsc"
LOG="${UCSC_VERIFY_LOG:-/tmp/ucsc-verify-$(date +%Y%m%d-%H%M%S).log}"
FAILED=0

SLUG=""
URL=""
NEEDLE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --url) URL="${2:-}"; shift 2 ;;
    --needle) NEEDLE="${2:-}"; shift 2 ;;
    -*) echo "unknown flag: $1"; exit 2 ;;
    *) SLUG="$1"; shift ;;
  esac
done

# Prefer the shared source-base resolver so every driver agrees on the repo root
# (ADR-095). Self-locate it relative to this driver; fall back to inline walk-up.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" && pwd)"
SOURCE_BASE="$SCRIPT_DIR/../develop/scripts/source_base.sh"

find_root() {
  local d
  if [ -f "$SOURCE_BASE" ]; then
    d="$(bash "$SOURCE_BASE" repo-root 2>/dev/null || true)"
    if [ -n "$d" ] && [ -d "$d/public/wp-content/plugins/${PLUGIN}" ]; then
      echo "$d"; return 0
    fi
  fi
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
pass() { printf '  [ OK ] %s\n' "$1"; }
fail() { printf '  [FAIL] %s\n' "$1"; FAILED=1; }
warn() { printf '  [WARN] %s\n' "$1"; }

echo "verify (root: $ROOT${SLUG:+, block: $SLUG})"

# 1. plugin active (PHP/mysqli path — never `wp db`, which fails on caching_sha2_password)
status=$(dc exec -T wpcli wp plugin list --name="$PLUGIN" --field=status 2>>"$LOG" | tr -d '\r' || true)
if [ "$status" = "active" ]; then
  pass "plugin active"
else
  fail "plugin not active (status: ${status:-unknown}) — run: run/driver.sh launch"
fi

# 2. build freshness — is build/ newer than every source file?
if [ -f "$PDIR/build/index.js" ]; then
  stale=$(find "$PDIR/src" -type f -newer "$PDIR/build/index.js" -print -quit 2>>"$LOG" || true)
  if [ -n "$stale" ]; then
    fail "build is STALE (src changed since last build) — run: run/driver.sh build"
  else
    pass "build up to date with src/"
  fi
else
  fail "build/index.js missing — run: run/driver.sh build"
fi

# 3. block registry (server-side, render-callback blocks register on init)
blocks=$(dc exec -T wpcli wp eval \
  'foreach (WP_Block_Type_Registry::get_instance()->get_all_registered() as $n=>$b){ if (strpos($n,"ucsc")===0) echo $n,"\n"; }' \
  2>>"$LOG" | tr -d '\r' || true)
nblocks=$(printf '%s\n' "$blocks" | grep -c . || true)
if [ "$nblocks" -gt 0 ]; then
  pass "$nblocks ucsc* block(s) registered"
else
  fail "no ucsc* blocks registered"
fi
if [ -n "$SLUG" ]; then
  # Match hyphen/case-insensitively: 'campus-directory' should match 'campusdirectory'.
  norm_slug=$(printf '%s' "$SLUG" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9')
  if printf '%s\n' "$blocks" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9\n' | grep -q -- "$norm_slug"; then
    pass "block matching '$SLUG' registered"
  else
    fail "no registered ucsc* block matches '$SLUG'"
  fi
fi

# 4. optional frontend render check
if [ -n "$URL" ]; then
  body=$(curl -k -s --resolve "${APP_HOST}:443:127.0.0.1" "$URL" 2>>"$LOG" || true)
  code=$(curl -k -s -o /dev/null -w '%{http_code}' --resolve "${APP_HOST}:443:127.0.0.1" "$URL" 2>>"$LOG" || true)
  case "$code" in
    200) pass "URL $code: $URL" ;;
    *) fail "URL ${code:-no-response}: $URL" ;;
  esac
  if [ -n "$NEEDLE" ]; then
    if printf '%s' "$body" | grep -qF -- "$NEEDLE"; then
      pass "page contains needle: $NEEDLE"
    else
      fail "needle not found in page: $NEEDLE"
    fi
  fi
fi

echo "----"
if [ "$FAILED" -eq 0 ]; then
  echo "RESULT: PASS  (deterministic checks only — still confirm behavior in the live app)"
else
  echo "RESULT: FAIL  (log: $LOG)"; tail -n 20 "$LOG" 2>/dev/null
fi
echo "log: $LOG"
exit "$FAILED"
