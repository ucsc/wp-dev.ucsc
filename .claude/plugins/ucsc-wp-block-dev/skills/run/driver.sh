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
#   driver.sh all       # inspect -> build -> launch -> smoke (default)
#   driver.sh down      # stop the stack
#
# Override the project root with WP_DEV_ROOT=/path if autodetection fails.
# Full log path is printed on every run; read it only when a step FAILs.

set -uo pipefail

PLUGIN="ucsc-gutenberg-blocks"
PLUGIN_CPATH="/var/www/html/wp-content/plugins/${PLUGIN}"
APP_HOST="wp-dev.ucsc"
APP_URL="https://${APP_HOST}/wp-admin/"
LOG="${UCSC_RUN_LOG:-/tmp/ucsc-run-$(date +%Y%m%d-%H%M%S).log}"
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

dc() { docker compose "$@"; }

# detail = compact one-liner; everything noisy is appended to $LOG
pass() { printf '  [ OK ] %s\n' "$1"; }
fail() { printf '  [FAIL] %s\n' "$1"; FAILED=1; }

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
  echo "build"
  if dc -f docker-compose.yml -f docker-compose-start.yml run --rm \
        -w "$PLUGIN_CPATH" plugin_npm_start npm run build >>"$LOG" 2>&1; then
    if [ -f "$ROOT/public/wp-content/plugins/${PLUGIN}/build/index.js" ]; then
      pass "build/index.js produced"
    else
      fail "build ran but build/index.js missing"
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
  # 4. blocks registered (render-callback blocks register on init)
  local nblocks
  nblocks=$(dc exec -T wpcli wp eval \
    'foreach (WP_Block_Type_Registry::get_instance()->get_all_registered() as $n=>$b){ if (strpos($n,"ucsc")===0) echo $n,"\n"; }' \
    2>>"$LOG" | grep -c . || true)
  [ "$nblocks" -gt 0 ] && pass "$nblocks ucsc* block(s) registered" || fail "no ucsc* blocks registered"
}

do_down() { echo "down"; dc down >>"$LOG" 2>&1 && pass "stack stopped" || fail "docker compose down (see log)"; }

# --- dispatch ---------------------------------------------------------------
cmd="${1:-all}"
case "$cmd" in
  inspect) do_inspect ;;
  build)   do_build ;;
  launch)  do_launch ;;
  smoke)   do_smoke ;;
  down)    do_down ;;
  all)     do_inspect; do_build; do_launch; do_smoke ;;
  *) echo "usage: driver.sh [inspect|build|launch|smoke|all|down]"; exit 2 ;;
esac

echo "----"
[ "$FAILED" -eq 0 ] && echo "RESULT: PASS" || { echo "RESULT: FAIL  (log: $LOG)"; tail -n 20 "$LOG" 2>/dev/null; }
echo "log: $LOG"
exit "$FAILED"
