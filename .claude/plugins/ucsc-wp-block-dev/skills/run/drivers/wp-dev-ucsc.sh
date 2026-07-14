#!/bin/bash
# driver.sh — token-frugal run harness for ucsc-gutenberg-blocks in the
# wp-dev.ucsc Docker environment. One call runs a whole lifecycle phase and
# prints a compact PASS/FAIL summary; verbose output goes to a logfile.
#
# Usage:
#   driver.sh inspect   # non-destructive: .env, plugin dir, container state
#   driver.sh build     # compile src/ -> build/ via Dockerized @wordpress/scripts
#   driver.sh launch    # docker compose up -d + activate plugin
#   driver.sh smoke      # health: containers, wp-admin HTTP, plugin active, blocks
#   driver.sh drive URL # headless Chrome: post-JS DOM + console errors of a frontend URL (UCSC_SHOT=path for an optional screenshot)
#   driver.sh all       # inspect -> build -> launch -> smoke (default)
#   driver.sh down      # stop the stack
#
# Plugin is autodetected from the current directory (any .../plugins/<slug>);
# override with UCSC_PLUGIN=<slug>. ucsc-blocks and ucsc-gutenberg-blocks share
# the one wp-dev.ucsc Docker runtime, so each builds via a -w working-dir
# override against the same plugin_npm_start service (no per-plugin service).
# Override the project root with WP_DEV_ROOT=/path if autodetection fails.
# Full log path is printed on every run; read it only when a step FAILs.

set -uo pipefail

usage() {
  sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
}

case "${1:-}" in
  --help|-h)
    usage
    exit 0
    ;;
esac

