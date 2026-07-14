#!/bin/bash
# implements: ADR-105-RUN-RUNTIME-MODE-SUPPORT-MULTIPLE-WP-LOCAL-RUNTIMES
# local.sh — LocalWP / Local by Flywheel driver (Phase 4b: full lifecycle).
#
# Full driver for developers using the LocalWP GUI app instead of the
# home-rolled wp-dev.ucsc Docker stack. Mirrors wp-env.sh's phase interface
# (inspect/build/launch/smoke/drive/down/all) so `driver.sh <env> <phase>`
# behaves the same regardless of which runtime is selected.
#
# Local has no official CLI (the archived getflywheel/local-cli was the only
# first-party attempt). This driver shells out to the third-party `lwp`
# (cartpauj/localwp-cli), which talks to Local's own local GraphQL API and
# requires the Local GUI app to be installed and running at least once. Install:
#   curl -fsSL https://raw.githubusercontent.com/cartpauj/localwp-cli/main/scripts/install.sh | bash
#
# Requires UCSC_LOCAL_SITE=<local-site-name-or-id> (see `lwp list`) — Local site
# names are per-developer and not part of this repo, so there is no default.
# The site's public URL is resolved from `lwp status <site>`; override with
# UCSC_LOCAL_URL=<url> if that parsing ever drifts from lwp's output format.
#
# NOT SUPPORTED: LDAP-dependent blocks (Campus Directory). Stock Local sites
# have no PHP LDAP extension or UCSC VPN reachability — same gating constraint
# as wp-env, tracked in ADR-105.
#
# ASSUMPTION: the plugin source this driver builds is this repo's own checkout
# (public/wp-content/plugins/<plugin>), the same as every other driver. A
# developer using Local is assumed to symlink their Local site's plugin
# directory to this checkout (the standard Local workflow for editing a
# plugin's source outside `~/Local Sites/`) rather than maintaining a second,
# disconnected copy inside the Local site. Like wp-env.sh, the `build` phase
# therefore runs `npm` on the host: Local has no in-repo build container either,
# and a developer using Local is not inside the wp-dev.ucsc Docker stack the
# "never run host Node" guardrail targets.
#
# Usage:
#   local.sh inspect   # non-destructive: lwp CLI, UCSC_LOCAL_SITE, Local reachability, plugin dir
#   local.sh build      # npm run build in the plugin dir (host)
#   local.sh launch     # lwp start + activate plugin
#   local.sh smoke       # health: site HTTP, plugin active, blocks registered
#   local.sh drive URL # headless Chrome: post-JS DOM + console errors (UCSC_SHOT=path for a screenshot); URL defaults to the resolved site URL
#   local.sh all        # inspect -> build -> launch -> smoke (default)
#   local.sh down       # lwp stop
#
# Plugin is autodetected from the current directory; override with
# UCSC_PLUGIN=<slug>. Override the lwp binary with LWP_BIN (default: `lwp` on
# PATH, else ~/.local/bin/lwp).

set -uo pipefail

usage() {
  sed -n '2,39p' "$0" | sed 's/^# \{0,1\}//'
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
SITE="${UCSC_LOCAL_SITE:-}"
LOG="${UCSC_RUN_LOG:-/tmp/ucsc-run-local-$(date +%Y%m%d-%H%M%S).log}"
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
      if [ -f "$d/docker-compose.yml" ]; then
        echo "$d"; return 0
      fi
      d=$(dirname "$d")
    done
  done
  return 1
}

ROOT="$(find_root)" || { echo "ERROR: could not locate repo root (set WP_DEV_ROOT=)"; exit 2; }
cd "$ROOT" || exit 2

# Resolve the lwp CLI: prefer LWP_BIN, then PATH, then the installer's default
# location (~/.local/bin/lwp is not always on PATH).
if [ -n "${LWP_BIN:-}" ]; then
  read -r -a LWP_CMD <<< "$LWP_BIN"
elif command -v lwp >/dev/null 2>&1; then
  LWP_CMD=(lwp)
elif [ -x "$HOME/.local/bin/lwp" ]; then
  LWP_CMD=("$HOME/.local/bin/lwp")
else
  LWP_CMD=()
fi

lwpcli() { "${LWP_CMD[@]}" "$@"; }
wpc() { lwpcli wp "$SITE" -- "$@"; }

pass() { printf '  [ OK ] %s\n' "$1"; }
fail() { printf '  [FAIL] %s\n' "$1"; FAILED=1; }

require_lwp() {
  if [ "${#LWP_CMD[@]}" -eq 0 ]; then
    fail "lwp CLI not found (install: curl -fsSL https://raw.githubusercontent.com/cartpauj/localwp-cli/main/scripts/install.sh | bash)"
    return 1
  fi
  return 0
}

require_site() {
  [ -n "$SITE" ] && return 0
  fail "UCSC_LOCAL_SITE not set — export UCSC_LOCAL_SITE=<name-or-id> (see 'lwp list')"
  return 1
}

