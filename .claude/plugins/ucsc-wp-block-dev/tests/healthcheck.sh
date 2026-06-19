#!/bin/bash
set -euo pipefail
PLUGIN_DIR="/Users/henryh/_code/_campuspress/wp-dev.ucsc/public/wp-content/plugins/ucsc-gutenberg-blocks"
MANUAL_TEST="$PLUGIN_DIR/tests/run_manual_test.php"
PHPUNIT_TEST_DIR="$PLUGIN_DIR/tests/phpunit"

echo "Healthcheck: ucsc-wp-block-dev plugin (lightweight)"

# Basic existence checks
if [ ! -d "$PLUGIN_DIR" ]; then
  echo "ERROR: Plugin directory not found: $PLUGIN_DIR"
  exit 2
fi

echo "Found plugin at $PLUGIN_DIR"

for f in templates/CampusDirectoryTemplate.php tests/run_manual_test.php tests/phpunit/CampusDirectoryTemplateTest.php; do
  if [ -f "$PLUGIN_DIR/$f" ]; then
    echo "OK: $f exists"
  else
    echo "WARN: $f missing"
  fi
done

# Quick grep checks for risky patterns
echo "Scanning for risky patterns (unescaped echo, permissive REST permissions)"
GREP_CMD="grep -nR --line-number --color=never"
$GREP_CMD "permission_callback.*__return_true" "$PLUGIN_DIR" || echo "(no permissive permission_callback found)"
# Strict enforcement: fail if raw echo patterns are found in templates
if $GREP_CMD "echo .*\\$" "$PLUGIN_DIR/templates" > /dev/null 2>&1; then
  echo "ERROR: raw echo patterns found in templates"
  $GREP_CMD "echo .*\\$" "$PLUGIN_DIR/templates"
  exit 3
else
  echo "(no obvious raw-echo-with-var found in templates)"
fi

# Try to run manual PHP test inside Docker container if available
CONTAINER=$(docker ps --format '{{.Names}}\t{{.Image}}\t{{.Status}}' 2>/dev/null | awk -F"\t" '/wp/ {print $1; exit}') || true

if [ -n "$CONTAINER" ]; then
  echo "Found docker container: $CONTAINER — attempting to run manual PHP test inside it"
  if docker exec -u www-data "$CONTAINER" test -f "/var/www/html/wp-content/plugins/ucsc-gutenberg-blocks/tests/run_manual_test.php"; then
    docker exec -u www-data "$CONTAINER" php /var/www/html/wp-content/plugins/ucsc-gutenberg-blocks/tests/run_manual_test.php || rc=$?
    if [ "${rc:-0}" -eq 0 ]; then
      echo "Manual PHP test passed inside container"
    else
      echo "Manual PHP test failed inside container (exit $rc)"
    fi
  else
    echo "Manual test not found inside container at expected path"
  fi
else
  echo "No docker container detected; attempting local php execution of manual test"
  if command -v php >/dev/null 2>&1; then
    if [ -f "$MANUAL_TEST" ]; then
      php "$MANUAL_TEST" || rc=$?
      if [ "${rc:-0}" -eq 0 ]; then
        echo "Manual PHP test passed locally"
      else
        echo "Manual PHP test failed locally (exit $rc)"
      fi
    else
      echo "Manual test file missing: $MANUAL_TEST"
    fi
  else
    echo "php not found locally; unable to run manual PHP test"
  fi
fi

# Suggest next steps
echo "Healthcheck finished. Suggestions: add phpunit/bootstrap and CI workflow if not present."
