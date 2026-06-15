---
title: "ADR-039: Use a skills-first surface with map as the entry point"
status: Accepted
date: 2026-06-15
---

# ADR-039: Use a skills-first surface with map as the entry point

## Status

Accepted

## Context

The plugin described reusable workflows as commands and maintained separate
`start` and `menu` routing skills. That language tied the canonical guidance to
one host's invocation syntax and duplicated routing behavior. The workflows are
already implemented as Agent Skills and should remain portable across hosts.

## Decision

Use skills as the canonical public surface:

- Replace `start` with `map`, the single app-aware skill router and inventory.
- Retire `menu`; `map` serves both initial and mid-session routing.
- Refer to peer workflows by skill name rather than slash-command syntax.
- Fold the concise capability overview into `map`; retire `setup` as a separate
  skill.
- Keep host-specific invocation syntax outside canonical skill instructions
  unless an adapter requires it.

`map` parses the target, natural-language request, and optional Jira context,
identifies the active WordPress app, and routes by intent. It may pair a
workflow skill with hidden domain guidance and a block-specific reference.

## Consequences

- The canonical workflows are portable to Codex, Claude Code, and other Agent
  Skills-compatible hosts.
- There is one routing inventory instead of overlapping start and menu skills.
- The live plugin inventory remains 14 skills as `map` and `feature` replace
  `start`, `menu`, and `setup`.
- Host adapters may still expose commands or UI actions without changing the
  skill definitions.
