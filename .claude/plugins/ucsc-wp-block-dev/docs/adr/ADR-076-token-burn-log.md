---
title: "ADR-076: track token-heavy operations in a usage log for retrospective review"
status: Accepted
date: 2026-06-17
related: ["ADR-003", "ADR-059", "ADR-064", "ADR-075"]
---

# ADR-076: track token-heavy operations in a usage log

## Status

Accepted

## Context

ADR-003 and ADR-075 establish lean token spend as a default. ADR-064 gates
`validate` and `review-skills` as explicit opt-in operations because each
spawns a token-heavy Anthropic plugin-dev agent (~10k and ~14k tokens
respectively).

Currently there is no record of when these operations run or what they cost.
The retrospective skill (ADR-059) is where session lessons are captured, but
there is no signal to prompt the question "was this session more expensive than
it needed to be?"

A lightweight log creates that signal without imposing overhead on low-cost
operations.

## Decision

When running any of the following token-heavy operations, append a one-line
entry to `.claude/plugins/ucsc-wp-block-dev/logs/token-usage.log`:

| Operation | Approximate token cost | When to log |
|---|---|---|
| `validate` (plugin-dev:plugin-validator agent) | ~10k | After launch |
| `review-skills` (plugin-dev:skill-reviewer agent) | ~14k | After launch |
| Future approved multi-agent operations | varies | At ADR time |

**Log format** (one line per entry):

```
YYYY-MM-DD HH:MM  <operation>  <notes>
```

Example:
```
2026-06-17 14:32  validate       post-refactor structure check
2026-06-17 15:01  review-skills  after adding calendar-feed and ucsc-events targets
```

The log file is append-only and human-readable. It is checked into the
repository so retrospective sessions have a persistent record.

**During retrospective** (ADR-059): review the log entries since the last
retrospective. For each entry ask: was this run worth the cost? Could a
structural test or script have caught the issue at lower cost? Capture insights
as skill improvements or script additions.

## Consequences

- Token-heavy operations leave a visible trace.
- Retrospective sessions have a concrete artifact to anchor the cost-reduction
  conversation.
- Low-cost inline operations (file edits, script runs, test runs) are not
  logged — the log stays quiet unless agent operations are actually run.
