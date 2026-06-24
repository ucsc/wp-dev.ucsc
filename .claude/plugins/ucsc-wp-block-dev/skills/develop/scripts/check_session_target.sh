#!/usr/bin/env bash
# implements: ADR-094-DEVELOP-SCRIPTS
# One-call check of the session block target (ADR-093/ADR-094).
#
# Bundles the related session-target checks into a single command so a skill
# instructs Claude to run only this script (ADR-094), instead of a sequence of
# ad-hoc commands. Self-locates via ${BASH_SOURCE[0]} so it works regardless of
# the caller's working directory or whether ${CLAUDE_PLUGIN_ROOT} is set.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<EOF
Usage: check_session_target.sh [show | --help]

Report the session block target in one call (ADR-093/ADR-094):
  - confirms session_target.sh and block_target_check.sh are present
  - prints the persisted target ("<slug> <repo> <path>", or a notice if unset)
  - validates the persisted filesystem path with block_target_check.sh when one
    is recorded

  show   Print the source of the target-resolution scripts (session_target.sh,
         block_target_check.sh) instead of running the checks — a safe single
         command in place of an ad-hoc \`cat\`/\`for\` loop (ADR-094/ADR-095).

Issue it as the single canonical command:
  bash "\${CLAUDE_PLUGIN_ROOT}/skills/develop/scripts/check_session_target.sh"
EOF
}

case "${1:-}" in
  --help|-h|help)
    usage
    exit 0
    ;;
  show)
    for f in session_target.sh block_target_check.sh; do
      echo "===== $f ====="
      if [ -f "$SCRIPT_DIR/$f" ]; then
        cat "$SCRIPT_DIR/$f"
      else
        echo "(absent)"
      fi
      echo
    done
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

echo "=== scripts present? ==="
ls -1 \
  "$SCRIPT_DIR/session_target.sh" \
  "$SCRIPT_DIR/block_target_check.sh"

echo "=== persisted session target (get) ==="
target="$(bash "$SCRIPT_DIR/session_target.sh" get || true)"
if [ -z "$target" ]; then
  echo "(no persisted target — resolve one per ADR-093 before proceeding)"
else
  echo "$target"
  target_path="$(bash "$SCRIPT_DIR/session_target.sh" dir || true)"
  if [ -n "$target_path" ]; then
    echo "=== validate persisted path is a real block ==="
    bash "$SCRIPT_DIR/block_target_check.sh" "$target_path" || \
      echo "(persisted path failed block_target_check — treat target as unresolved)"
  fi
fi
