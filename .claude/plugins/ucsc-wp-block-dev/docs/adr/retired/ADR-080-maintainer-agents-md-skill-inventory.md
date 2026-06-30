---
title: "ADR-080: Keep AGENTS.md synchronized with live skill inventory"
status: Superseded
date: 2026-06-17
related: ["ADR-061", "ADR-067", "ADR-073"]
---

# ADR-080: Keep AGENTS.md synchronized with live skill inventory

## Status

Accepted

## Context

The repository root `AGENTS.md` is the first instruction surface Codex receives
for `wp-dev.ucsc`. It includes a skill routing table for the
`ucsc-wp-block-dev` plugin.

That table drifted from the live plugin inventory: it still listed retired
surfaces such as `map`, `documentation`, and `blocks`, while omitting live
skills such as `hub`, `survey`, and `retrospective`. This caused Codex to look
for skills that no longer exist before falling back to the correct available
skills.

ADR-067 introduced `sync-inventory.sh` for inventory consistency, but its
documented sync set did not include the root `AGENTS.md` table. ADR-073 also
keeps plugin operations scoped to `.claude/plugins/ucsc-wp-block-dev/`, so
`AGENTS.md` should stay a concise routing shim rather than a duplicate copy of
skill instructions.

## Decision

Whenever a live skill is added, removed, renamed, or has its routing summary
changed, update the root `AGENTS.md` skill routing table in the same inventory
sync pass as the plugin README, `hub` skill, slide deck, and tests.

The authoritative source remains the live directories under
`.claude/plugins/ucsc-wp-block-dev/skills/` that contain `SKILL.md`.
`AGENTS.md` must list those live skills and no retired skill names in its
routing table.

Extend `skills/maintainer/scripts/sync-inventory.sh` so:

1. `--check` reports drift in `AGENTS.md`.
2. `--write` regenerates the root `AGENTS.md` routing table.
3. The existing pytest coverage that checks `AGENTS.md` remains part of the
   deterministic maintainer test suite.

Do not duplicate full skill content into `AGENTS.md`; it should continue to
point agents at the canonical skill source and require reading the relevant
`SKILL.md` before acting.

## Consequences

- **Positive:** Codex receives an accurate skill routing table before any
  plugin-specific task begins.
- **Positive:** Stale skill names are caught by `sync-inventory.sh --check`
  and the existing pytest tests instead of through runtime confusion.
- **Negative:** `sync-inventory.sh --write` now edits a repository-root file
  outside the plugin directory, so maintainers must review that diff along with
  plugin-owned documentation changes.
