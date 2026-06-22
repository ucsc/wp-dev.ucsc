#!/bin/bash
# implements: ADR-086-MAINTAINER-CONVENTIONS
# new_adr.sh — automatically allocates the next ADR number, creates the ADR
# markdown file with frontmatter, and updates docs/adr/index.md.
#
# Usage:
#   bash new_adr.sh <skill> <mode> "<title>"   # ADR-NNN_skill_mode_detail.md
#   bash new_adr.sh <slug> "<title>"           # legacy alias, ADR-NNN_slug.md
#
# Example:
#   bash new_adr.sh maintainer backlog "Track a maintainer backlog"

set -uo pipefail

usage() {
  sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'
}

case "${1:-}" in
  --help|-h)
    usage
    exit 0
    ;;
esac

# Per ADR-086, new ADRs use
# ADR-NNN_<skill>_<mode>_<detail>.md (underscore, lowercase).
# Two call forms:
#   new_adr.sh <skill> <mode> "<title>"   -> ADR-NNN_<skill>_<mode>_<detail>.md
#   new_adr.sh <slug> "<title>"           -> ADR-NNN_<slug>.md (legacy alias)
if [ $# -lt 2 ]; then
  echo "Usage: $0 <skill> <mode> \"<title>\"   (preferred, ADR-086)"
  echo "       $0 <slug> \"<title>\"            (legacy)"
  exit 1
fi

norm() { echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/_\{1,\}/_/g' | sed 's/^_//' | sed 's/_$//'; }

if [ $# -ge 3 ]; then
  SKILL=$(norm "$1")
  MODE=$(norm "$2")
  TITLE="$3"
  DETAIL=$(norm "$TITLE")
  NAME_PART="${SKILL}_${MODE}_${DETAIL}"
else
  NAME_PART=$(norm "$1")
  TITLE="$2"
fi

# Locate docs/adr/
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ADR_DIR="$(cd "${SCRIPT_DIR}/../../../docs/adr" && pwd)"

if [ ! -d "$ADR_DIR" ]; then
  echo "ERROR: docs/adr directory not found at: $ADR_DIR"
  exit 2
fi

# Find the highest ADR number in the directory. Match ADR files by their leading
# number (3+ digits, dash or underscore separator) so numbering stays correct
# across older worktrees (ADR-086).
last_num=$(ls "$ADR_DIR" "$ADR_DIR"/retired 2>/dev/null | grep -E '^ADR-[0-9]{3,}[-_]' | sed -E 's/^ADR-([0-9]{3,})[-_].*/\1/' | sort -n | tail -n1)

if [ -z "$last_num" ]; then
  next_num=1
else
  # Force base 10 to avoid octal interpretation of leading zeros
  next_num=$((10#$last_num + 1))
fi

next_str=$(printf "%03d" "$next_num")
ADR_FILE="ADR-${next_str}_${NAME_PART}.md"
ADR_PATH="${ADR_DIR}/${ADR_FILE}"
CURR_DATE=$(date +%Y-%m-%d)

echo "Creating ADR-${next_str} (${ADR_FILE})..."

# Write ADR skeleton
cat <<EOF > "$ADR_PATH"
---
title: "ADR-${next_str}: ${TITLE}"
status: Accepted
date: ${CURR_DATE}
---

# ADR-${next_str}: ${TITLE}

## Status

Accepted

## Context

<Context>

## Decision

<Decision>

## Consequences

- **Positive:** <Consequence>
- **Negative:** <Consequence>
EOF

# Update index.md
INDEX_PATH="${ADR_DIR}/index.md"
if [ -f "$INDEX_PATH" ]; then
  # Check if index ends with a newline, if not add one
  tail_char=$(tail -c 1 "$INDEX_PATH")
  if [ "$tail_char" != "" ]; then
    echo "" >> "$INDEX_PATH"
  fi
  
  # Append the new row to the table
  echo "| [ADR-${next_str}](${ADR_FILE}) | ${TITLE} | Accepted | ${CURR_DATE} |" >> "$INDEX_PATH"
  echo "Updated index.md with ADR-${next_str}."
else
  echo "WARNING: index.md not found in $ADR_DIR"
fi

echo "Done! File created at docs/adr/${ADR_FILE}"
