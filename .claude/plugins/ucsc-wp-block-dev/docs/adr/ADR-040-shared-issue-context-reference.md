---
title: "ADR-040: Issue context is a shared develop reference"
status: Accepted
date: 2026-06-15
---

# ADR-040: Issue context is a shared develop reference

## Status

Accepted

## Context

Issue normalization supports feature and fix workflows but is not an
independent user outcome. Keeping it as a top-level skill adds discovery
metadata and makes an implementation detail look like a public workflow.

The plugin also needs a concrete pattern for progressively disclosed reference
files that multiple skills can reuse.

## Decision

Move issue normalization guidance to:

`skills/develop/references/issue-context.md`

The `develop` skill owns and indexes the reference. `feature` and `fix` link to
the same file and read it only when Jira, Confluence, pasted ticket details, or
issue normalization applies.

Remove the top-level `issue-context` skill from the discoverable inventory.

## Consequences

- The public skill inventory decreases from 14 to 13 skills.
- Jira and issue handling remains shared without consuming a skill slot.
- `develop/references/` establishes the preferred pattern for reusable,
  progressively disclosed development guidance.
- ADR-032 continues to ensure the owning skill links every support file.

