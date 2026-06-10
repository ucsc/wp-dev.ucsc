#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: .agents/codex.sh [--install]

Create or refresh the local Codex adapter for the ucsc-wp-block-dev plugin.

Options:
  --install   Also register the local marketplace and install the plugin with Codex.
  -h, --help  Show this help text.

.agents contains Codex-specific adapter source plus symlinks to .claude skills.
Shared plugin source remains under .claude/plugins/ucsc-wp-block-dev (ADR-017).
EOF
}

INSTALL=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --install)
      INSTALL=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
AGENTS_DIR="${PROJECT_DIR}/.agents"
PLUGIN_NAME="ucsc-wp-block-dev"
SOURCE_PLUGIN_DIR="${PROJECT_DIR}/.claude/plugins/${PLUGIN_NAME}"
CODEX_PLUGIN_DIR="${AGENTS_DIR}/plugins/${PLUGIN_NAME}"
CLAUDE_MANIFEST="${SOURCE_PLUGIN_DIR}/.claude-plugin/plugin.json"
CODEX_MANIFEST="${CODEX_PLUGIN_DIR}/.codex-plugin/plugin.json"

require_system_python() {
  if ! command -v python3 >/dev/null 2>&1; then
    echo "[ERROR] system python3 command not found" >&2
    exit 1
  fi
}

echo "=== Codex Setup for ${PLUGIN_NAME} ==="
echo "Project repo: ${PROJECT_DIR}"

require_system_python
python3 -m json.tool "${AGENTS_DIR}/plugins/marketplace.json" >/dev/null
python3 -m json.tool "${CLAUDE_MANIFEST}" >/dev/null
python3 -m json.tool "${CODEX_MANIFEST}" >/dev/null

CLAUDE_NAME="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["name"])' "${CLAUDE_MANIFEST}")"
CODEX_NAME="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["name"])' "${CODEX_MANIFEST}")"
CLAUDE_VERSION="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' "${CLAUDE_MANIFEST}")"
CODEX_VERSION="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"].split("+", 1)[0])' "${CODEX_MANIFEST}")"

if [ "${CLAUDE_NAME}" != "${PLUGIN_NAME}" ] || [ "${CODEX_NAME}" != "${PLUGIN_NAME}" ]; then
  echo "[ERROR] Claude and Codex plugin names must both be ${PLUGIN_NAME}" >&2
  exit 1
fi

if [ "${CLAUDE_VERSION}" != "${CODEX_VERSION}" ]; then
  echo "[ERROR] Claude version ${CLAUDE_VERSION} does not match Codex base version ${CODEX_VERSION}" >&2
  exit 1
fi

# ADR-017: use symlinks instead of rsync copies
if [ -d "${CODEX_PLUGIN_DIR}/skills" ] && [ ! -L "${CODEX_PLUGIN_DIR}/skills" ]; then
  rm -rf "${CODEX_PLUGIN_DIR}/skills"
fi
if [ ! -L "${CODEX_PLUGIN_DIR}/skills" ]; then
  ln -s "../../../.claude/plugins/${PLUGIN_NAME}/skills" "${CODEX_PLUGIN_DIR}/skills"
fi
echo "[OK] Symlinked .agents/plugins/${PLUGIN_NAME}/skills -> .claude/plugins/${PLUGIN_NAME}/skills"

if [ "${INSTALL}" -eq 1 ]; then
  if ! command -v codex >/dev/null 2>&1; then
    echo "[ERROR] codex command not found" >&2
    exit 1
  fi

  codex plugin marketplace add "${PROJECT_DIR}"
  codex plugin add "${PLUGIN_NAME}@ucsc-wordpress-local"
  echo "[OK] Installed ${PLUGIN_NAME}@ucsc-wordpress-local"
else
  cat <<EOF

To register and install the local Codex plugin:
  ${SCRIPT_DIR}/codex.sh --install

Then launch Codex from the app under development, for example:
  cd /path/to/wp-dev.ucsc
  codex
EOF
fi
