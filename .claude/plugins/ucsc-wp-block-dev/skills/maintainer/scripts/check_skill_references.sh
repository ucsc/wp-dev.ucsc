#!/bin/bash
# check_skill_references.sh — enforce ADR-032: every supporting file under a
# skill directory must be referenced from that skill's top-level SKILL.md, so
# nested reference/asset/script files stay discoverable (progressive disclosure).
#
# For each skills/<name>/SKILL.md, every other file under skills/<name>/ must be
# mentioned in SKILL.md by its skill-relative path (preferred) or basename.
#
# Output is compact: one line per skill with unreferenced files; a final
# PASS/FAIL. Exit 0 when all supporting files are referenced, 1 otherwise.
#
# Usage:  check_skill_references.sh [--quiet]
# Skips dotfiles, __pycache__, *.pyc, and the SKILL.md itself.

set -uo pipefail

QUIET=0
[ "${1:-}" = "--quiet" ] && QUIET=1

SKILLS_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
[ -d "$SKILLS_DIR" ] || { echo "ERROR: skills dir not found at $SKILLS_DIR"; exit 2; }

FAILED=0
TOTAL_SKILLS=0
TOTAL_FILES=0
MISSING=0

for skill_md in "$SKILLS_DIR"/*/SKILL.md; do
  [ -f "$skill_md" ] || continue
  sdir="$(dirname "$skill_md")"
  sname="$(basename "$sdir")"
  TOTAL_SKILLS=$((TOTAL_SKILLS + 1))

  # supporting files = everything under the skill dir except SKILL.md / noise
  files=$(find "$sdir" -type f \
            ! -name 'SKILL.md' \
            ! -name '.*' \
            ! -name '*.pyc' \
            ! -path '*/__pycache__/*' 2>/dev/null | sort)
  [ -n "$files" ] || continue

  skill_missing=""
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    TOTAL_FILES=$((TOTAL_FILES + 1))
    rel="${f#$sdir/}"
    base="$(basename "$f")"
    if grep -qF "$rel" "$skill_md" || grep -qF "$base" "$skill_md"; then
      :
    else
      skill_missing="$skill_missing $rel"
      MISSING=$((MISSING + 1))
    fi
  done <<EOF
$files
EOF

  if [ -n "$skill_missing" ]; then
    FAILED=1
    printf '  [FAIL] %s:%s\n' "$sname" "$skill_missing"
  elif [ "$QUIET" -eq 0 ]; then
    printf '  [ OK ] %s\n' "$sname"
  fi
done

echo "----"
echo "skills: $TOTAL_SKILLS   supporting files: $TOTAL_FILES   unreferenced: $MISSING"
if [ "$FAILED" -eq 0 ]; then
  echo "RESULT: PASS"
else
  echo "RESULT: FAIL — add a relative-path reference (e.g. references/foo.md) to the skill's SKILL.md, or remove the obsolete file."
fi
exit "$FAILED"
