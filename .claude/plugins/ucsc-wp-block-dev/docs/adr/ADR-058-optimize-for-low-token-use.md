---
title: "ADR-058: Optimize for low token use, prefer single agent"
status: Accepted
date: 2026-06-15
---

# ADR-058: Optimize for low token use, prefer single agent

## Context

Subagents consume additional tokens and add latency. Many tasks that could be delegated to a subagent can be performed more efficiently inline by the primary agent using targeted file reads and commands rather than broad delegation.

## Decision

The AI assistant must always optimize for minimal token consumption:

1. **Prefer single-agent execution.** Do not spawn subagents for tasks that can be completed with a few targeted reads and commands inline.
2. **Read narrowly.** Read only the specific files or line ranges needed to answer the question. Avoid broad directory scans or reading entire files when a section suffices.
3. **Grep before reading.** Use `grep_search` or `rg` to locate relevant lines before opening a file.
4. **Subagents are a last resort.** Only invoke a subagent when the task requires genuinely parallel workstreams, a long research survey that would pollute the primary context, or a specialized agent capability unavailable inline.

## Consequences

- **Positive:** Lower token burn per session, faster responses, less context window pressure.
- **Negative:** Occasional tasks that could have been parallelized will run sequentially. The tradeoff is generally worthwhile.
