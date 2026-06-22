#!/bin/bash
set -euo pipefail

# Minimal plugin-local compare_blocks implementation (lightweight)
# Prefer using the upstream compare_blocks from _code/_WP_tools when available.
# Usage: compare_blocks_local.sh --dev <dev_url> --prod <prod_url> --selector <css_selector> [--keep]

usage() {
  sed -n '4,6p' "$0" | sed 's/^# \{0,1\}//'
}

case "${1:-}" in
  --help|-h)
    usage
    exit 0
    ;;
esac

DEV_URL=""
PROD_URL=""
SELECTOR=""
KEEP=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dev) DEV_URL="$2"; shift 2;;
    --prod) PROD_URL="$2"; shift 2;;
    --selector) SELECTOR="$2"; shift 2;;
    --keep) KEEP=1; shift;;
    *) echo "Unknown arg: $1"; exit 2;;
  esac
done

if [ -z "$DEV_URL" ] || [ -z "$PROD_URL" ]; then
  echo "Usage: $0 --dev <dev_url> --prod <prod_url> --selector '<css selector>'"
  exit 2
fi

TMPDIR=$(mktemp -d)
DEVHTML="$TMPDIR/dev.html"
PRODHTML="$TMPDIR/prod.html"

curl -sSfL "$DEV_URL" -o "$DEVHTML" || { echo "Failed to fetch dev url"; exit 3; }
curl -sSfL "$PROD_URL" -o "$PRODHTML" || { echo "Failed to fetch prod url"; exit 3; }

# Simple selector extraction using pup if available, else fallback to sed extracting body
if command -v pup >/dev/null 2>&1; then
  pup "$SELECTOR" < "$DEVHTML" > "$TMPDIR/dev_sel.html"
  pup "$SELECTOR" < "$PRODHTML" > "$TMPDIR/prod_sel.html"
else
  # fallback: crude grep between selector start/end (best-effort)
  sed -n '1,4000p' "$DEVHTML" > "$TMPDIR/dev_sel.html"
  sed -n '1,4000p' "$PRODHTML" > "$TMPDIR/prod_sel.html"
fi

# Normalize some ephemeral attributes (nonces, timestamps, ids)
for f in dev_sel prod_sel; do
  sed -E -e 's/id="[^"]+"/id="ID_REPLACED"/g' -e 's/data-[a-zA-Z0-9_-]+="[^"]+"/data-ATTR_REPLACED=""/g' -e 's/nonce-[a-zA-Z0-9_-]+/NONCE_REPLACED/g' "$TMPDIR/${f}.html" > "$TMPDIR/${f}.norm.html"
done

diff -u "$TMPDIR/dev_sel.norm.html" "$TMPDIR/prod_sel.norm.html" || true

if [ "$KEEP" -eq 1 ]; then
  echo "Kept temp files in $TMPDIR"
else
  rm -rf "$TMPDIR"
fi
