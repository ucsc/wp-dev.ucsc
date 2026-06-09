---
title: "ADR-077: always consider lessons learned and token-reduction opportunities via scripts and skill improvements"
status: Accepted
date: 2026-06-17
related: ["ADR-003", "ADR-059", "ADR-075", "ADR-076"]
---

# ADR-077: lessons learned → scripts and skill improvements

## Status

Accepted

## Context

ADR-059 introduced the `retrospective` skill for capturing session lessons into
skill and script files. ADR-075 established single-agent mode as the default.
ADR-076 logs token-heavy operations.

The missing link is an explicit prompt: during every retrospective (and at
natural session end points), ask whether any pattern in the session should be
captured as a script or skill improvement — not just as a prose lesson.

Scripts and skills are first-class delivery mechanisms for lessons learned:

- A **script** automates a manual step so future sessions skip it entirely.
- A **skill improvement** encodes a pattern so future AI-assisted sessions
  handle it correctly without needing to rediscover it.

Without this prompt, lessons stay as prose notes and the same manual work
recurs in future sessions.

## Decision

At the end of every session that invokes `retrospective`, explicitly ask:

> "Are there any workflows from this session that could be turned into a script
> or skill improvement to reduce manual steps or token burn next time?"

Evaluate the session against three questions:

1. **Script candidate:** Was there a multi-step manual operation (e.g. a file
   reorganization, a bulk link-update, a survey run) that could be automated?
   If yes, write a script under `skills/<skill>/scripts/` and link it from
   `SKILL.md`.

2. **Skill improvement candidate:** Was there guidance the AI re-derived from
   scratch that should be in a reference file or a `SKILL.md` section? If yes,
   add it.

3. **Token-reduction candidate:** Did a token-heavy operation (see ADR-076)
   surface something that a cheaper structural test could have caught? If yes,
   add or improve the test and update the test suite.

None of these are required — if the session was routine and nothing new was
learned, say so and close. The goal is the prompt, not ceremony.

## Consequences

- Retrospective sessions produce actionable artifacts, not just prose.
- Repeated manual patterns become scripts; rediscovered guidance becomes skill
  text.
- Token-heavy operations feed into cheaper automated checks over time.
- The retrospective skill should include the three questions above in its
  closing checklist.
