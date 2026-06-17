#!/bin/bash
# new_adr.sh — automatically allocates the next ADR number, creates the ADR
# markdown file with frontmatter, and updates docs/adr/index.md.
#
# Usage:
#   bash new_adr.sh <slug> "<title>"
#
# Example:
#   bash new_adr.sh test-driver "Test Driver implementation"

set -uo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: $0 <slug> \"<title>\""
  exit 1
fi

SLUG_RAW="$1"
TITLE="$2"

# Normalize slug: lowercase, replace non-alphanumerics with hyphens, collapse consecutive hyphens
SLUG=$(echo "$SLUG_RAW" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\{1,\}/-/g' | sed 's/^-//' | sed 's/-$//')

# Locate docs/adr/
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ADR_DIR="$(cd "${SCRIPT_DIR}/../../../docs/adr" && pwd)"

if [ ! -d "$ADR_DIR" ]; then
  echo "ERROR: docs/adr directory not found at: $ADR_DIR"
  exit 2
fi

# Find the highest ADR number in the directory
last_num=$(ls "$ADR_DIR" | grep -E '^ADR-[0-9]{3}-' | sed -E 's/^ADR-([0-9]{3})-.*/\1/' | sort -n | tail -n1)

if [ -z "$last_num" ]; then
  next_num=1
else
  # Force base 10 to avoid octal interpretation of leading zeros
  next_num=$((10#$last_num + 1))
fi

next_str=$(printf "%03d" "$next_num")
ADR_FILE="ADR-${next_str}-${SLUG}.md"
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
