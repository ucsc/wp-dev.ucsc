---
title: "ADR-083: Retrospective sub-skill — structure, offer model, and closing checklist"
status: Accepted
date: 2026-06-18
related: ["ADR-081", "ADR-032", "ADR-046", "ADR-049"]
---

# ADR-083: Retrospective is a maintainer sub-skill

## Status

Accepted

## Context

ADR-081 permits sub-skill directories nested under a parent skill. `retrospective`
captures session lessons into the plugin's own skill and reference files (ADR-049,
ADR-059) and prompts for script, skill, and test improvements (ADR-077). That work
— enriching the plugin's skills, references, scripts, and tests — is plugin
maintenance, the same domain `maintainer` owns (ADR-046).

`retrospective` was already a hidden manual skill, excluded from the public
workflow list alongside `maintainer`. Keeping it as a separate top-level entry
split one maintenance concern across two top-level skills. Nesting it under
`maintainer` consolidates plugin self-maintenance under a single parent, with no
change to its hidden visibility.

## Decision

Move `retrospective` from `skills/retrospective/` to
`skills/maintainer/retrospective/` as a `maintainer` sub-skill (ADR-081).

- `maintainer/SKILL.md` references `retrospective/SKILL.md` from a
  `## Sub-workflows` section (extends ADR-032).
- `retrospective` leaves `EXPECTED_LIVE_SKILLS`; a new
  `EXPECTED_MAINTAINER_SUB_SKILLS` set declares it, enforced by a parallel
  reference test (`test_maintainer_sub_skills_are_referenced_from_maintainer`).
- The ADR-077 closing-checklist test now reads
  `maintainer/retrospective/SKILL.md`.
- Visibility is unchanged: `retrospective` stays out of the public README, hub
  public-workflow table, and slide-deck tables. It remains reachable through
  `maintainer retro` or by describing the goal at session end. `retro` is the
  concise public mode name; `retrospective` remains the internal sub-skill
  directory and frontmatter name.

## Offer model (absorbed from ADR-059)

After completing a `fix`, `feature`, or `review` activity, the assistant **offers**
a retrospective rather than running one unconditionally. When the user accepts, the
retrospective captures lessons into both:
1. **Skills** — appropriate skill reference documents or the relevant `SKILL.md`.
2. **Scripts** — plugin helper scripts, when the session surfaced a fix, hardening,
   or new capability for a build, launch, verification, or maintenance script.

If the session produced no durable lesson, note that and skip. Missing MCP must not
block work. Consistent with the offer pattern (see ADR-023 for commit offer).

## Closing checklist (absorbed from ADR-077)

At the end of every retrospective session, explicitly evaluate three questions:

1. **Script candidate** — was there a multi-step manual operation that could be
   automated? If yes, write a script under `skills/<skill>/scripts/` and link it
   from `SKILL.md`.
2. **Skill improvement candidate** — was there guidance the model re-derived from
   scratch that should be in a reference file? If yes, add it.
3. **Token-reduction candidate** — did a token-heavy operation surface something a
   cheaper structural test could have caught? If yes, add or improve the test.

None are required — if the session was routine and nothing new was learned, say so.
The goal is the prompt, not ceremony.

## Consequences

- **Positive:** Plugin self-maintenance — validation, docs, contrib review, and
  lesson capture — is consolidated under `maintainer`.
- **Positive:** The top-level workflow surface shrinks by one more entry.
- **Positive:** `retrospective` keeps its full `SKILL.md` with the closing checklist
  intact, now nested under `maintainer/`.
- **Positive:** End-of-task overhead is incurred only when there is something worth
  saving; retrospective sessions produce actionable artifacts, not just prose.
- **Negative:** `retrospective` is no longer a direct top-level entry; users reach
  it through `maintainer` or by describing the goal.
- **Negative:** The sub-skill reference invariant now spans two parents
  (`develop` and `maintainer`), each with its own expectation set and test.
