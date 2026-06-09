---
title: "ADR-098: ADR naming convention to use hyphens and include mode"
status: Superseded
date: 2026-06-24
---

# ADR-098: ADR naming convention to use hyphens and include mode

## Status

Accepted

## Context

We want each ADR to follow a clear format that encodes the primary skill, the skill mode (if applicable), and decision details. We also want to standardize on hyphens `-` rather than underscores `_` for filename separators, and rename all existing ADR files to match this new format.

## Decision

1. All ADR files will be named using the hyphenated format:
   - If the ADR is about a specific mode of a skill: `ADR-XXX-<skill>-<mode>-mode-details.md`
   - If the ADR is about a skill generally: `ADR-XXX-<skill>-details.md`
   - If the ADR is general and does not apply to a specific skill: `ADR-XXX-details.md`
2. `new-adr.sh` is updated to generate new files following this hyphenated naming convention.
3. All existing ADR files (both active and retired) are renamed to match this convention.
4. All references to these filenames across the repository are updated to point to the new hyphenated filenames.

## Consequences

- **Positive:** Standardizes filenames with hyphens, matching the general conventions of the skills specification.
- **Positive:** Explicitly encodes when a decision is specific to a skill mode using `-mode-`.
- **Negative:** Requires renaming existing files and updating their references.
