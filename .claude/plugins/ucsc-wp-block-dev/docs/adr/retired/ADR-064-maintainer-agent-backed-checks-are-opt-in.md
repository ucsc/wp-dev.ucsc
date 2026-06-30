---
title: "ADR-064: Agent-backed maintainer checks are opt-in, not default"
status: Superseded
date: 2026-06-16
---

# ADR-064: Agent-backed maintainer checks are opt-in, not default

## Status

Accepted

## Context

Two maintainer operations delegate to Anthropic `plugin-dev` agents:

- `validate` → `plugin-dev:plugin-validator`
- `review-skills` → `plugin-dev:skill-reviewer`

Both are genuinely valuable, but each spawns a subagent that starts cold and
consumes significant tokens — observed at ~9.9k (validator) and ~14.2k
(skill-reviewer) for a single run. Running them as part of routine maintenance,
or implying them on every maintainer entry, contradicts ADR-003 (single-agent
mode by default; subagents are a last resort) and surprises the user with large
token spend.

Previously `all` ran `validate` and `review-skills` alongside the cheap
deterministic checks, so the obvious "run everything" path silently spawned two
agents.

## Decision

The agent-backed checks are **opt-in only**:

1. `validate` and `review-skills` never run automatically. They run only when the
   user explicitly selects them.
2. They are **excluded from `all`.** `all` is the token-frugal deterministic
   suite: `test` then `check-references`.
3. When the user enters maintainer mode, **offer** `validate` and
   `review-skills` as available operations, but flag that each spawns a
   token-heavy Anthropic `plugin-dev` agent so the choice is informed.

## Consequences

- **Positive:** Routine maintenance stays cheap and predictable; large token
  spend happens only on explicit request. Consistent with ADR-003.
- **Positive:** The powerful agent reviews remain one keyword away when wanted.
- **Negative:** `all` no longer guarantees a full structural+quality sweep; a
  maintainer wanting the agent reviews must ask for them by name.
