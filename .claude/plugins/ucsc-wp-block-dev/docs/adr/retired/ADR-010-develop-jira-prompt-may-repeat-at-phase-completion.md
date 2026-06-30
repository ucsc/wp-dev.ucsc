---
title: "ADR-010: Jira prompt may repeat at phase completion"
status: Superseded
date: 2026-06-09
---

# ADR-010: Jira prompt may repeat at phase completion

## Status

Accepted

## Context

A Jira ID is preferred during initial fix and feature intake under ADR-008, but a ticket may not exist or be known at that point. The user may create or locate the ticket while work is underway.

## Decision

When a `fix` or `develop` phase is completed and no Jira ID has been captured, the skill may repeat the Jira prompt.

- Phase completion means the requested implementation and its applicable validation are complete.
- The repeated prompt should accompany the completion summary rather than interrupt implementation.
- Do not repeat the prompt when a Jira ID is already known.
- The user may provide an ID, say there is no ticket, or skip it.
- The repeated Jira prompt is optional and non-blocking. Completed work remains complete without an ID.

## Consequences

- Work can be associated with a Jira ticket created or discovered during implementation.
- Users are not repeatedly prompted after an ID is already known.
- Jira remains preferred context rather than a completion requirement.
