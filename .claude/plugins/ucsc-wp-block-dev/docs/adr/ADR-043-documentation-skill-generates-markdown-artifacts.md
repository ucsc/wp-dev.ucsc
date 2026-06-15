---
title: Documentation skill generates portable Markdown artifacts
status: Superseded
date: 2026-06-15
---

# ADR-043: Documentation Skill Generates Portable Markdown Artifacts

Superseded by [ADR-045](ADR-045-documentation-is-a-maintainer-reference.md).

## Context

The plugin needs maintainer-friendly Markdown artifacts that can be copied into
Google Docs or Confluence: the main guide and the slide deck source. Publishing
is already owned by the `maintainer` skill, but regeneration of portable
Markdown files is a separate concern.

## Decision

Create a top-level `documentation` skill that regenerates Markdown artifacts
under `skills/documentation/assets/` from canonical plugin sources:

- `README.md` for the main guide.
- `skills/maintainer/assets/ucsc_wp_block_dev_presentation.md` for the slide
  deck source.

The skill owns a deterministic `scripts/regenerate.sh` script. It refreshes
generated-date metadata and writes portable Markdown only; it does not publish
or upload.

## Consequences

- Documentation regeneration is discoverable as a portable skill.
- The maintainer-owned slide deck remains canonical.
- Google Docs and Confluence import/paste workflows can use generated assets
  without adding another publishing command.
- Top-level skill inventory tests must include `documentation`.
