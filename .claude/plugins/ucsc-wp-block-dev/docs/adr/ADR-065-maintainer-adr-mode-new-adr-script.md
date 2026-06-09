---
title: "ADR-065: ADR mode — automated creation script and naming convention"
status: Accepted
date: 2026-06-16
---

# ADR-065: ADR mode — automated creation script and naming convention

## Status

Accepted (consolidates ADR-098, 2026-06-24)

## Context

Creating Architectural Decision Records (ADRs) is a frequent task during the
development and maintenance of the `ucsc-wp-block-dev` plugin. The process
previously required manually scanning `docs/adr/` and `docs/adr/index.md` to
find the next sequential number, creating a file with the correct name, writing
standard frontmatter, and appending an index entry — tedious, and prone to
number-collision race conditions when multiple tasks or agents were active.

The ADR **filename format** also needed to be standardized: encode the primary
skill, the skill mode (when applicable), and decision details, using hyphens
`-` rather than underscores `_` to match the skills specification. This decision
folds in the former ADR-098 (naming convention) so the `adr` mode's creation
tooling and its naming rules live in one record.

## Decision

Maintain a creation script at `skills/maintainer/scripts/new-adr.sh` that
automates ADR creation, and a single naming convention it enforces.

**Creation script (`new-adr.sh`):**

1. Accepts a skill + mode + title (preferred), or a slug + title (legacy alias).
2. Normalizes the slug into a lowercase, hyphen-separated string.
3. Scans `docs/adr/` (and `retired/`) to resolve the next sequential number,
   retiring the number-collision gotcha.
4. Creates the file with standard ADR frontmatter and skeleton.
5. Appends the entry to the table in `docs/adr/index.md`.

**Naming convention (consolidated from ADR-098):**

1. ADR files use the hyphenated format:
   - mode-specific: `ADR-NNN-<skill>-<mode>-mode-<details>.md`
   - skill-general: `ADR-NNN-<skill>-<details>.md`
   - non-skill: `ADR-NNN-<details>.md`
2. `new-adr.sh` generates files following this hyphenated convention.
3. Existing active and retired ADR files follow this convention (the one-time
   rename was performed by `rename-adrs.py`).
4. References to ADR filenames across the repository point to the hyphenated
   names.

## Consequences

- **Positive:** Reduces token use and eliminates exploratory file-reading and
  hand-editing when creating ADRs.
- **Positive:** Standardizes both filename formatting and skeleton structure, and
  explicitly encodes when a decision is specific to a skill mode via `-mode-`.
- **Positive:** Retires the ADR number-collision gotcha.
- **Negative:** Developers must use the script rather than creating files by hand;
  the one-time rename required updating references across the repository.
