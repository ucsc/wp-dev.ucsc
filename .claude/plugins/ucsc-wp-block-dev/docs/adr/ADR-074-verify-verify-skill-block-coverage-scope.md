---
title: "ADR-074: verify skill block coverage scope — start with ucsc-gutenberg-blocks, extend to ucsc-blocks on onboarding"
status: Accepted
date: 2026-06-17
---

# ADR-074: verify skill block coverage scope

## Status

Accepted

## Context

The `verify` skill validates live block behavior in the running WordPress editor
and frontend. The `ucsc-wp-block-dev` plugin currently supports two plugins:

- **`ucsc-gutenberg-blocks`** — the original plugin with blocks including
  `class-schedule`, `course-catalog`, and `campus-directory`. These blocks have
  full target references and established verify workflows.
- **`ucsc-blocks`** — a newer plugin containing `calendar-feed` (`ucsc/calendar-feed`)
  and `ucsc-events` (`ucsc/events`). Target references for these blocks were
  added in June 2026, but their verify workflows, acceptance criteria, and
  live-test patterns have not yet been established.

A question arose: should `verify` check all blocks across both plugins, or scope
to the blocks that have mature support?

## Decision

The `verify` skill's block-coverage scope is managed in two phases:

**Phase 1 (current):** `verify` covers only the original three `ucsc-gutenberg-blocks`
blocks: `class-schedule`, `course-catalog`, and `campus-directory`. These are the
blocks with established target references, full verify acceptance criteria, and
tested live-environment workflows.

**Phase 2 (future):** Once `calendar-feed` and `ucsc-events` from `ucsc-blocks` are
fully onboarded — meaning they have verify acceptance criteria, live-test
patterns, and confirmed Docker environment wiring — they will be added to the
`verify` scope. This ADR should be updated to "Superseded" at that point and a
new ADR written to document the expanded scope.

Onboarding criteria for a block to enter verify scope:
1. Target reference exists in `skills/develop/references/targets/`.
2. Verify acceptance criteria documented (step-by-step live test checklist).
3. Block confirmed to render correctly in the `wp-dev.ucsc` Docker environment.
4. At least one verify session completed successfully for that block.

## Consequences

- `verify` skill prompt and any hardcoded block lists reference only the three
  original blocks until Phase 2 is explicitly triggered.
- The two `ucsc-blocks` targets (`calendar-feed`, `ucsc-events`) are discoverable
  via `develop`/`fix`/`feature` immediately — only `verify` scope is deferred.
- Future maintainer adding a new block to verify scope should update this ADR
  status to Superseded, write a new ADR, and update the verify skill and any
  related tests.
