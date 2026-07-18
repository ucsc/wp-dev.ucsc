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

# Phase-first form (driver.sh all|inspect|build|launch|smoke|drive|down): a
# phase word in $1 means the environment was omitted — auto-detect and keep
# the phase in the arguments.
PHASE_FIRST=0
case "$ENVIRONMENT" in
  inspect|build|launch|smoke|drive|down|all)
    ENVIRONMENT="auto"
    PHASE_FIRST=1
    ;;
esac

if [ "$ENVIRONMENT" = "auto" ]; then
  SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  
  # Try to detect the environment
  DETECTED=$(bash "$SCRIPT_DIR/lib/detect-environment.sh" "$PWD" 2>/dev/null || echo "unknown")
  ENVIRONMENT="$DETECTED"
  
  if [ "$ENVIRONMENT" = "unknown" ]; then
    # Default environment when detection is inconclusive.
    ENVIRONMENT="wp-dev-ucsc"
    echo "NOTE: could not detect environment — defaulting to wp-dev-ucsc"
  fi

  # Remove 'auto' from arguments (phase-first form passed no environment)
  if [ "$PHASE_FIRST" -eq 0 ]; then
    shift || true
  fi
else
  # Remove explicit environment from arguments
  shift || true
fi

# The ucsc-gutenberg-blocks family (campus-directory, course-catalog,
# class-schedule) depends on the custom wp-dev.ucsc image (PHP LDAP extension,
# PeopleSoft/VPN reachability) and must not run under other environments.
if [ "${UCSC_PLUGIN:-}" = "ucsc-gutenberg-blocks" ] && [ "$ENVIRONMENT" != "wp-dev-ucsc" ]; then
  echo "ERROR: ucsc-gutenberg-blocks requires the wp-dev-ucsc environment (got: $ENVIRONMENT)" >&2
  echo "Its blocks (campus-directory, course-catalog, class-schedule) need the custom Docker image." >&2
  exit 2
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
