---
title: "ADR-018: Maintainer skill owns the canonical slide deck"
status: Accepted
date: 2026-06-10
---

# ADR-018: Maintainer skill owns the canonical slide deck

**Status:** Accepted
**Date:** 2026-06-10

## Context

The presentation source lived at the `wp-dev.ucsc` repository root while its validation, freshness checks, ADR coverage, and Google Docs publication were plugin-maintenance responsibilities. That separation made ownership unclear and allowed the publishing script and deck content to drift from the maintainer workflow.

## Decision

1. The canonical Marp source lives at:
   `skills/maintainer/assets/ucsc_wp_block_dev_presentation.md`.
2. The repository root must not contain a second copy of the deck.
3. `.claude/scripts/publish_to_gdoc.py` reads the maintainer-owned asset directly.
4. The `maintainer` skill exposes a `publish-slides` operation that verifies skills, commands, ADR coverage, and the generated date before publishing.
5. The plugin test suite enforces the canonical path, complete top-level skill inventory, generated-date format, and publisher path.

## Consequences

- The deck has one source of truth next to the workflow that maintains it.
- Publishing and validation remain discoverable through the maintainer command.
- Future skill additions or path drift fail deterministic tests before publication.
