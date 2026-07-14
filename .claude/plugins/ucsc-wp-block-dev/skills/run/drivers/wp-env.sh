#!/bin/bash
# implements: ADR-105-RUN-RUNTIME-MODE-SUPPORT-MULTIPLE-WP-LOCAL-RUNTIMES
# wp-env.sh — WordPress.org wp-env driver (Phase 4a: full lifecycle).
#
# Full driver for developers using @wordpress/env instead of the home-rolled
# wp-dev.ucsc Docker stack. Mirrors wp-dev-ucsc.sh's phase interface
# (inspect/build/launch/smoke/drive/down/all) so `driver.sh <env> <phase>`
# behaves the same regardless of which runtime is selected.
#
# Requires .wp-env.json at the repo root — see wp-env-example.json one
# directory up (skills/run/wp-env-example.json) to scaffold one; copy it to
# the repo root as .wp-env.json, same pattern as .env.example.txt.
#
# NOT SUPPORTED: LDAP-dependent blocks (Campus Directory). The default wp-env
# WordPress image has no PHP LDAP extension and no UCSC VPN reachability —
# this is the gating constraint tracked in ADR-105. Non-LDAP blocks work fine.
#
# Unlike wp-dev-ucsc.sh, this driver runs `npm` on the host for the `build`
# phase: wp-env has no equivalent to the wp-dev-ucsc.sh in-repo build
# container, and a developer using wp-env is, by definition, not inside the
# wp-dev.ucsc Docker stack the "never run host Node" guardrail targets.
#
# Usage:
#   wp-env.sh inspect   # non-destructive: .wp-env.json, wp-env CLI, plugin dir
#   wp-env.sh build     # npm run build in the plugin dir (host)
#   wp-env.sh launch    # wp-env start + activate plugin
#   wp-env.sh smoke     # health: wp-env running, wp-admin HTTP, plugin active, blocks
#   wp-env.sh drive URL # headless Chrome: post-JS DOM + console errors (UCSC_SHOT=path for a screenshot)
#   wp-env.sh all       # inspect -> build -> launch -> smoke (default)
#   wp-env.sh down      # wp-env stop
#
# Plugin is autodetected from the current directory; override with
# UCSC_PLUGIN=<slug>. Override the wp-env binary with WP_ENV_BIN (default:
# `wp-env` if on PATH, else `npx --yes @wordpress/env`).

set -uo pipefail

usage() {
  sed -n '2,32p' "$0" | sed 's/^# \{0,1\}//'
}

case "${1:-}" in
  --help|-h)
    usage
    exit 0
    ;;
esac

