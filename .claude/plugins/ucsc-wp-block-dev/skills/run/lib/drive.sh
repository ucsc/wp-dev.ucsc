#!/bin/bash
# implements: ADR-105-RUN-RUNTIME-MODE-SUPPORT-MULTIPLE-WP-LOCAL-RUNTIMES
# drive.sh — shared headless-Chrome driver: post-JS DOM dump + console capture.
#
# Environment-agnostic (only needs a reachable URL); every environment driver
# (wp-dev-ucsc, wp-env, generic-byo, local once implemented) sources this
# instead of re-implementing Chrome invocation. Callers must define `pass()`,
# `fail()`, and a `FAILED` variable before sourcing (same contract as the
# drivers' own pass/fail helpers) since drive_url() reports through them.
#
# Usage (after sourcing):
#   drive_url <url> <log-base-path> [host-resolver-rule]
# Writes <log-base-path>.dom and <log-base-path>.console; screenshot is opt-in
# via UCSC_SHOT=<path> (avoids image tokens by default).

find_chrome() {
  local c
  for c in \
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
    "/Applications/Chromium.app/Contents/MacOS/Chromium" \
    "$(command -v chromium 2>/dev/null)" \
    "$(command -v chromium-browser 2>/dev/null)" \
    "$(command -v google-chrome 2>/dev/null)"; do
    [ -n "$c" ] && [ -x "$c" ] && { echo "$c"; return 0; }
  done
  return 1
}

drive_url() {
  local url="$1"
  local log="$2"
  local resolve_rule="${3:-}"

  local chrome
  chrome="$(find_chrome)" || { fail "no Chrome/Chromium found (install or set PATH)"; return 1; }

  # ignore-certificate-errors covers self-signed dev certs (harmless over
  # plain HTTP); virtual-time-budget lets DOMContentLoaded JS run;
  # enable-logging=stderr surfaces page console messages/uncaught JS errors as
  # grep-able `[...:CONSOLE(n)]` / `[...:ERROR:CONSOLE(n)]` lines (ADR-097).
  local common=( --headless=new --disable-gpu --no-sandbox
    --ignore-certificate-errors
    --enable-logging=stderr --v=1
    --virtual-time-budget=6000 )
  [ -n "$resolve_rule" ] && common+=( --host-resolver-rules="$resolve_rule" )

  local console="${log}.console"
  if "$chrome" "${common[@]}" --dump-dom "$url" >"${log}.dom" 2>"$console"; then
    local nblocks
    # Match both namespaces' wrapper classes: wp-block-ucsc-<name> (ucsc/*) and
    # wp-block-ucscblocks-<name> (ucscblocks/*, ucsc-gutenberg-blocks).
    nblocks=$(grep -oE 'wp-block-ucsc[a-z-]+' "${log}.dom" 2>/dev/null | sort -u | grep -c . || true)
    [ "$nblocks" -gt 0 ] && pass "$nblocks ucsc block class(es) in rendered DOM" \
                         || fail "no ucsc block classes in rendered DOM"
    echo "  ...  DOM dump: ${log}.dom"
  else
    fail "dump-dom failed (see log)"
  fi

  local nerr nmsg
  nerr=$(grep -c 'ERROR:CONSOLE' "$console" 2>/dev/null || true)
  nmsg=$(grep -c ':CONSOLE(' "$console" 2>/dev/null || true)
  if [ "${nerr:-0}" -gt 0 ]; then
    fail "$nerr console error(s)/JS exception(s) — see ${console}"
    grep 'ERROR:CONSOLE' "$console" 2>/dev/null | sed 's/^/  ...  /' | head -5
  else
    pass "no console errors (${nmsg:-0} console msg(s)); log: ${console}"
  fi

  if [ -n "${UCSC_SHOT:-}" ]; then
    if "$chrome" "${common[@]}" --window-size=1100,900 --screenshot="$UCSC_SHOT" "$url" >>"${log}" 2>&1 \
       && [ -s "$UCSC_SHOT" ]; then
      pass "screenshot written ($UCSC_SHOT)"
    else
      fail "screenshot failed (see log)"
    fi
  else
    echo "  ...  screenshot skipped (set UCSC_SHOT=<path> for a visual capture)"
  fi
}

# This file is a library, meant to be sourced by driver scripts — but support
# standalone --help so it's discoverable the same way every other skill script
# is (matches lib/detect-environment.sh's dual sourced/standalone pattern).
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
  case "${1:-}" in
    --help|-h)
      cat <<'EOF'
Usage: drive.sh (library — source it, don't run it directly)

Shared headless-Chrome driver used by every environment driver
(wp-dev-ucsc.sh, wp-env.sh, generic-byo.sh). Source it, define pass()/fail()/
FAILED, then call:
  drive_url <url> <log-base-path> [host-resolver-rule]
EOF
      exit 0
      ;;
    *)
      echo "drive.sh is a library — source it from a driver script instead of running it. See --help." >&2
      exit 2
      ;;
  esac
fi
