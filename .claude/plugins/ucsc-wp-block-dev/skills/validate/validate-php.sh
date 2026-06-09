#!/bin/bash
set -e

usage() {
  cat <<'EOF'
Usage: validate-php.sh

Runs the ucsc-blocks PHPUnit suite inside the running wp-dev.ucsc WordPress
container. Start Docker and the wp-dev.ucsc stack before running without --help.

Environment overrides:
  WP_CONTAINER      Container name to exec into (default: auto-detect).
  PLUGIN_SLUG       Plugin folder under wp-content/plugins (default: ucsc-blocks).
  PHPUNIT_PHAR_URL  PHPUnit phar to fetch if none is installed in the container
                    (default: https://phar.phpunit.de/phpunit-10.phar).

The plugin's tests/bootstrap.php runs in standalone mode (it stubs WordPress and
loads the block code directly), so the container only needs PHP + a PHPUnit 10
binary — no WordPress test library is required.
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
