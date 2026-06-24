#!/usr/bin/env bash
# implements: ADR-095-DEVELOP-SOURCE-BASE
# Resolve the source base for ucsc-wp-block-dev work (ADR-095).
#
# Gives skills a single, robust notion of "where things live" so they never
# hardcode absolute paths like /Users/.../wp-dev.ucsc/public/wp-content/plugins/...
# Self-locates via ${BASH_SOURCE[0]} (ADR-094) and walks up to the wp-dev.ucsc
# repo root by marker, so it works regardless of the caller's cwd.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# This script lives at <repo>/.claude/plugins/ucsc-wp-block-dev/skills/develop/scripts.
# The plugin root is four levels up from here unless the harness told us directly.
PLUGIN_ROOT_DEFAULT="$(cd -- "$SCRIPT_DIR/../../.." && pwd)"

usage() {
  cat <<'EOF'
Usage: source-base.sh <command> [arg]

Resolve the canonical roots for ucsc-wp-block-dev work (ADR-095). Use these
instead of hardcoding absolute paths in skill commands.

Commands:
  repo-root | project-root   Print the wp-dev.ucsc repository root.
  plugin-root                Print this Claude plugin's root (.claude/plugins/ucsc-wp-block-dev).
  wp-plugins                 Print <repo>/public/wp-content/plugins.
  plugin-dir <slug>          Print the WordPress plugin dir for <slug>
                             (e.g. ucsc-blocks, ucsc-gutenberg-blocks).
  env                        Print REPO_ROOT / PLUGIN_ROOT / WP_PLUGINS as KEY=VALUE.

Resolution (repo root): $WP_DEV_ROOT, then $CLAUDE_PROJECT_DIR, then
$CLAUDE_PLUGIN_ROOT, then $PWD, then this script's location — each walked upward
to the dir containing both `public/wp-content/plugins` and `docker-compose.yml`.
Plugin root prefers $CLAUDE_PLUGIN_ROOT.

Exit 0 on success; 2 when a root cannot be resolved or args are missing.
EOF
}

is_repo_root() {
  [ -d "$1/public/wp-content/plugins" ] && [ -f "$1/docker-compose.yml" ]
}

walk_up_to_repo() {
  local d="$1"
  [ -n "$d" ] || return 1
  d="$(cd -- "$d" 2>/dev/null && pwd)" || return 1
  while [ -n "$d" ] && [ "$d" != "/" ]; do
    if is_repo_root "$d"; then
      echo "$d"
      return 0
    fi
    d="$(dirname -- "$d")"
  done
  return 1
}

resolve_repo_root() {
  local cand
  for cand in "${WP_DEV_ROOT:-}" "${CLAUDE_PROJECT_DIR:-}" \
              "${CLAUDE_PLUGIN_ROOT:-}" "$PWD" "$SCRIPT_DIR"; do
    [ -n "$cand" ] || continue
    if walk_up_to_repo "$cand"; then
      return 0
    fi
  done
  return 1
}

resolve_plugin_root() {
  if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ] && [ -d "${CLAUDE_PLUGIN_ROOT}" ]; then
    echo "${CLAUDE_PLUGIN_ROOT}"
  else
    echo "$PLUGIN_ROOT_DEFAULT"
  fi
}

case "${1:-}" in
  --help|-h|help)
    usage
    exit 0
    ;;
  repo-root|project-root)
    resolve_repo_root || { echo "ERROR: could not locate wp-dev.ucsc repo root (set WP_DEV_ROOT=)" >&2; exit 2; }
    ;;
  plugin-root)
    resolve_plugin_root
    ;;
  wp-plugins)
    root="$(resolve_repo_root)" || { echo "ERROR: could not locate wp-dev.ucsc repo root (set WP_DEV_ROOT=)" >&2; exit 2; }
    echo "$root/public/wp-content/plugins"
    ;;
  plugin-dir)
    slug="${2:-}"
    [ -n "$slug" ] || { echo "plugin-dir requires a <slug> argument" >&2; usage >&2; exit 2; }
    root="$(resolve_repo_root)" || { echo "ERROR: could not locate wp-dev.ucsc repo root (set WP_DEV_ROOT=)" >&2; exit 2; }
    echo "$root/public/wp-content/plugins/$slug"
    ;;
  env)
    root="$(resolve_repo_root)" || { echo "ERROR: could not locate wp-dev.ucsc repo root (set WP_DEV_ROOT=)" >&2; exit 2; }
    printf 'REPO_ROOT=%s\n' "$root"
    printf 'PLUGIN_ROOT=%s\n' "$(resolve_plugin_root)"
    printf 'WP_PLUGINS=%s\n' "$root/public/wp-content/plugins"
    ;;
  "")
    usage >&2
    exit 2
    ;;
  *)
    echo "Unknown command: $1" >&2
    usage >&2
    exit 2
    ;;
esac
