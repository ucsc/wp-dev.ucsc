---
title: "ADR-041: Block targets are develop references"
status: Accepted
date: 2026-06-15
---

# ADR-041: Block targets are develop references

## Status

Accepted

## Context

Campus Directory, Class Schedule, and Course Catalog describe domain targets,
not independent workflows. Exposing each as a top-level skill consumes
discovery space and mixes the action being performed with the object being
changed.

## Decision

Move block-specific guidance under:

`skills/develop/references/targets/`

The `develop` skill requires the user to choose a target before tools are used.
It resolves known slugs and aliases through `targets/index.md` and loads only
the selected reference. `feature` and `fix` may reuse the same target index.

Remove `campus-directory`, `class-schedule`, and `course-catalog` from the
top-level skill inventory.

## Consequences

- The public inventory decreases from 13 to 10 skills.
- Workflow skills describe actions; target references describe domain objects.
- Adding a supported target does not add always-visible skill metadata.
- Progressive disclosure limits target context to the block currently in use.

