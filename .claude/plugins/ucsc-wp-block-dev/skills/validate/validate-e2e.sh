#!/bin/bash
set -e

usage() {
  cat <<'EOF'
Usage: validate-e2e.sh

Runs end-to-end tests (Playwright / e2e) for the plugin. Multi-environment aware:
- For wp-dev.ucsc the recommended driver invocation is shown.
- For other environments the script prompts for bringing up the target site.

This script intentionally prompts rather than attempting to start browsers or containers
in unknown environments.
EOF
}

case "${1:-}" in
  --help|-h)
    usage
    exit 0
    ;;
  "")
    ;;
  *)
    echo "Unknown argument: $1" >&2
    usage >&2
    exit 2
    ;;
esac

PLUGIN_SLUG="${PLUGIN_SLUG:-ucsc-blocks}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
detect_script="$script_dir/../run/lib/detect-environment.sh"
if [ -x "$detect_script" ]; then
  ENVIRONMENT="$($detect_script 2>/dev/null || echo unknown)"
else
  ENVIRONMENT=wp-dev-ucsc
fi

echo "Detected environment: $ENVIRONMENT"

case "$ENVIRONMENT" in
  wp-dev-ucsc)
    echo "Recommended: run the e2e runner inside the plugin's npm container:" 
    echo "  docker compose -f docker-compose.yml -f docker-compose-start.yml run --rm -w /var/www/html/wp-content/plugins/$PLUGIN_SLUG plugin_npm_start npm run test:e2e"
    echo
    # Not executing docker here to avoid starting browsers unexpectedly.
    exit 0
    ;;
  *)
    echo
    echo "Detected non-wp-dev.ucsc environment. Bring your site up (wp-env/local/wp-engine/BYO) and run the plugin's e2e test command in that environment."
    echo
    echo "Suggested local command:"
    echo "  cd path/to/wp/content/plugins/$PLUGIN_SLUG && npm ci && npm run test:e2e"
    echo
    exit 0
    ;;
esac
