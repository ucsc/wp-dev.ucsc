---
title: "ADR-014: Slide deck documents all top-level skills and commands"
status: Superseded
date: 2026-06-10
---

# ADR-014: Slide deck documents all top-level skills

Superseded by ADR-039. The inventory requirement remains, but the deck now
describes portable skills rather than a command surface.

**Status:** Accepted
**Date:** 2026-06-10

## Context

The slide deck's skill landscape table was incomplete — it listed 8 of the plugin's 14 skills, omitting `start`, `setup`, `test`, `review`, `menu`, and `issue-context`. New skills added after the initial deck creation were not reflected. The maintainer slide also lacked mention of the ADR pattern used for architecture decisions.

## Decision

1. The slide deck's "Plugin Skills Landscape" section must list every skill in the plugin, organized into three groups:
   - **User-invocable commands** — skills that developers call directly via `/ucsc-wp-block-dev:<name>`.
   - **Block-specific guides** — skills scoped to individual Gutenberg blocks.
   - **Auto-loaded / internal** — skills that are not directly invoked (auto-loaded context, internal helpers, deprecated stubs).

2. The "Blocks Reference & Maintainer Skills" slide must document the ADR pattern — where ADRs live, what they capture, and how to create new ones.

3. When a skill is added or removed, the slide deck must be updated in the same change or flagged for update.

## Consequences

- The slide deck is a reliable overview of plugin capabilities for onboarding and presentations.
- Internal skills are visible in the deck (marked as such) so maintainers understand the full component set.
- The ADR pattern is documented alongside the maintainer workflow it supports.
