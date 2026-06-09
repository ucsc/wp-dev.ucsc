---
title: "ADR-059: Offer a retrospective for skill and script enrichment"
status: Accepted
date: 2026-06-16
---

# ADR-059: Offer a retrospective for skill and script enrichment

## Context

ADR-049 directed the assistant to *always* perform a retrospective at the end of
every `fix`, `feature`, or `review` workflow. In practice an unconditional
write-back at the end of every task adds token cost and time even when nothing
new was learned, which is at odds with ADR-003 (optimize for low token use).
The plugin has also converged on an *offer* pattern for end-of-task actions
rather than acting unilaterally — see ADR-051 (offer to commit) and ADR-054
(offer to create pull requests).

Separately, lessons learned are not limited to skill documentation. Block
development frequently improves the plugin's own helper **scripts** (build,
launch, verification, and maintenance helpers), and those improvements deserve
to be captured alongside skill reference updates.

## Decision

After completing a `fix`, `feature`, or `review` activity, the assistant
**offers** a retrospective rather than running one unconditionally. When the
user accepts, the retrospective captures lessons learned into **both**:

1. **Skills** — the appropriate skill reference documents (such as
   `develop/references/domain/blocks.md`) or the relevant `SKILL.md`.
2. **Scripts** — the plugin's helper scripts, when the session surfaced a fix,
   hardening, or new capability for a build, launch, verification, or
   maintenance script.

If the session produced no durable lesson, the assistant may note that and skip
the retrospective. The `retrospective` skill remains the mechanism that performs
the enrichment once offered and accepted.

This supersedes ADR-049.

## Consequences

- **Positive:** End-of-task overhead is incurred only when there is something
  worth saving, aligning with ADR-003.
- **Positive:** Script improvements are formalized, not just skill docs, so the
  plugin's tooling improves alongside its knowledge base.
- **Positive:** Consistent with the established offer pattern (ADR-051, ADR-054).
- **Negative:** Relying on an offer means a user who declines may lose a lesson
  that an unconditional retrospective would have captured.
