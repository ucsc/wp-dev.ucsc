#!/bin/bash
# implements: ADR-105-RUN-RUNTIME-MODE-SUPPORT-MULTIPLE-WP-LOCAL-RUNTIMES
# detect-environment.sh — Determine which WordPress development environment is running.
#
# Output: Environment name string (STDOUT)
# Exit code: 0 if environment detected, 1 if unknown
#
# Supported environments:
#   - wp-dev-ucsc: home-rolled Docker Compose (docker-compose.yml + Dockerfile with LDAP)
#   - wp-env: WordPress.org wp-env (wp-env.json or package.json with wp-env)
#   - local: LocalWP / Local by Flywheel
#   - bare-wp-cli: Bare WordPress with wp-cli available
#   - running-generic: Any WordPress responding at localhost:PORT
#   - unknown: No environment detected

set -uo pipefail

detect_environment() {
  local cwd="${1:-.}"
  local detected=""

  # 1. wp-dev.ucsc: home-rolled Docker with custom PHP image (LDAP + Xdebug)
  # Markers: docker-compose.yml + Dockerfile + WordPress/LDAP references
  if [ -f "$cwd/docker-compose.yml" ] && [ -f "$cwd/Dockerfile" ]; then
    if grep -q "LDAP\|wordpress:6" "$cwd/Dockerfile" 2>/dev/null; then
      detected="wp-dev-ucsc"
    fi
  fi

  [ -n "$detected" ] && { echo "$detected"; return 0; }

  # 2. wp-env: WordPress.org standard (wp-env.json or package.json dependency)
  if [ -f "$cwd/wp-env.json" ]; then
    detected="wp-env"
  elif [ -f "$cwd/package.json" ]; then
    # Look for @wordpress/env or wp-env in package.json
    if grep -q '"@wordpress/env"\|"wp-env"' "$cwd/package.json" 2>/dev/null; then
      detected="wp-env"
    fi
  fi

  [ -n "$detected" ] && { echo "$detected"; return 0; }

  # 3. LocalWP / Local by Flywheel
  # Markers: Local app installed or ~/.local/share/Local sites directory
  if [ -d "$HOME/.local/share/Local/sites" ] 2>/dev/null; then
    detected="local"
  elif [ -x "/Applications/Local.app/Contents/MacOS/Local" ] 2>/dev/null; then
    # macOS: check for Local.app bundle
    detected="local"
  elif [ -x "$HOME/.local/share/LocalByFlywheel/Local" ] 2>/dev/null; then
    # Linux: check for Local installation
    detected="local"
  fi

  [ -n "$detected" ] && { echo "$detected"; return 0; }

  # 4. WP Engine (.wpe marker or WPE_* environment variables)
  if [ -f "$cwd/.wpe" ]; then
    detected="wpe"
  elif env | grep -q "^WPE_" 2>/dev/null; then
    detected="wpe"
  fi

  [ -n "$detected" ] && { echo "$detected"; return 0; }

  # 5. Bare wp-cli (WordPress installed locally, wp-cli available and working)
  if command -v wp &>/dev/null; then
    # Try to get WordPress version in current directory (succeeds if wp-config.php exists)
    if wp --path="$cwd" core version &>/dev/null 2>&1; then
      detected="bare-wp-cli"
    fi
  fi

  [ -n "$detected" ] && { echo "$detected"; return 0; }

  # 6. Running generic WordPress (HTTP probe on common ports)
  # Check: localhost:8000 (wp-env default), 3000 (Local/other), 8080, 80, 443
  # Probe for WordPress login form or wp-admin redirect
  local ports="8000 3000 8080 80 443"
  local port
  for port in $ports; do
    # Check for WordPress login page or wp-admin redirect
    local response
    response=$(curl -s --max-time 1 "http://localhost:$port/wp-admin/" 2>/dev/null || echo "")
    # Look for WordPress login form, wp-admin redirect, or WordPress text
    if echo "$response" | grep -q "wp-login\|wp-admin\|WordPress\|function wp_" 2>/dev/null; then
      detected="running-generic"
      break
    fi
  done

  [ -n "$detected" ] && { echo "$detected"; return 0; }

  # No environment detected
  echo "unknown"
  return 1
}

# Allow calling as a script or sourcing as a function
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
  case "${1:-}" in
    --help|-h)
      cat <<'EOF'
Usage: detect-environment.sh [dir]

Prints the detected WordPress development environment for dir (default: .):
wp-dev-ucsc, wp-env, local, bare-wp-cli, running-generic, or unknown.
Exits 0 when detected, 1 for unknown. May also be sourced to use the
detect_environment() function directly.
EOF
      exit 0
      ;;
  esac
  detect_environment "$@"
fi