# Resolves the site's public URL from `lwp status <site>`, which prints
# "<name>: <status>  (<url>)". UCSC_LOCAL_URL always wins so a format drift in
# lwp's output has a documented escape hatch rather than a silent breakage.
resolve_url() {
  if [ -n "${UCSC_LOCAL_URL:-}" ]; then
    echo "$UCSC_LOCAL_URL"; return 0
  fi
  [ -n "$SITE" ] || return 1
  require_lwp >/dev/null 2>&1 || return 1
  local out
  out=$(lwpcli status "$SITE" 2>>"$LOG") || return 1
  printf '%s\n' "$out" | grep -oE '\(https?://[^)]+\)' | tr -d '()' | head -n1
}

# --- phases -----------------------------------------------------------------
do_inspect() {
  echo "inspect (root: $ROOT)"
  if require_lwp; then
    pass "lwp CLI resolvable (${LWP_CMD[*]})"
    if lwpcli doctor >>"$LOG" 2>&1; then
      pass "lwp doctor: Local reachable"
    else
      fail "lwp doctor failed — is the Local app open? (see log)"
    fi
  fi
  require_site && pass "UCSC_LOCAL_SITE set ($SITE)"
  [ -d "$ROOT/public/wp-content/plugins/${PLUGIN}" ] && pass "plugin checked out" || fail "plugin dir missing"
  local url
  url="$(resolve_url)"
  if [ -n "$url" ]; then
    echo "  ...  target URL: $url"
  else
    echo "  ...  target URL: unresolved (set UCSC_LOCAL_URL=<url>, or fix UCSC_LOCAL_SITE / start Local)"
  fi
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

wait_site_cli() {
  local i
  for i in $(seq 1 30); do
    if wpc option get siteurl >>"$LOG" 2>&1; then
      return 0
    fi
    sleep 2
  done
  return 1
}

do_launch() {
  echo "launch"
  require_lwp || return
  require_site || return
  lwpcli start "$SITE" >>"$LOG" 2>&1 && pass "lwp start $SITE" || { fail "lwp start (see log)"; return; }
  if wait_site_cli; then
    pass "wp-cli reachable via lwp"
  else
    fail "wp-cli not reachable after 60s (see log)"
    return
  fi
  if wpc plugin activate "$PLUGIN" >>"$LOG" 2>&1; then
    pass "plugin activated"
  else
    fail "plugin activate (see log)"
  fi
}

do_smoke() {
  echo "smoke"
  require_lwp || return
  require_site || return
  local url
  url="$(resolve_url)"
  if [ -z "$url" ]; then
    fail "could not resolve site URL (set UCSC_LOCAL_URL=<url> to override)"
  else
    local code
    code=$(curl -sk -o /dev/null -w '%{http_code}' "$url" 2>>"$LOG" || true)
    case "$code" in
      200|301|302) pass "site HTTP $code ($url)" ;;
      *) fail "site HTTP ${code:-no-response} ($url)" ;;
    esac
  fi
  local status
  status=$(wpc plugin list --name="$PLUGIN" --field=status 2>>"$LOG" | tr -d '\r' || true)
  [ "$status" = "active" ] && pass "plugin status: active" || fail "plugin status: ${status:-unknown}"
  # Blocks registered — same reviewed PHP as the other drivers (helpers/list-blocks.php),
  # piped over stdin so no PHP is embedded in a shell string (ADR-095).
  local blocks nblocks
  blocks=$(wpc eval-file - < "$SCRIPT_DIR/../helpers/list-blocks.php" 2>>"$LOG" || true)
  nblocks=$(printf '%s\n' "$blocks" | grep -c . || true)
  if [ "$nblocks" -gt 0 ]; then
    pass "$nblocks ucsc* block(s) registered"
    printf '%s\n' "$blocks" | grep . | sed 's/^/  ...    /'
  else
    fail "no ucsc* blocks registered (see log — lwp's stdin handling for eval-file is unverified upstream, rerun with UCSC_RUN_LOG set to inspect)"
  fi
}

do_drive() {
  local url="${1:-}"
  [ -n "$url" ] || url="$(resolve_url)"
  echo "drive (${url:-unresolved})"
  if [ -z "$url" ]; then
    fail "no URL given and none resolvable (pass one explicitly or set UCSC_LOCAL_URL)"
    return
  fi
  drive_url "$url" "$LOG"
}

do_down() {
  echo "down"
  require_lwp || return
  require_site || return
  lwpcli stop "$SITE" >>"$LOG" 2>&1 && pass "lwp stop $SITE" || fail "lwp stop (see log)"
}

# --- dispatch ---------------------------------------------------------------
cmd="${1:-all}"
case "$cmd" in
  inspect) do_inspect ;;
  build)   do_build ;;
  launch)  do_launch ;;
  smoke)   do_smoke ;;
  drive)   do_drive "${2:-}" ;;
  down)    do_down ;;
  all)     do_inspect; do_build; do_launch; do_smoke ;;
  *) echo "usage: local.sh [inspect|build|launch|smoke|drive URL|all|down]"; exit 2 ;;
esac

echo "----"
[ "$FAILED" -eq 0 ] && echo "RESULT: PASS" || { echo "RESULT: FAIL  (log: $LOG)"; tail -n 20 "$LOG" 2>/dev/null; }
echo "log: $LOG"
exit "$FAILED"
