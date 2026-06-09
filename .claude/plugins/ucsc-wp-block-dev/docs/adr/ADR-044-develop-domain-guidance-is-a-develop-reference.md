---
title: "ADR-044: Domain guidance is a develop reference"
status: Accepted
date: 2026-06-15
---

# ADR-044: Domain guidance is a develop reference

## Status

Accepted

## Context

The `blocks` skill contained useful domain guidance for the
`ucsc-gutenberg-blocks` WordPress plugin, but it was not an independent user
workflow. Keeping it as a top-level skill made command discovery noisier and
made reference material look like something users should invoke directly.

The plugin already uses `develop/references/` for progressively disclosed,
shared implementation context such as issue normalization and block targets.

## Decision

Move WordPress block domain guidance to:

`skills/develop/references/domain/blocks.md`

Move its support files under:

`skills/develop/references/domain/references/`

The `develop` skill owns and indexes those files. `map`, `feature`, `fix`, and
other workflow skills may point users or agents to that reference when work
touches `ucsc-gutenberg-blocks`, but `blocks` is not a top-level skill.

## Consequences

- The public skill inventory decreases by one skill.
- WordPress domain guidance remains available through progressive disclosure.
- The exported skill list is closer to user-facing workflows.
- ADR-032 continues to ensure the owning skill links every support file.
