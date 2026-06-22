---
title: "ADR-082: Survey is a develop sub-skill"
status: Superseded
date: 2026-06-18
related: ["ADR-081", "ADR-032", "ADR-041", "ADR-044"]
superseded_by: "ADR-088"
---

# ADR-082: Survey is a develop sub-skill

## Status

Superseded by ADR-088. `survey` was later retired from the live skill
inventory.

## Context

ADR-081 established that sub-skill directories may nest under a parent skill,
provided each nested `SKILL.md` is referenced from the parent. `feature` and
`fix` were the first application, moving under `develop/`.

`survey` audits UCSC custom block usage across the CampusPress network. It shares
`develop`'s domain knowledge — it reads the same block-detection fingerprints in
`develop/references/domain-detection.md`, and the audit it produces feeds block
authoring and targeting decisions (which sites use a block, where a change lands).
Kept at the top level, `survey` widened the discoverable workflow surface with an
entry that is conceptually part of the develop domain rather than an independent
product workflow.

Survey is also not a routine product action a casual user reaches for; it is a
domain audit invoked occasionally. Nesting it under `develop` keeps it available
while removing it from the public, directly-invocable workflow list — matching the
ADR-081 criteria: it shares reference material with the parent, and promoting it to
the top level adds surface without routing clarity.

## Decision

Move `survey` from `skills/survey/` to `skills/develop/survey/` as a `develop`
sub-skill (ADR-081).

- `develop/SKILL.md` references `survey/SKILL.md` from its `## Sub-workflows`
  section (extends ADR-032).
- `survey` is removed from the public README skills table, the hub public-workflow
  table, the AGENTS.md routing table, and the slide-deck table. It remains
  discoverable through `develop` and by describing the audit goal.
- `EXPECTED_DEVELOP_SUB_SKILLS` in the test suite gains `survey`; it leaves
  `EXPECTED_LIVE_SKILLS`.

## Consequences

- **Positive:** The top-level workflow surface shrinks; block-usage auditing is
  grouped with the develop domain it informs.
- **Positive:** `survey` keeps its full `SKILL.md` and reference content, now
  nested under `develop/`.
- **Negative:** `survey` is no longer a direct top-level slash entry; users reach
  it through `develop` or by describing the goal.
- **Negative:** Inventory surfaces (README, hub, AGENTS.md, slide deck, tests) all
  required updating, the same maintenance cost as any skill move.
