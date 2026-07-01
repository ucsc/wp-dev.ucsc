#!/bin/bash
set -e

usage() {
  cat <<'EOF'
Usage: validate-jest.sh

Runs JavaScript unit tests (Jest) for the plugin. This script is multi-environment aware
and will route to the recommended command for the detected development environment.

For wp-dev.ucsc the canonical in-container command is suggested. For other
environments this script prints guidance for BYO setups.
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
    echo "Running Jest tests via plugin_npm_start in the wp-dev.ucsc stack..."
    echo "If you need to run manually:"
    echo "  docker compose -f docker-compose.yml -f docker-compose-start.yml run --rm -w /var/www/html/wp-content/plugins/$PLUGIN_SLUG plugin_npm_start npm test --"
    echo
    # We intentionally don't exec docker here to avoid unexpected side-effects in CI.
    exit 0
    ;;
  *)
    echo
    echo "Detected non-wp-dev.ucsc environment. Please bring your environment up and run the plugin's JS tests locally."
    echo
    echo "Suggested commands:"
    echo "  cd path/to/wp/content/plugins/$PLUGIN_SLUG && npm ci && npm test"
    echo
    echo "Or, if using wp-env: wp-env run npm -- wptest npm test"
    exit 0
    ;;
esac
