---
title: "ADR-081: Sub-skill directories nested under a parent skill are permitted"
status: Accepted
date: 2026-06-18
related: ["ADR-032", "ADR-036", "ADR-041", "ADR-044"]
---

# ADR-081: Sub-skill directories nested under a parent skill are permitted

## Status

Accepted

## Context

ADR-032 requires every file under a skill directory to be referenced from that
skill's `SKILL.md`. ADR-041 and ADR-044 established that block targets and
domain guidance live as reference files under `develop/references/` rather than
as top-level skills.

The `feature` and `fix` skills were historically top-level entries in
`skills/`, each with their own `SKILL.md`. Both delegate their implementation
phase to `develop` and share its reference files. Keeping them at the top level
meant users saw three separate entry points (`develop`, `feature`, `fix`) for
what is conceptually one workflow surface, and the plugin's skill inventory grew
wider than necessary.

A sub-skill model allows a parent skill to own related sub-workflows as nested
directories, each with its own `SKILL.md`, instead of promoting them to
independent top-level skills. This matches how `develop/references/` already
organises progressive reference content, extending the pattern to structured
sub-workflows that carry full skill frontmatter.

Sub-skills at any nesting depth are permitted: a first-level sub-skill may
itself reference further sub-directories, and those may reference deeper ones.
The only invariant is that each directory's `SKILL.md` must be referenced from
the parent `SKILL.md` that contains it.

## Decision

Sub-skill directories are permitted anywhere under a top-level skill directory,
provided every `SKILL.md` in those sub-directories is referenced from the
enclosing skill's `SKILL.md`.

Apply this pattern when:

1. The sub-workflow is always entered through the parent (users invoke `develop`,
   which surfaces `feature` or `fix`), not independently at the top level.
2. The sub-workflow shares reference material with the parent.
3. Promoting it to a top-level skill would widen the discoverable skill surface
   without adding routing clarity.

`feature` and `fix` are moved from `skills/feature/` and `skills/fix/` to
`skills/develop/feature/` and `skills/develop/fix/` as the first application of
this pattern.

Constraints:

- Every nested `SKILL.md` must be linked from its parent `SKILL.md`
  (extends ADR-032).
- Sub-skill directories must not appear under `references/` — those remain
  plain markdown without skill frontmatter (ADR-032 unchanged).
- The `test_develop_sub_skills_are_referenced_from_develop` pytest enforces the
  reference requirement for declared sub-skills under `develop/`.
- `EXPECTED_DEVELOP_SUB_SKILLS` in the test suite declares which directories
  under `develop/` are intentional sub-skills; additions must update this set.

## Consequences

- **Positive:** The top-level skill surface shrinks from eleven to nine entries,
  reducing discovery noise.
- **Positive:** `feature` and `fix` retain their full SKILL.md structure and
  remain readable and linkable, just nested under `develop/`.
- **Positive:** Relative paths within sub-skills shorten (`../references/`
  instead of `../develop/references/`).
- **Negative:** Sub-skill invocation is no longer a direct slash command; users
  reach `feature` and `fix` through `develop` or by describing their goal and
  letting Claude route to the sub-skill from context.
- **Negative:** `hub`, README, AGENTS.md, and tests must all be updated when
  sub-skills are added or removed — the same maintenance burden as top-level
  skills but with an additional nesting layer to track.
