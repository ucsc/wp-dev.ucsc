---
title: "ADR-003: Always prefer low token use"
status: Accepted
date: 2026-06-09
---

# ADR-003: Always prefer low token use

## Status

Accepted

## Context

The maintainer values reliability and cost-efficiency. Verbose skills, redundant file reads, and unnecessary subagent spawns all inflate token spend without improving outcomes. This plugin's skills are loaded into context on every relevant turn, so their size and the workflows they prescribe directly affect cost.

## Decision

Low token use is a first-class design constraint for `ucsc-wp-block-dev`.

**Skill authoring:**

- Keep each `SKILL.md` lean and imperative; push detail into `references/` only when needed (progressive disclosure).
- Prefer scanner scripts and targeted commands over instructions that read whole files.

**Workflow behavior the skills prescribe:**

- Do inline work with direct tool calls; only launch a subagent when the task genuinely cannot be done inline (e.g. `plugin-dev:plugin-validator` in the `maintainer` skill).
- Avoid parallel agents, redundant re-reads, and exploratory searches.
- Relay only the findings that matter; keep output terse.

## Consequences

- Skills stay small and cheap to load.
- Maintenance (`maintainer` skill) favors the validator and test suite over manual file-by-file review.
- New skills must justify any subagent spawn or large reference file against this principle.
