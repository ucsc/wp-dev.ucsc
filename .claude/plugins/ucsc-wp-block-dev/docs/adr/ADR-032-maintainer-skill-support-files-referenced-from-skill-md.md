---
title: "ADR-032: Skill support files must be referenced from SKILL.md"
status: Accepted
date: 2026-06-10
---

# ADR-032: Skill support files must be referenced from SKILL.md

## Status

Accepted

## Context

Skills use progressive disclosure (ADR-003): the top-level `SKILL.md` stays lean and routes to deeper `references/`, `assets/`, and `scripts/` files only when needed. A support file that no `SKILL.md` links to is invisible — Claude never loads it, so it silently rots or duplicates content. As skills accumulate driver scripts and reference docs, this drift becomes likely and is hard to catch by eye.

## Decision

Every file under `skills/<name>/` — other than the top-level `SKILL.md` and
ignorable noise (dotfiles, `__pycache__`, `*.pyc`) — MUST:

1. Use a lowercase kebab-case filename, while preserving conventional names
   such as `SKILL.md`.
2. Be referenced from that skill's `SKILL.md` by its skill-relative path
   (preferred, e.g. `references/stack-profile.md`) or at least its basename.

The invariant is enforced two ways:

- `skills/maintainer/scripts/check-skill-references.sh` — a standalone scanner, exposed as the maintainer `check-references` operation and included in `all`.
- The pytest suite runs the same scanner, so a gap fails `maintainer test` and CI.

When a support file is intentionally unused, the correct action is to remove it, not to suppress the check.

## Consequences

- Nested reference/asset/script files stay discoverable from the skill that owns them.
- Support-file naming follows the same portable convention as plugin component
  directories.
- Adding a support file costs one line of reference in `SKILL.md`, reinforcing its table-of-contents role.
- Obsolete files surface as failures instead of lingering unnoticed.
