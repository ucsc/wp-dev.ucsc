---
title: "ADR-049: Perform Retrospective After Tasks"
status: Accepted
date: 2026-06-15
---

# ADR-049: Perform Retrospective After Tasks

## Context

During continuous use of the `ucsc-wp-block-dev` plugin, the AI assistant learns new patterns, edge cases, and domain logic about the `wp-dev.ucsc` app and Gutenberg blocks. If these insights are only kept in the active session's context window, they are lost across different tasks or sessions.

## Decision

We will always perform a retrospective at the conclusion of every `fix`, `feature`, or `review` workflow.

During this retrospective:
1. Identify any new domain rules, common pitfalls, architecture patterns, or test strategies discovered during the task.
2. Save these lessons learned to the appropriate plugin skill reference documents (such as `develop/references/domain/blocks.md` or directly inside the relevant `SKILL.md`).

## Consequences

- **Positive:** Institutional knowledge is progressively formalized in the plugin's documentation and skill instructions, allowing the AI to automatically apply past lessons to future tasks without repeating mistakes.
- **Negative:** Slightly increases the token cost and time at the end of every task to perform the write operations.
