---
title: "ADR-038: Contributed skills use proposal and incubator tiers"
status: Accepted
date: 2026-06-15
---

# ADR-038: Contributed skills use proposal and incubator tiers

## Status

Accepted

## Context

Contributors need a low-risk place to suggest new skills or submit incomplete
workflow ideas. Putting drafts under `skills/` makes them part of the live
plugin inventory before they meet triggering, validation, documentation, and
maintenance standards. Requiring contributors to edit canonical skills also
mixes proposal authorship with maintainer approval.

## Decision

Create a non-discovered `contrib/` tree with two tiers:

1. `contrib/proposals/` contains idea documents based on a proposal template.
2. `contrib/incubator/<skill-name>/` contains maintainer-accepted candidate
   skills that are being developed and evaluated.

The lifecycle is `proposal -> incubator -> skills`. Only maintainers promote a
candidate into `skills/`, after checking scope overlap, frontmatter, references,
tests, realistic trigger examples, and documentation impact.

The maintainer skill exposes `review-contrib` and `promote-contrib` operations.
Normal plugin validation and skill discovery exclude `contrib/` so incomplete
candidates cannot trigger accidentally.

Contributors do not need to modify or merge directly into the canonical
`skills/` tree. Their proposal must still be submitted through a normal
repository contribution channel before a maintainer can review it.

## Consequences

- Incomplete ideas remain visible to maintainers but unavailable to users.
- Maintainers own the quality gate and the final production integration.
- Candidate skills can be tested and revised without changing the supported
  command surface.
- The repository carries a small amount of additional process documentation
  and template content.

