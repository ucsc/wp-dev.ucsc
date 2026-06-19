#!/bin/bash
set -euo pipefail
# compare_blocks wrapper: prefer plugin-local script, fallback to user _code/_WP_tools path,
# and otherwise print actionable manual instructions.
PLUGIN_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
LOCAL="$PLUGIN_DIR/skills/verify/scripts/compare_blocks_local.sh"
USER="$HOME/_code/_WP_tools/compare_blocks.sh"

if [ -x "$LOCAL" ]; then
  exec "$LOCAL" "$@"
elif [ -x "$USER" ]; then
  exec "$USER" "$@"
else
  echo "compare_blocks helper not found. Expected either:" >&2
  echo "  $LOCAL (plugin-local) or" >&2
  echo "  $USER (user tools repo)" >&2
  echo "" >&2
  echo "Manual fallback: fetch both dev and prod pages that contain the same block, extract the block container element, normalize ephemeral differences (nonces, timestamps), and run a text diff. Example commands:" >&2
  echo "  curl -ks 'https://dev.example/page' | sed -n '/<div class=\"ucsc-block\">/,/<\/div>/p' > /tmp/dev.html" >&2
  echo "  curl -ks 'https://prod.example/page' | sed -n '/<div class=\"ucsc-block\">/,/<\/div>/p' > /tmp/prod.html" >&2
  echo "  diff -u /tmp/dev.html /tmp/prod.html" >&2
  echo "" >&2
  echo "If you'd like, copy or symlink your ~/ _code/_WP_tools/compare_blocks.sh into the plugin at: $LOCAL" >&2
  exit 2
fi
