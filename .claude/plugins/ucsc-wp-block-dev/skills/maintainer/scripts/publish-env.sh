#!/bin/bash
# Shared, source-only environment loader for the documentation publishers.

publish_env_usage() {
  cat <<'EOF'
Usage: source publish-env.sh

Loads the project-root .env (or UCSC_WP_BLOCK_DEV_ENV_FILE) and provides
Google Docs destination URL validation for the maintainer publishing scripts.
EOF
}

load_publish_env() {
  project_root="$1"
  env_file="${UCSC_WP_BLOCK_DEV_ENV_FILE:-$project_root/.env}"

  if [ -f "$env_file" ]; then
    set -a
    # shellcheck disable=SC1090
    . "$env_file"
    set +a
  fi
}

require_google_doc_url() {
  variable_name="$1"
  label="$2"
  value="${!variable_name:-}"

  if [ -z "$value" ]; then
    echo "  [FAIL] $variable_name is not set for the $label destination." >&2
    echo "  Add it to the project-root .env (gitignored), for example:" >&2
    echo "  $variable_name=https://docs.google.com/document/d/<DOCUMENT_ID>/edit" >&2
    echo "  See README.md#environment-configuration-for-publishing." >&2
    return 2
  fi

  case "$value" in
    https://docs.google.com/document/d/*/edit|https://docs.google.com/document/d/*/edit\?*)
      ;;
    *)
      echo "  [FAIL] $variable_name must be a Google Docs edit URL for the $label destination." >&2
      echo "  Expected: https://docs.google.com/document/d/<DOCUMENT_ID>/edit" >&2
      return 2
      ;;
  esac
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  publish_env_usage
fi
