---
title: "ADR-075: prefer single-agent mode — avoid multi-agent pipelines unless the task requires parallelism"
status: Accepted
date: 2026-06-17
supersedes: []
related: ["ADR-003", "ADR-064"]
---

# ADR-075: prefer single-agent mode

## Status

Accepted

## Context

ADR-003 establishes lean token spend (and the single-agent default) as a
principle, applied to the `hub` skill by mandating a static inventory (no
filesystem scan, no agent spawn). ADR-064 protected `validate` and `review-skills` from running as part
of `all` because each spawns a token-heavy Anthropic plugin-dev agent.

These rules are correct but piecemeal — each ADR defends one entry point.
Sessions and contributors still sometimes default to spinning up subagents for
work that a single inline pass can handle.

The user has explicitly asked that single-agent mode be treated as a **sticky,
plugin-wide default** — not just a guideline for specific operations.

## Decision

Single-agent mode is the default for every operation in this plugin.

**Before spawning an agent, ask: can this be done in a single inline pass?**

- Reading files, editing files, running scripts, writing ADRs, updating tests —
  these are single-agent tasks. Do them inline.
- Operations already guarded by ADR-064 (`validate`, `review-skills`) are the
  only approved multi-agent operations. They remain opt-in only.
- New operations that require genuine parallelism or isolation may spawn an
  agent, but that choice must be documented (add an ADR or update this one).

The check before any spawn: "Is this task truly parallel or isolated, or am I
reaching for an agent because it feels cleaner?" If the honest answer is the
latter, do it inline.

## Consequences

- All skill operations default to single-agent.
- Agent spawns outside the approved list require explicit justification.
- Token spend stays low by default across all workflows.
- Contributors adding new operations should design them for single-agent
  execution and note the exception if an agent is genuinely necessary.
