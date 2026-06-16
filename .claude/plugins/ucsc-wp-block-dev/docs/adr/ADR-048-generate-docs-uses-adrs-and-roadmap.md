---
title: "ADR-048: Generate docs uses ADRs and includes a roadmap"
status: Accepted
date: 2026-06-16
---

# ADR-048: Generate docs uses ADRs and includes a roadmap

## Status

Accepted

## Context

The generated guide and slide deck are maintainer-facing documentation
artifacts. They should not merely copy current README and deck content; they
should also reflect the plugin's recorded decisions. ADRs carry important
context about current policy, superseded behavior, and future study areas.

The slide deck also needs a forward-looking section so maintainers can see
where the plugin is heading, not only how it works today.

## Decision

The `generate-docs` reference must instruct maintainers to reconcile generated
documentation with `docs/adr/index.md` and the ADRs it references before
regenerating artifacts.

The maintainer-owned slide deck must include a future roadmap slide. Roadmap
items should be drawn from study ADRs, open-ended maintenance decisions, and
recent accepted direction-setting policies, with ADR numbers included when
practical.

## Consequences

- Generated docs remain aligned with current accepted decisions.
- Superseded ADR behavior is less likely to leak back into the guide or deck.
- The deck gives maintainers a concise future-work view grounded in ADRs.
