---
title: "ADR-027: Study GitHub and Atlassian MCP token cost"
status: Accepted
date: 2026-06-10
---

# ADR-027: Study GitHub and Atlassian MCP token cost

## Context

GitHub and Atlassian context is common in block-development work. Direct MCP tools may retrieve pull requests, Jira issues, Confluence pages, and Bitbucket data with fewer searches and less pasted content than CLI, API, browser, or user-supplied fallbacks.

Starting both MCP servers automatically may still increase total cost. Tool names, descriptions, schemas, startup messages, authentication failures, and discovery can consume context or time in every session, including sessions that never use either service. The correct comparison is total task cost, not only the number of retrieval calls.

## Decision

Study whether GitHub and Atlassian MCP reduce total token use before enabling either server by default. Compare three configurations:

1. **Fallback only** — MCP disabled; use `gh`, GitHub API, pasted Atlassian details, browser access, or other existing fallbacks.
2. **On demand** — start or enable the relevant MCP only after the task contains a GitHub, Jira, Confluence, or Bitbucket reference and the user approves any configuration change.
3. **Always on** — start both GitHub and Atlassian MCP at session initialization.

Measure GitHub and Atlassian independently as well as together. A result for one server must not be assumed to apply to the other.

## Benchmark Tasks

Use repeatable tasks that include:

1. Review a GitHub pull request and inspect changed files, checks, and discussion.
2. Resolve a Jira issue into target, requirements, and acceptance criteria.
3. Read a Confluence page linked from an issue.
4. Review a Bitbucket pull request with related Jira context.
5. Complete a local-only fix with no external-service reference.
6. Complete a mixed task using both GitHub and Atlassian context.

The local-only case measures the tax imposed on sessions that do not benefit from MCP.

## Metrics

For each configuration and task, record:

- always-on and on-invoke tool-schema tokens when available;
- total input and output tokens;
- startup and authentication time;
- tool discovery and selection calls;
- retrieval calls, retries, and failures;
- amount of issue, page, PR, diff, or log content returned;
- manual parsing, follow-up searches, and repeated retrieval;
- whether required context was complete and correctly attributed;
- task completion, review accuracy, and user clarification turns.

Normalize or cap retrieved payloads where tools allow it. A tool that returns an entire issue history or large diff may cost more than a targeted CLI or API request even if it uses fewer calls.

## Evaluation

- Compare median total tokens and completion time across repeated runs.
- Separate the fixed session-start cost from task-specific retrieval cost.
- Calculate the approximate number of relevant tasks needed to recover any always-on startup tax.
- Prefer on-demand activation when savings occur only in external-context tasks.
- Prefer always-on activation only when the measured savings across the expected task mix exceed startup overhead without reducing reliability.
- Retain fallback-only operation when MCP adds cost, instability, or incomplete access.

## Guardrails

- Do not configure, authenticate, enable, or reload MCP servers without explicit user approval.
- Do not include credentials, tokens, or private Atlassian content in benchmark artifacts.
- Use equivalent task inputs and acceptance criteria across configurations.
- Do not count token savings that come from omitting required context or validation.
- Do not treat fewer tool calls as equivalent to fewer tokens.
- Preserve the non-blocking Atlassian setup reminder from ADR-025 while the study is underway.

## Consequences

The plugin does not start GitHub or Atlassian MCP automatically at session initialization. ADR-028 adopts just-in-time activation when the expected token savings justify it; this study supplies and refines the measurements used by that decision. Configuration and disruptive environment changes still require explicit user approval.
