#!/bin/bash
set -e

usage() {
  cat <<'EOF'
Usage: validate_driver.sh

Runs the ucsc-gutenberg-blocks PHPUnit suite inside the running wp-dev.ucsc
container. Start Docker and the wp-dev.ucsc stack before running without --help.
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

CONTAINER=$(docker ps --filter "name=wp-dev.ucsc" --format '{{.Names}}' | head -n1)
if [ -z "$CONTAINER" ]; then
  echo "Container named 'wp-dev.ucsc' not found. Start Docker and run the wp-dev.ucsc container, then re-run this script."
  exit 2
fi

echo "Using container: $CONTAINER"
# Run phpunit as www-data in the container; plugin files are mounted at /var/www/html
docker exec -u www-data "$CONTAINER" bash -lc "cd /var/www/html/wp-content/plugins/ucsc-gutenberg-blocks && if [ -x ./vendor/bin/phpunit ]; then ./vendor/bin/phpunit --configuration phpunit.xml.dist || ./vendor/bin/phpunit; else if command -v phpunit >/dev/null 2>&1; then phpunit --configuration phpunit.xml.dist || phpunit; else echo 'phpunit not found in container. Install dev dependencies or run tests via composer install.'; exit 3; fi; fi"