detect_plugin() {
  case "$PWD" in
    */wp-content/plugins/*) local rest="${PWD#*/wp-content/plugins/}"; echo "${rest%%/*}"; return 0 ;;
  esac
  return 1
}
PLUGIN="${UCSC_PLUGIN:-$(detect_plugin || echo ucsc-gutenberg-blocks)}"
LOG="${UCSC_RUN_LOG:-/tmp/ucsc-run-wp-env-$(date +%Y%m%d-%H%M%S).log}"
FAILED=0

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" && pwd)"
SOURCE_BASE="$SCRIPT_DIR/../../develop/scripts/source-base.sh"
# shellcheck source=../lib/drive.sh
source "$SCRIPT_DIR/../lib/drive.sh"

find_root() {
  local d
  if [ -f "$SOURCE_BASE" ]; then
    d="$(bash "$SOURCE_BASE" repo-root 2>/dev/null || true)"
    [ -n "$d" ] && { echo "$d"; return 0; }
  fi
  for d in "${WP_DEV_ROOT:-}" "$PWD" "$(cd "$(dirname "$0")" && pwd)"; do
    [ -n "$d" ] || continue
    while [ -n "$d" ] && [ "$d" != "/" ]; do
      if [ -f "$d/.wp-env.json" ] || [ -f "$d/docker-compose.yml" ]; then
        echo "$d"; return 0
      fi
      d=$(dirname "$d")
    done
  done
  return 1
}

ROOT="$(find_root)" || { echo "ERROR: could not locate repo root (set WP_DEV_ROOT=)"; exit 2; }
cd "$ROOT" || exit 2
CONFIG="$ROOT/.wp-env.json"

# Resolve the wp-env CLI: prefer a global/local `wp-env` on PATH, otherwise
# `npx --yes @wordpress/env` (matches the package's published bin name).
if [ -n "${WP_ENV_BIN:-}" ]; then
  read -r -a WP_ENV_CMD <<< "$WP_ENV_BIN"
elif command -v wp-env >/dev/null 2>&1; then
  WP_ENV_CMD=(wp-env)
else
  WP_ENV_CMD=(npx --yes @wordpress/env)
fi

wpenv() { "${WP_ENV_CMD[@]}" "$@"; }
wpc() { wpenv run cli "$@"; }

# Port comes from .wp-env.json ("port": N); WP_ENV_PORT overrides both
# (matches wp-env's own precedence), default 8888.
port_from_config() {
  [ -f "$CONFIG" ] || { echo 8888; return; }
  local p
  p=$(grep -o '"port"[[:space:]]*:[[:space:]]*[0-9]*' "$CONFIG" | grep -o '[0-9]*$' | head -n1)
  echo "${p:-8888}"
}
PORT="${WP_ENV_PORT:-$(port_from_config)}"
APP_URL="http://localhost:${PORT}/"

pass() { printf '  [ OK ] %s\n' "$1"; }
fail() { printf '  [FAIL] %s\n' "$1"; FAILED=1; }

# wp-env manages its own Docker containers internally; still needs a running daemon.
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
  echo "inspect (root: $ROOT, wp-env: ${WP_ENV_CMD[*]})"
  [ -f "$CONFIG" ] && pass ".wp-env.json present" \
    || fail ".wp-env.json missing (copy skills/run/wp-env-example.json to $ROOT/.wp-env.json)"
  [ -d "$ROOT/public/wp-content/plugins/${PLUGIN}" ] && pass "plugin checked out" || fail "plugin dir missing"
  if command -v wp-env >/dev/null 2>&1 || command -v npx >/dev/null 2>&1; then
    pass "wp-env CLI resolvable (${WP_ENV_CMD[*]})"
  else
    fail "neither wp-env nor npx found on PATH"
  fi
  echo "  ...  target URL: $APP_URL"
}

do_build() {
  echo "build ($PLUGIN)"
  local pdir="$ROOT/public/wp-content/plugins/${PLUGIN}"
  if [ ! -d "$pdir" ]; then
    fail "plugin dir missing: $pdir"; return
  fi
  if [ ! -x "$pdir/node_modules/.bin/wp-scripts" ]; then
    echo "  ...  installing node deps (first build for $PLUGIN)"
    if ! (cd "$pdir" && npm ci) >>"$LOG" 2>&1; then
      fail "npm ci (see log)"; return
    fi
  fi
  if (cd "$pdir" && npm run build) >>"$LOG" 2>&1; then
    if [ -f "$pdir/build/index.js" ] || find "$pdir/build" -name '*.js' -type f 2>/dev/null | grep -q .; then
      pass "build output produced"
    else
      fail "build ran but no JS output under build/"
    fi
  else
    fail "npm run build (see log)"
  fi
}

wait_wp_env_cli() {
  local i
  for i in $(seq 1 30); do
    if wpc wp option get siteurl >>"$LOG" 2>&1; then
      return 0
    fi
    sleep 2
  done
  return 1
}

do_launch() {
  echo "launch"
  [ -f "$CONFIG" ] || { fail ".wp-env.json missing — run 'inspect' for scaffold instructions"; return; }
  wpenv start >>"$LOG" 2>&1 && pass "wp-env start" || { fail "wp-env start (see log)"; return; }
  if wait_wp_env_cli; then
    pass "cli container reachable"
  else
    fail "cli container not reachable after 60s (see log)"
    return
  fi
  if wpc wp plugin activate "$PLUGIN" >>"$LOG" 2>&1; then
    pass "plugin activated"
  else
    fail "plugin activate (see log)"
  fi
}

do_smoke() {
  echo "smoke"
  local code
  code=$(curl -s -o /dev/null -w '%{http_code}' "$APP_URL" 2>>"$LOG" || true)
  case "$code" in
    200|301|302) pass "wp-admin HTTP $code" ;;
    *) fail "wp-admin HTTP ${code:-no-response}" ;;
  esac
  local status
  status=$(wpc wp plugin list --name="$PLUGIN" --field=status 2>>"$LOG" | tr -d '\r' || true)
  [ "$status" = "active" ] && pass "plugin status: active" || fail "plugin status: ${status:-unknown}"
  # Blocks registered — same reviewed PHP as wp-dev-ucsc.sh (helpers/list-blocks.php),
  # piped over stdin so no PHP is embedded in a shell string (ADR-095).
  local blocks nblocks
  blocks=$(wpc wp eval-file - < "$SCRIPT_DIR/../helpers/list-blocks.php" 2>>"$LOG" || true)
  nblocks=$(printf '%s\n' "$blocks" | grep -c . || true)
  if [ "$nblocks" -gt 0 ]; then
    pass "$nblocks ucsc* block(s) registered"
    printf '%s\n' "$blocks" | grep . | sed 's/^/  ...    /'
  else
    fail "no ucsc* blocks registered (see log — wp-env run's stdin handling can vary; rerun with UCSC_RUN_LOG set to inspect)"
  fi
}

do_drive() {
  local url="${1:-$APP_URL}"
  echo "drive ($url)"
  drive_url "$url" "$LOG"
}

do_down() { echo "down"; wpenv stop >>"$LOG" 2>&1 && pass "wp-env stopped" || fail "wp-env stop (see log)"; }

# --- dispatch ---------------------------------------------------------------
cmd="${1:-all}"
require_docker
case "$cmd" in
  inspect) do_inspect ;;
  build)   do_build ;;
  launch)  do_launch ;;
  smoke)   do_smoke ;;
  drive)   do_drive "${2:-}" ;;
  down)    do_down ;;
  all)     do_inspect; do_build; do_launch; do_smoke ;;
  *) echo "usage: wp-env.sh [inspect|build|launch|smoke|drive URL|all|down]"; exit 2 ;;
esac

echo "----"
[ "$FAILED" -eq 0 ] && echo "RESULT: PASS" || { echo "RESULT: FAIL  (log: $LOG)"; tail -n 20 "$LOG" 2>/dev/null; }
echo "log: $LOG"
exit "$FAILED"