# Autodetect the plugin from the invocation directory (any path segment under
# .../wp-content/plugins/<slug>); fall back to ucsc-gutenberg-blocks. Override
# with UCSC_PLUGIN=<slug>. Detect from $PWD before any cd below.
detect_plugin() {
  case "$PWD" in
    */wp-content/plugins/*) local rest="${PWD#*/wp-content/plugins/}"; echo "${rest%%/*}"; return 0 ;;
  esac
  return 1
}
PLUGIN="${UCSC_PLUGIN:-$(detect_plugin || echo ucsc-gutenberg-blocks)}"
PLUGIN_CPATH="/var/www/html/wp-content/plugins/${PLUGIN}"
APP_HOST="wp-dev.ucsc"
APP_URL="https://${APP_HOST}/wp-admin/"
LOG="${UCSC_RUN_LOG:-/tmp/ucsc-run-$(date +%Y%m%d-%H%M%S).log}"
FAILED=0

# --- locate the wp-dev.ucsc root -------------------------------------------
# Prefer the shared source-base resolver so every driver agrees on the repo root
# (ADR-095). Self-locate it relative to this driver; fall back to inline walk-up.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" && pwd)"
SOURCE_BASE="$SCRIPT_DIR/../../develop/scripts/source-base.sh"

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

dc() { docker compose "$@"; }

# detail = compact one-liner; everything noisy is appended to $LOG
pass() { printf '  [ OK ] %s\n' "$1"; }
fail() { printf '  [FAIL] %s\n' "$1"; FAILED=1; }

# Pre-flight: every phase talks to Docker, so a stopped daemon otherwise makes
# each `docker compose` call print the same "Cannot connect to the Docker
# daemon" line — flooding the log with ~20 identical errors. Probe once and emit
# a single actionable line instead.
require_docker() {
  if ! docker info >/dev/null 2>&1; then
    echo "preflight"
    fail "Docker daemon not running — start Docker Desktop, then re-run"
    echo "  ...  open -a Docker   (wait until 'docker info' succeeds)"
    echo "----"
    echo "RESULT: FAIL  (Docker daemon unreachable)"
    exit 1
  fi
}

# --- phases -----------------------------------------------------------------
do_inspect() {
  echo "inspect (root: $ROOT)"
  [ -f "$ROOT/.env" ] && pass ".env present" || fail ".env missing (copy .env.example.txt)"
  [ -d "$ROOT/public/wp-content/plugins/${PLUGIN}" ] && pass "plugin checked out" || fail "plugin dir missing"
  local running
  running=$(dc ps --status running --services 2>>"$LOG" | grep -c . || true)
  echo "  ...  $running container(s) running"
}

do_build() {
  echo "build ($PLUGIN)"
  local pdir="$ROOT/public/wp-content/plugins/${PLUGIN}"
  # Each plugin has its own node_modules; install in-container on first build.
  if [ ! -x "$pdir/node_modules/.bin/wp-scripts" ]; then
    echo "  ...  installing node deps (first build for $PLUGIN)"
    if ! dc -f docker-compose.yml -f docker-compose-start.yml run --rm \
          -w "$PLUGIN_CPATH" plugin_npm_start npm ci >>"$LOG" 2>&1; then
      fail "npm ci (see log)"; return
    fi
  fi
  if dc -f docker-compose.yml -f docker-compose-start.yml run --rm \
        -w "$PLUGIN_CPATH" plugin_npm_start npm run build >>"$LOG" 2>&1; then
    # Single-block plugins emit build/index.js; multi-block plugins emit
    # build/blocks/<name>/*.js. Accept either as proof of a successful compile.
    if [ -f "$pdir/build/index.js" ] || find "$pdir/build" -name '*.js' -type f 2>/dev/null | grep -q .; then
      pass "build output produced"
    else
      fail "build ran but no JS output under build/"
    fi
  else
    fail "npm run build (see log)"
  fi
}

# Wait until WordPress can reach the DB. The db container starts a few seconds
# after `up -d` returns, so wp-cli fails with "Error establishing a database
# connection" if called immediately. Retry for ~60s.
#
# Probe via `wp option get` (PHP/mysqli path) — NOT `wp db query`: the mysql CLI
# client in this container can't load caching_sha2_password.so, so every `wp db *`
# subcommand fails even when the database is perfectly healthy.
wait_db() {
  local i
  for i in $(seq 1 30); do
    if dc exec -T wpcli wp option get siteurl >>"$LOG" 2>&1; then
      return 0
    fi
    sleep 2
  done
  return 1
}

do_launch() {
  echo "launch"
  # --remove-orphans clears stale build containers (theme-build/plugin-build)
  dc up -d --remove-orphans >>"$LOG" 2>&1 && pass "docker compose up -d" || fail "docker compose up -d (see log)"
  if wait_db; then
    pass "database reachable"
  else
    fail "database not reachable after 60s (see log)"
    return
  fi
  if dc exec -T wpcli wp plugin activate "$PLUGIN" >>"$LOG" 2>&1; then
    pass "plugin activated"
  else
    fail "plugin activate (see log)"
  fi
}

do_smoke() {
  echo "smoke"
  # 1. containers
  local running
  running=$(dc ps --status running --services 2>>"$LOG" | grep -c . || true)
  [ "$running" -gt 0 ] && pass "$running container(s) running" || fail "no containers running"
  # 2. wp-admin reachable (self-signed cert -k; --resolve avoids /etc/hosts dependence)
  local code
  code=$(curl -k -s -o /dev/null -w '%{http_code}' --resolve "${APP_HOST}:443:127.0.0.1" "$APP_URL" 2>>"$LOG" || true)
  case "$code" in
    200|301|302) pass "wp-admin HTTP $code" ;;
    *) fail "wp-admin HTTP ${code:-no-response}" ;;
  esac
  # 3. plugin active
  local status
  status=$(dc exec -T wpcli wp plugin list --name="$PLUGIN" --field=status 2>>"$LOG" | tr -d '\r' || true)
  [ "$status" = "active" ] && pass "plugin status: active" || fail "plugin status: ${status:-unknown}"
  # 4. blocks registered — runtime registry via list-blocks.sh (reviewed PHP in
  #    a file, piped to wp-cli; spans ALL activated plugins, reads no repo source)
  local blocks nblocks
  blocks=$(bash "$SCRIPT_DIR/../list-blocks.sh" 2>>"$LOG" || true)
  nblocks=$(printf '%s\n' "$blocks" | grep -c . || true)
  if [ "$nblocks" -gt 0 ]; then
    pass "$nblocks ucsc* block(s) registered"
    printf '%s\n' "$blocks" | grep . | sed 's/^/  ...    /'
  else
    fail "no ucsc* blocks registered"
  fi
}

# Drive a frontend URL with a real headless browser to prove client JS runs.
# Shared across every environment driver (lib/drive.sh); MAP resolves this
# stack's vanity host to localhost so the headless run doesn't depend on
# /etc/hosts. No login: drives public frontend pages (wp-admin needs a
# session headless can't supply).
# shellcheck source=../lib/drive.sh
source "$SCRIPT_DIR/../lib/drive.sh"

do_drive() {
  local url="${1:-https://${APP_HOST}/}"
  echo "drive ($url)"
  drive_url "$url" "$LOG" "MAP ${APP_HOST} 127.0.0.1"
}

do_down() { echo "down"; dc down >>"$LOG" 2>&1 && pass "stack stopped" || fail "docker compose down (see log)"; }

# List every ucsc/* block registered in the running WP (all activated plugins).
do_blocks() {
  echo "blocks"
  local blocks nblocks
  blocks=$(bash "$SCRIPT_DIR/../list-blocks.sh" 2>>"$LOG" || true)
  nblocks=$(printf '%s\n' "$blocks" | grep -c . || true)
  if [ "$nblocks" -gt 0 ]; then
    pass "$nblocks ucsc* block(s) registered (all plugins)"
    printf '%s\n' "$blocks" | grep . | sed 's/^/  ...    /'
  else
    fail "no ucsc* blocks registered"
  fi
}

# Seed the registry-driven demo page (all registered ucsc/* blocks), then drive
# it in a real browser to prove the blocks render across whatever plugins exist.
do_demo() {
  echo "demo"
  local url
  url=$(bash "$SCRIPT_DIR/../seed-demo-page.sh" 2>>"$LOG" | tr -d '\r' | grep -E '^https?://' | tail -n1)
  if [ -n "$url" ]; then
    pass "demo page seeded ($url)"
    do_drive "$url"
  else
    fail "demo page seed failed (see log)"
  fi
}

# --- dispatch ---------------------------------------------------------------
cmd="${1:-all}"
require_docker
case "$cmd" in
  inspect) do_inspect ;;
  build)   do_build ;;
  launch)  do_launch ;;
  smoke)   do_smoke ;;
  blocks)  do_blocks ;;
  demo)    do_demo ;;
  drive)   do_drive "${2:-}" ;;
  down)    do_down ;;
  all)     do_inspect; do_build; do_launch; do_smoke ;;
  *) echo "usage: driver.sh [inspect|build|launch|smoke|blocks|demo|drive URL|all|down]"; exit 2 ;;
esac

echo "----"
[ "$FAILED" -eq 0 ] && echo "RESULT: PASS" || { echo "RESULT: FAIL  (log: $LOG)"; tail -n 20 "$LOG" 2>/dev/null; }
echo "log: $LOG"
exit "$FAILED"
