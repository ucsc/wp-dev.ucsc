#!/bin/bash
# stack-check.sh — lightweight, once-per-session sanity check that the codebase
# under <path> matches the stack this plugin operates on: WordPress / Gutenberg
# (ADR-096).
#
# Why: `ucsc-wp-block-dev` was forked from the Laravel+Vue plugin
# `ucsc-laravel-vue-dev` and shares the same skill names (hub, develop, review,
# run, validate, verify). The wrong plugin can load silently — a WordPress
# session against a Laravel repo, or vice versa — and then apply stack-specific
# build/test/edit workflows to the wrong code. This catches that early.
#
# Deterministic and offline: inspects only a handful of cheap signals near the
# target, never the network. Walks up from <path> to the nearest repo root (a
# dir with .git / composer.json / package.json / docker-compose.yml) and reads
# signals from both the target and that root.
#
# Exit codes (ADR-096 — warn, do not hard-block on ambiguity):
#   0  WordPress detected (match), OR ambiguous/undetectable (prints a warning)
#   2  bad usage / unresolvable path
#   3  clear mismatch — strong Laravel/Vue signals and no WordPress signals
set -uo pipefail

EXPECTED_PLUGIN="ucsc-wp-block-dev"
SIBLING_PLUGIN="ucsc-laravel-vue-dev"

usage() {
  cat <<'EOF'
Usage: stack-check.sh [<path>]

Verify that the codebase at <path> (default: current directory) is a WordPress /
Gutenberg project, the stack the ucsc-wp-block-dev plugin operates on (ADR-096).

Prints the detected signals and a verdict. Exit 0 on match or when the stack is
ambiguous/undetectable (a warning is printed, never a hard block). Exit 3 only on
a clear mismatch (Laravel/Vue signals with no WordPress signals), which means the
wrong plugin is likely active — switch to ucsc-laravel-vue-dev.
EOF
}

case "${1:-}" in --help|-h) usage; exit 0 ;; esac

target="${1:-.}"
[ -d "$target" ] || target="$(dirname "$target")"
target="$(cd "$target" 2>/dev/null && pwd)" || {
  echo "stack-check: cannot resolve path '${1:-.}'" >&2
  exit 2
}

# Walk up to the nearest repo root.
root="$target"
while [ "$root" != "/" ]; do
  if [ -d "$root/.git" ] || [ -f "$root/composer.json" ] || \
     [ -f "$root/package.json" ] || [ -f "$root/docker-compose.yml" ]; then
    break
  fi
  root="$(dirname "$root")"
done

wp=0
laravel=0
wp_sig=""
laravel_sig=""
add_wp()      { wp=$((wp + 1));           wp_sig="${wp_sig:+$wp_sig; }$1"; }
add_laravel() { laravel=$((laravel + 1)); laravel_sig="${laravel_sig:+$laravel_sig; }$1"; }

# Echo the path of the nearest <filename> walking target -> root.
nearest() {
  local d="$target"
  while :; do
    [ -f "$d/$1" ] && { echo "$d/$1"; return 0; }
    [ "$d" = "$root" ] && break
    [ "$d" = "/" ] && break
    d="$(dirname "$d")"
  done
  return 1
}

# --- WordPress / Gutenberg signals ---
case "$target" in *wp-content/plugins*) add_wp "wp-content/plugins path" ;; esac

if pkg="$(nearest package.json)"; then
  grep -Eq '"@wordpress/|wp-scripts' "$pkg" && add_wp "@wordpress/* or wp-scripts in $(basename "$(dirname "$pkg")")/package.json"
fi

# A block.json near the target (handles the per-block-directory repo layout).
if find "$target" -maxdepth 4 -name block.json -not -path '*/node_modules/*' -print 2>/dev/null | grep -q .; then
  add_wp "block.json present"
fi

# A WordPress plugin PHP header at the target (handles the single-file layout).
if grep -lEr --include='*.php' "Plugin Name:" "$target" 2>/dev/null | head -1 | grep -q .; then
  add_wp "WordPress plugin header (Plugin Name:)"
fi

if compose="$(nearest docker-compose.yml)"; then
  grep -Eqi 'wordpress|wp-?cli' "$compose" && add_wp "wordpress/wpcli service in docker-compose.yml"
fi

# --- Laravel / Vue signals (the sibling plugin's stack) ---
[ -f "$root/artisan" ] && add_laravel "artisan present at repo root"
if comp="$(nearest composer.json)"; then
  grep -q '"laravel/framework"' "$comp" && add_laravel "laravel/framework in composer.json"
fi
[ -d "$root/resources/js" ] && add_laravel "resources/js (Vue) directory present"

echo "stack-check: target  = $target"
echo "stack-check: repo     = $root"
echo "stack-check: WordPress signals (${wp}): ${wp_sig:-none}"
echo "stack-check: Laravel signals   (${laravel}): ${laravel_sig:-none}"

if [ "$wp" -gt 0 ] && [ "$laravel" -eq 0 ]; then
  echo "stack-check: OK — WordPress/Gutenberg codebase matches the active $EXPECTED_PLUGIN plugin."
  exit 0
fi

if [ "$laravel" -gt 0 ] && [ "$wp" -eq 0 ]; then
  echo "stack-check: MISMATCH — Laravel/Vue codebase, but the active plugin is $EXPECTED_PLUGIN (WordPress)." >&2
  echo "stack-check: switch to the $SIBLING_PLUGIN plugin before operating on this repo (ADR-096)." >&2
  exit 3
fi

if [ "$wp" -gt 0 ] && [ "$laravel" -gt 0 ]; then
  echo "stack-check: WARN — both WordPress and Laravel signals found; confirm the intended target before acting." >&2
  exit 0
fi

echo "stack-check: WARN — stack undetectable from cheap signals; confirm this is a WordPress/Gutenberg repo before acting." >&2
exit 0
