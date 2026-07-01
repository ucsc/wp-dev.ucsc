#!/bin/bash
# implements: ADR-105-RUN-RUNTIME-MODE-SUPPORT-MULTIPLE-WP-LOCAL-RUNTIMES
# driver.sh — Multi-environment router for WordPress block development.
#
# Detects the WordPress development environment and routes to the appropriate driver.
#
# Usage:
#   driver.sh auto [phase] [ARGS]        # auto-detect environment
#   driver.sh wp-dev-ucsc [phase] [ARGS] # explicit environment
#   driver.sh wp-env [phase] [ARGS]
#   driver.sh local [phase] [ARGS]
#   driver.sh byo drive <URL>            # bring your own WordPress
#   driver.sh help
#
# Phases: inspect, build, launch, smoke, drive <URL>, down, all
#
# Examples:
#   bash driver.sh auto all              # auto-detect, run full lifecycle
#   bash driver.sh wp-dev-ucsc all       # explicit wp-dev-ucsc
#   bash driver.sh byo drive https://mysite.test/

set -uo pipefail

usage() {
  cat <<EOF
usage: $(basename "$0") [ENVIRONMENT] [PHASE] [ARGS...]

Environments:
  auto              Auto-detect environment (default)
  wp-dev-ucsc       Home-rolled Docker (wp-dev.ucsc/)
  wp-env            WordPress.org wp-env
  local             LocalWP / Local by Flywheel
  byo               Bring Your Own (WordPress already running)

Phases:
  inspect           Check environment state
  build             Build plugin
  launch            Start WordPress
  smoke             Health checks
  drive <URL>       Open browser to URL
  down              Stop WordPress
  all               inspect → build → launch → smoke (wp-dev-ucsc only)

Examples:
  bash driver.sh auto all
  bash driver.sh wp-dev-ucsc all
  bash driver.sh wp-env build
  bash driver.sh byo drive https://mysite.test/

For help:
  bash driver.sh help
EOF
}

# --- Main Script ---

case "${1:-}" in
  --help|-h|help)
    usage
    exit 0
    ;;
esac

# Resolve environment: explicit or auto-detect
ENVIRONMENT="${1:-auto}"
if [ "$ENVIRONMENT" = "auto" ]; then
  SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  
  # Try to detect the environment
  DETECTED=$(bash "$SCRIPT_DIR/lib/detect-environment.sh" "$PWD" 2>/dev/null || echo "unknown")
  ENVIRONMENT="$DETECTED"
  
  if [ "$ENVIRONMENT" = "unknown" ]; then
    echo "ERROR: Could not detect WordPress development environment"
    echo ""
    echo "Supported environments:"
    echo "  - wp-dev-ucsc: home-rolled Docker (docker-compose.yml + Dockerfile)"
    echo "  - wp-env: WordPress.org wp-env (wp-env.json)"
    echo "  - local: LocalWP / Local by Flywheel"
    echo "  - byo: Bring Your Own (WordPress already running)"
    echo ""
    echo "To specify environment explicitly:"
    echo "  bash driver.sh wp-dev-ucsc all"
    echo "  bash driver.sh byo drive http://localhost:8000/"
    echo ""
    echo "For more help:"
    echo "  bash driver.sh help"
    exit 1
  fi
  
  # Remove 'auto' from arguments
  shift || true
else
  # Remove explicit environment from arguments
  shift || true
fi

# Locate the driver
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DRIVER_PATH="$SCRIPT_DIR/drivers/${ENVIRONMENT}.sh"

if [ ! -f "$DRIVER_PATH" ]; then
  echo "ERROR: Unsupported or unimplemented environment: $ENVIRONMENT"
  echo "Supported: wp-dev-ucsc, wp-env, local, byo"
  echo ""
  echo "For available environments:"
  echo "  bash driver.sh help"
  exit 2
fi

# Execute the environment-specific driver
echo "→ Environment: $ENVIRONMENT"
bash "$DRIVER_PATH" "$@"
