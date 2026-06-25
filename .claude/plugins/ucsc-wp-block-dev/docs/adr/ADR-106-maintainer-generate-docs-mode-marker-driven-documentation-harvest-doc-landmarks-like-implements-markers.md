---
title: "ADR-106: Marker-driven documentation — harvest doc landmarks like implements: markers"
status: Proposed
date: 2026-06-25
related: ["ADR-045", "ADR-048", "ADR-086", "ADR-099"]
---

# ADR-106: Marker-driven documentation — harvest doc landmarks like implements: markers

## Status

Proposed

> Forward-looking idea, not yet built. Extracted from the (now-removed)
> `PORTABLE-PATTERNS.md` working note so it is not lost. Nothing behaves
> differently because of it yet.

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

**Direction (not adopted yet):** extend the marker-harvest pattern from ADRs to
**documentation landmarks**. Sketch only, to be designed if prioritized:

1. **Doc landmark markers.** Allow a lightweight, full-slug marker (e.g.
   `doc:` / `landmark:` lines, mirroring the `implements:` convention) placed in
   skills and scripts at the spots worth surfacing in published docs — the
   capability, the primary command, the gotcha — right where it is true.

2. **A dumb harvester.** A script collects those markers (the same harvesting
   pattern as the `implements:` checker, and the orchestrating-wrapper discipline
   of ADR-099) into the generated guide/deck artifact. The generator stays
   deterministic and free of editorial prose; the *source* carries the signal of
   what is interesting to document.

3. **Sources stay canonical (ADR-045/048).** This complements, not replaces, the
   README + ADR-index generation: markers add in-code landmarks; the README and
   ADRs remain the canonical narrative sources. Reconcile against the live tree at
   publish time as today.

**Not deciding now:** the marker syntax, whether it shares the `implements:`
harvester or gets its own, and which artifact consumes it first. Deferred until
someone picks it up.

## Consequences

- **Positive (if pursued):** documentation signal lives next to the code it
  describes, reducing drift; the generator gets dumber and more deterministic;
  reuses an already-proven, test-friendly harvest pattern (ADR-086) and the
  single-pass wrapper discipline (ADR-099).
- **Negative / risks:** another marker vocabulary to learn and keep tidy; markers
  can rot if not enforced by a test the way `implements:` is; over-marking could
  bloat the generated docs. Because this is **Proposed**, none of that cost is
  incurred yet — the only risk today is the idea being forgotten, which this ADR
  prevents.
- **Provenance:** captured from `PORTABLE-PATTERNS.md` ("Emerging idea:
  marker-driven documentation (not yet built)") before that working note was
  deleted, so the idea survives the file.
