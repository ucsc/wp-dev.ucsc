---
title: "ADR-003: Low token use and single-agent default"
status: Accepted
date: 2026-06-09
---

# ADR-003: Low token use and single-agent default

## Status

Accepted (consolidates ADR-058, 2026-06-24)

## Context

The maintainer values reliability and cost-efficiency. Verbose skills, redundant
file reads, and unnecessary subagent spawns all inflate token spend without
improving outcomes. This plugin's skills are loaded into context on every
relevant turn, so their size and the workflows they prescribe directly affect
cost. Subagents add the most: each spawned agent starts cold and re-derives
context the primary agent already holds, so delegation multiplies cost even when
the work is small. This decision folds in the former ADR-058 so the low-token
principle and the single-agent default live in one record.

## Decision

Low token use is a first-class design constraint for `ucsc-wp-block-dev`, and
**single-agent execution is the default operating mode** — not merely a
preference.

**Skill authoring:**

- Keep each `SKILL.md` lean and imperative; push detail into `references/` only
  when needed (progressive disclosure).
- Prefer scanner scripts and targeted commands over instructions that read whole
  files.

**Workflow behavior the skills prescribe:**

1. **Default to single-agent execution.** Run the work inline in the primary
   agent. A request being multi-part, "thorough," or open-ended is **not** a
   reason to delegate.
2. **Do not spawn subagents unless the user explicitly asks** (or names a
   specific agent type) — e.g. `plugin-dev:plugin-validator` in `maintainer`.
3. **Read narrowly.** Read only the specific files or line ranges needed; avoid
   broad directory scans or whole-file reads when a section suffices.
4. **Grep before reading** to locate relevant lines first.
5. **No background or parallel agent fan-out for token savings' sake** —
   parallelism trades tokens for wall-clock time; it does not reduce burn.
6. **Subagents are a true last resort**, justified only by genuinely parallel
   user-sanctioned workstreams, a long research survey that would pollute the
   primary context, or a specialized capability unavailable inline.
- Relay only the findings that matter; keep output terse.

## Consequences

- Skills stay small and cheap to load; maintenance favors the validator and test
  suite over manual file-by-file review.
- Lower token burn per session, faster responses, and predictable single-agent
  behavior.
- New skills must justify any subagent spawn or large reference file against this
  principle.
- **Negative:** occasional tasks that could have been parallelized run
  sequentially — a deliberate, generally worthwhile tradeoff.
