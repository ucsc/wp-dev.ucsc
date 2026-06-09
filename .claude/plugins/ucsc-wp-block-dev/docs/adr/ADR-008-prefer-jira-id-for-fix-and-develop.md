---
title: "ADR-008: Prefer a Jira ID for fix and develop work"
status: Accepted
date: 2026-06-09
---

# ADR-008: Prefer a Jira ID for fix and develop work

## Status

Accepted

## Context

Bug fixes and feature work are often tracked in Jira. Capturing the Jira ID at the start provides authoritative requirements, acceptance criteria, and traceability between the implementation and its ticket.

Not every request has a Jira ticket, and Jira availability must not become an unnecessary blocker.

## Decision

The `fix` and `develop` skills must prefer obtaining a Jira ID from the user before investigation or implementation.

- When the user supplies a Jira ID, preserve it as task context and use the ticket details when available.
- When no Jira ID is supplied, request it during the initial clarification.
- Combine the Jira request with any other required clarification instead of asking in a separate turn.
- The user may answer that there is no Jira ticket or choose to skip it.
- A missing Jira ID must not block work once the concrete problem or feature requirements are sufficient.
- If no Jira ID is captured, the prompt may repeat when the fix or feature phase is completed. See ADR-010.

For `fix`, this preference operates alongside ADR-007: a Jira ID can provide the concrete problem, but an ID alone is not sufficient unless its ticket details establish the symptom or expected-versus-actual behavior.

## Consequences

- Fixes and features are more consistently tied to their source requirements.
- Initial clarification remains concise and avoids multiple question rounds.
- Work can still proceed for untracked requests.
