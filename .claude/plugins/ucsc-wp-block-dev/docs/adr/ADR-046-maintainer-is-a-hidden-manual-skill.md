---
title: "ADR-046: Maintainer is a hidden manual skill"
status: Superseded
date: 2026-06-15
superseded_by: "ADR-089"
---

# ADR-046: Maintainer is a hidden manual skill

## Status

Superseded by ADR-089. `maintainer` is now a public, user-invocable slash
entry while remaining guarded from model auto-invocation.

## Context

The `maintainer` skill is useful for plugin upkeep, validation, contribution
review, reference checks, documentation generation, and slide publishing. Those
are not normal WordPress block development workflows, so advertising
`maintainer` beside product-facing skills makes the public skill list noisier.

At the same time, maintainers still need a direct way to invoke it.

## Decision

Keep `skills/maintainer/SKILL.md` as a live skill so typing `maintainer`
directly can still invoke it. Remove it from public workflow tables in README,
`map`, and the maintainer slide deck. Document it as a hidden manual skill.

## Consequences

- The public workflow list focuses on block development work.
- Maintainers can still type `maintainer` directly for plugin upkeep.
- Tests distinguish live skills from public workflow skills.
