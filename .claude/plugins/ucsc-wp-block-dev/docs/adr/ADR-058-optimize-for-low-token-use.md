---
title: "ADR-058: Optimize for low token use, single-agent mode by default"
status: Accepted
date: 2026-06-15
---

# ADR-058: Optimize for low token use, single-agent mode by default

## Context

Subagents consume additional tokens and add latency. Each spawned agent starts
cold and re-derives context the primary agent already holds, so delegation
multiplies token cost even when the work itself is small. Many tasks that could
be delegated to a subagent can be performed more efficiently inline by the
primary agent using targeted file reads and commands rather than broad
delegation. Single-agent operation is therefore the default mode for this
plugin, not merely a preference.

## Decision

**Single-agent mode is the default and expected operating mode.** The assistant
must always optimize for minimal token consumption:

1. **Default to single-agent execution.** Run the work inline in the primary
   agent. A request being multi-part, "thorough," or open-ended is **not** a
   reason to delegate — handle it inline with targeted tools.
2. **Do not spawn subagents unless the user explicitly asks** for one (or names a
   specific agent type). Absent that, single-agent execution is mandatory, not
   optional.
3. **Read narrowly.** Read only the specific files or line ranges needed. Avoid
   broad directory scans or reading entire files when a section suffices.
4. **Grep before reading.** Use `grep_search` or `rg` to locate relevant lines
   before opening a file.
5. **Never use background or parallel agent fan-out for token savings' sake.**
   Parallelism trades tokens for wall-clock time; it does not reduce burn and is
   disfavored here.
6. **Subagents are a true last resort.** Even when permitted, justify the spawn:
   only when the task requires genuinely parallel workstreams that the user has
   sanctioned, a long research survey that would otherwise pollute the primary
   context, or a specialized agent capability unavailable inline.

This applies to the plugin's own skills as well: design new skills and workflows
to run single-agent by default rather than orchestrating subagents (see also the
maintainer skill's low-token guidance).

## Consequences

- **Positive:** Lower token burn per session, faster responses, less context
  window pressure, and predictable single-agent behavior.
- **Negative:** Occasional tasks that could have been parallelized will run
  sequentially. The tradeoff is deliberate and generally worthwhile.
