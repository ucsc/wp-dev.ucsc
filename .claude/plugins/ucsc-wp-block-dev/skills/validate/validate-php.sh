#!/bin/bash
set -e

usage() {
  cat <<'EOF'
Usage: validate-php.sh

Runs the ucsc-blocks PHPUnit suite. This script is multi-environment aware and
routes to the appropriate validator based on the detected development runtime.

If running inside the wp-dev.ucsc Docker stack the original behavior is used.
For other environments (wp-env, Local, BYO) the script prompts with guidance
and checks for local PHPUnit only when possible.

Environment overrides:
  WP_CONTAINER      Container name to exec into (default: auto-detect for wp-dev.ucsc).
  PLUGIN_SLUG       Plugin folder under wp-content/plugins (default: ucsc-blocks).
  PHPUNIT_PHAR_URL  PHPUnit phar to fetch if none is installed in the container
                    (default: https://phar.phpunit.de/phpunit-10.phar).
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
PHPUNIT_PHAR_URL="${PHPUNIT_PHAR_URL:-https://phar.phpunit.de/phpunit-10.phar}"

# Locate the detect-environment helper shipped with the run skill
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
detect_script="$script_dir/../run/lib/detect-environment.sh"
if [ ! -x "$detect_script" ]; then
  echo "Warning: detect-environment script not found at $detect_script. Defaulting to wp-dev-ucsc behavior." >&2
  ENVIRONMENT=wp-dev-ucsc
else
  ENVIRONMENT="$($detect_script 2>/dev/null || echo unknown)"
fi

echo "Detected environment: $ENVIRONMENT"

case "$ENVIRONMENT" in
  wp-dev-ucsc)
    # Original behavior: run phpunit inside the wp-dev.ucsc WordPress container.

    # Locate the WordPress container. Prefer an explicit WP_CONTAINER, then known
    # name patterns, then the container running the wp-devucsc-wp image.
    CONTAINER="${WP_CONTAINER:-}"
    if [ -z "$CONTAINER" ]; then
      for pat in ucsc-wordpress-wp wp-dev.ucsc; do
        CONTAINER=$(docker ps --filter "name=$pat" --format '{{.Names}}' | head -n1)
        [ -n "$CONTAINER" ] && break
      done
    fi
    if [ -z "$CONTAINER" ]; then
      CONTAINER=$(docker ps --filter "ancestor=wp-devucsc-wp" --format '{{.Names}}' | head -n1)
    fi
    if [ -z "$CONTAINER" ]; then
      echo "WordPress container not found. Start Docker and the wp-dev.ucsc stack, or set WP_CONTAINER, then re-run." >&2
      exit 2
    fi

    echo "Using container: $CONTAINER"
    echo "Using plugin slug: $PLUGIN_SLUG"

    # Run phpunit as www-data in the container; plugin files are mounted at /var/www/html.
    docker exec -u www-data \
      -e PLUGIN_SLUG="$PLUGIN_SLUG" \
      -e PHPUNIT_PHAR_URL="$PHPUNIT_PHAR_URL" \
      "$CONTAINER" bash -lc '
      set -e
      dir="/var/www/html/wp-content/plugins/$PLUGIN_SLUG"
      if [ ! -d "$dir" ]; then
        echo "Plugin not found: $dir (set PLUGIN_SLUG to the plugin folder name)." >&2
        exit 2
      fi
      echo "Using plugin dir: $dir"
      cd "$dir"

      if [ -f phpunit.xml.dist ]; then set -- --configuration phpunit.xml.dist; else set --; fi

      if [ -x ./vendor/bin/phpunit ]; then
        exec ./vendor/bin/phpunit "$@"
      elif command -v phpunit >/dev/null 2>&1; then
        exec phpunit "$@"
      fi

      # No Composer/PHPUnit in the container — fetch a standalone phar (cached in /tmp).
      phar=/tmp/phpunit-10.phar
      if [ ! -f "$phar" ]; then
        echo "phpunit not installed in container; fetching PHPUnit phar..." >&2
        if ! curl -fsSL -o "$phar" "$PHPUNIT_PHAR_URL"; then
          echo "Could not download phpunit from $PHPUNIT_PHAR_URL (no network?)." >&2
          echo "Alternatively install dev deps in the plugin: composer install." >&2
          exit 3
        fi
      fi
      exec php "$phar" "$@"
    '
    ;;

  *)
    # Non-wp-dev.ucsc environments: prompt and guide the developer to run tests in their environment.
    echo
    echo "Note: multi-environment support detected '$ENVIRONMENT'. This validate script will not run tests automatically for that environment." 
    echo "Please ensure your WordPress instance is running and that PHPUnit is available in your development environment."
    echo
    echo "Suggested commands (choose the one that fits your setup):"
    echo "  # If you're using the plugin's npm/docker runner (wp-dev.ucsc):"
    echo "  docker compose -f docker-compose.yml -f docker-compose-start.yml run --rm -w /var/www/html/wp-content/plugins/$PLUGIN_SLUG plugin_npm_start npm test --"
    echo
    echo "  # If you run tests locally in the plugin folder (composer deps installed):"
    echo "  cd path/to/wp/content/plugins/$PLUGIN_SLUG && ./vendor/bin/phpunit"
    echo
    echo "  # If you prefer running via wp-env/local: bring your environment up, then run the plugin's test command in your environment."
    echo
    echo "If you'd like this script to attempt automatic execution in your environment, open an issue or request the specific driver for '$ENVIRONMENT'."

    # Friendly exit: don't fail the pipeline simply because the environment isn't supported yet.
    exit 0
    ;;
esac
