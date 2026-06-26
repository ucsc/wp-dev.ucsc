---
title: "ADR-106: Marker-driven documentation — harvest doc landmarks like implements: markers"
status: Accepted
date: 2026-06-25
related: ["ADR-018", "ADR-045", "ADR-048", "ADR-086", "ADR-099", "ADR-107"]
---

# ADR-106: Marker-driven documentation — harvest doc landmarks like implements: markers

## Status

Accepted (first harvester built 2026-06-25; superseding the original Proposed sketch below).

## Context

The plugin already generates published documentation (portable guide + slide
deck) from canonical sources — the README and the ADR index — rather than
hand-maintaining them (ADR-045, ADR-048). Those generators carry a fair amount of
prose *inside* the `maintainer/references/generate-docs-*.md` files describing
**how the doc should be assembled**. That couples "what is worth documenting" to
the generator instead of to the code/skill it describes, and the description
lives away from the thing it documents, so it drifts.

Separately, the plugin has a proven pattern for the inverse problem: the
`implements:` marker (ADR-086) places a lightweight, full-slug tag *in* each
skill/script at the point it realizes a decision, and a harvester
(`check-adr-implements.py`) collects those markers by number. The signal lives
where it is true; a dumb script gathers it. This is the same shape as the
doc-generation problem, pointed the other way.

## Decision

Adopt marker-driven harvest for the **slide deck**, the first artifact to consume
it. The slides are a tour of the plugin itself, so their per-skill content should
live next to each skill, not in the generator.

1. **Doc landmark markers.** Each `SKILL.md` may carry a single
   `<!-- doc-slide: ... -->` landmark — a one-line tour summary placed where it is
   true, mirroring the `implements:` convention (ADR-086). It is an HTML comment so
   it adds zero render/token cost to the skill (ADR-003).

2. **A dumb harvester.** `skills/maintainer/scripts/build-slides.py` collects those
   landmarks and rewrites two AUTO-marked regions in the canonical deck in place:
   `AUTO:skills` (one slide per public skill) and `AUTO:roadmap` (Proposed ADRs).
   It draws structure (the ordered skill set, argument hints, sub-modes) from the
   existing `skill-tree.json` source of truth, so the per-skill slides cannot
   drift from the live inventory; the `doc-slide:` landmark (falling back to the
   tree's `short_description`) supplies the prose. It follows the orchestrating
   single-pass wrapper discipline (ADR-099) and supports `--check` (exit 3 when
   regions are stale) for tests.

3. **Sources stay canonical (ADR-045/048).** Harvest complements, does not replace,
   the README + ADR-index generation. The hand-authored framing slides remain in
   the canonical deck (ADR-018) outside the AUTO markers; `regenerate-docs.sh`
   runs `build-slides.py` before copying and hashing, so a `docs` run always
   reflects the live tree. The roadmap is harvested from ADR status, so an ADR
   moving Proposed → Accepted drops off the roadmap automatically.

**Scope today:** only the deck consumes landmarks; the guide stays README-derived
(ADR-107). The `doc-slide:` vocabulary is deliberately the only marker for now —
extend to other landmark kinds or artifacts only when a second need appears.

## Consequences

- **Positive:** documentation signal lives next to the skill it describes, reducing
  drift; the generator is deterministic and free of editorial prose; reuses the
  proven, test-friendly harvest pattern (ADR-086) and single-pass wrapper
  discipline (ADR-099). Adding or renaming a skill, or flipping an ADR's status,
  updates the slides on the next `docs` run with no deck edit.
- **Negative / risks:** another marker vocabulary to keep tidy; a `doc-slide:`
  landmark can rot if not refreshed with the skill. The pytest suite asserts the
  AUTO regions are current (`build-slides.py --check`) so the deck cannot silently
  drift, but it does not yet require every skill to carry a landmark (missing ones
  fall back to `short_description`).
- **Provenance:** the original Proposed sketch was captured from
  `PORTABLE-PATTERNS.md` ("Emerging idea: marker-driven documentation (not yet
  built)") before that working note was deleted; this revision records the built
  system.
