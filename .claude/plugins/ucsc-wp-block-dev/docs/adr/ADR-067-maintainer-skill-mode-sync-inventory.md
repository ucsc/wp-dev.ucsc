---
title: "ADR-067: Introduce sync-inventory.sh script to enforce skill inventory consistency"
status: Accepted
date: 2026-06-16
---

# ADR-067: Introduce sync-inventory.sh script to enforce skill inventory consistency

## Status

Accepted (consolidates ADR-080 2026-06-29)

## Context

The plugin maintains its skill inventory in multiple places across the repository:
1. The `README.md` skills table.
2. The `skills/hub/SKILL.md` public workflows table and hidden manual skills list.
3. The slide deck skill table (`skills/maintainer/assets/ucsc-wp-block-dev-presentation.md`).
4. The `EXPECTED_LIVE_SKILLS` list in the python tests (`tests/test_plugin_structure.py`).

Adding or removing a skill required manually updating all of these files. Failing to do so resulted in test suite failures and documentation drift (such as with the `survey` skill).

## Decision

We will introduce a script at `skills/maintainer/scripts/sync-inventory.sh` (wrapping an inline Python3 script) to automate inventory synchronization:

1. It treats the active directories under `skills/` containing `SKILL.md` as the single source of truth.
2. By default (or with `--check`), it performs a dry-run check to identify if any listing is out of sync and exits non-zero if drift is found.
3. With `--write`, it automatically reconciles and updates:
   - The tables in `README.md`.
   - The public/hidden listings in `skills/hub/SKILL.md`.
   - The skills table in the presentation slide deck markdown.
   - The `EXPECTED_LIVE_SKILLS` set in `tests/test_plugin_structure.py`.
4. It contains a static mapping of descriptions and triggers to preserve desired table content formatting, but falls back to the skill's YAML frontmatter description for any new, unrecognized skill.

## AGENTS.md sync (absorbed from ADR-080)

The root `AGENTS.md` routing table is also part of the sync set. Whenever a skill
is added, removed, renamed, or has its routing summary changed, update `AGENTS.md`
in the same inventory sync pass. `sync-inventory.sh --check` reports drift in
`AGENTS.md`; `--write` regenerates its routing table. `AGENTS.md` must list only
live skills and no retired skill names. Do not duplicate full skill content into
`AGENTS.md` — it points agents at the canonical skill source and requires reading
the relevant `SKILL.md` before acting.

## Consequences

- **Positive:** Retires the inventory-sync gotcha.
- **Positive:** Automates updates to documentation, `AGENTS.md`, and tests, reducing development friction when skills are added/removed.
- **Positive:** Stale skill names in `AGENTS.md` are caught by `sync-inventory.sh --check` and the existing pytest tests.
- **Negative:** `sync-inventory.sh --write` now edits a repository-root file outside the plugin directory; review that diff alongside plugin-owned documentation changes.
