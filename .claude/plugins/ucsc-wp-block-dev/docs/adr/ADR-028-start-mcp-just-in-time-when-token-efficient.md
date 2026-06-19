---
title: "ADR-028: Start MCP just in time when token-efficient"
status: Accepted
date: 2026-06-10
---

# ADR-028: Start MCP just in time when token-efficient

## Context

`ucsc-wp-block-dev` is a multi-purpose plugin. Many sessions operate only on local source, tests, Docker, or browser behavior and never need GitHub, Jira, Confluence, or Bitbucket. Loading every external integration at startup would impose tool-schema, startup, discovery, and possible authentication costs on unrelated work.

ADR-027 establishes how to measure the cost of GitHub and Atlassian MCP. The operating policy should favor just-in-time access while retaining cheaper CLI, API, browser, and pasted-context fallbacks.

## Decision

Do not start GitHub or Atlassian MCP by default for every plugin session. Activate only the relevant MCP just in time when the current task uses that service and MCP is expected to reduce total token use or materially improve context accuracy.

### Selection

- Use **GitHub MCP** for GitHub PR, issue, check, review-discussion, or repository tasks when structured retrieval avoids repeated API, CLI, browser, or diff parsing.
- Use **Atlassian MCP** for Jira, Confluence, or Bitbucket tasks when direct linked context avoids pasted details, repeated page retrieval, or manual cross-product searches.
- Start both only for a task that genuinely requires both ecosystems.
- Prefer an existing lightweight fallback for a single bounded lookup when starting MCP would cost more than the retrieval it replaces.
- Do not activate either MCP for local-only development, testing, Docker, or browser work.

### Just-in-time behavior

- When the relevant MCP is already available in the current session, use it directly when it is the lower-cost suitable tool.
- When it is configured but not loaded and activation requires a restart or forced plugin reload, briefly explain the benefit and session impact, then obtain explicit approval.
- When it is not configured or authenticated, offer setup once when relevant and obtain explicit approval before installation, configuration, or authentication.
- If approval is declined or activation fails, continue with available fallbacks without blocking the task or repeating the prompt.
- Activate only the service needed by the current task; do not opportunistically start the other service.

### Token-efficiency decision

Use available measurements from ADR-027. Until enough benchmark data exists, prefer MCP when the task needs multiple related objects, linked context, comments, checks, histories, or repeated queries. Prefer fallbacks for one small public lookup with a known direct command or endpoint.

The decision is based on estimated **total task tokens**, including tool schemas, returned payloads, retries, and manual parsing. Fewer tool calls alone are not sufficient.

## Guardrails

- Preserve explicit user tool preferences.
- Never expose credentials or private retrieved content outside the task.
- Request bounded fields and payloads when the MCP supports filtering.
- Do not reload solely for a speculative future need.
- Do not count omitted requirements, discussion, checks, or validation as token savings.
- Reevaluate the threshold as MCP implementations and tool-schema costs change.

## Consequences

The plugin remains lightweight for its many local and non-Atlassian/GitHub workflows. External integrations become available at the point of need, and only when their expected retrieval savings justify their session cost. Users retain control over configuration and disruptive reloads, while already available MCP tools can be used without unnecessary setup prompts.
