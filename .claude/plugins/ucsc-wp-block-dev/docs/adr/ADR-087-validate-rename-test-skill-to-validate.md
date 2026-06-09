---
title: "ADR-087: Rename test skill to validate"
status: Accepted
date: 2026-06-18
related: ["ADR-031", "ADR-066", "ADR-078"]
---

# ADR-087: Rename `test` skill to `validate`

## Status

Accepted

## Context

The plugin skill inventory used `test` for automated test-suite runs (PHP, Jest,
e2e). The name read narrowly and collided conceptually with the maintainer
`validate` operation and the broader idea of asserting correctness. The skill has
several modes (`create`, `run`) and is the automated-test counterpart to the live
`verify` skill.

## Decision

Retire the top-level `test` skill and use `validate` as the top-level skill name.

- Rename `skills/test/` to `skills/validate/`, keep its modes (`create`, `run`)
  and references (`references/create.md`, `references/run.md`). Menu and hub
  surfaces list those modes as distinct lines: `validate create` and
  `validate run`.
- The phase driver is `skills/validate/validate-php.sh`.
- Update skill frontmatter, references, inventory tables (README, hub, AGENTS.md,
  slide deck via `sync-inventory.sh`), structural tests, and prose in `run` and
  `verify` that pointed at the old `test` skill.
- `verify` remains for live runtime verification; `validate` covers automated
  tests and validation checks.

## Consequences

- **Positive:** Clearer intent; `validate` covers automated tests and checks,
  `verify` covers live behavior.
- **Negative:** Backwards-incompatible for scripts or bookmarks referencing the
  old `skills/test/` path or `test` skill name; saved driver invocations must be
  updated.
- **Negative:** Inventory surfaces and several hardcoded test references had to be
  updated together to keep the suite green.
