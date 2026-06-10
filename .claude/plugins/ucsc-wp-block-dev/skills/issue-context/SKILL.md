---
name: issue-context
description: Resolve optional Jira or user-supplied issue context for WordPress block development and normalize it into a compact implementation brief.
disable-model-invocation: false
argument-hint: "[target | issue summary | Jira key/URL]"
arguments: [target, input]
---

# Issue Context

## Universal Command Intake

Apply ADR-011: resolve the target block or app, natural-language issue summary, and optional Jira key/URL regardless of order. Ask one concise question only when none of those inputs identifies work to summarize.

Per ADR-021, accept the Jira reference as either a bare issue key (`[A-Z]+-\d+`, e.g. `WPM-97`) or a full Atlassian URL (e.g. `https://ucsc-its.atlassian.net/browse/WPM-97`). When given a URL, extract the key from the trailing `/browse/<KEY>` segment and work from that canonical key. A token that is neither a valid key nor a parseable Jira URL is part of the natural-language request, not a Jira key.

Use available Jira tooling when present. Otherwise accept pasted ticket details or the user's description; Jira is preferred for feature and fix work but never required.

Per ADR-025, when a Jira key/URL or Confluence URL is in use and Atlassian MCP tools are unavailable, mention once that the user can set up Atlassian MCP for direct access. Keep the reminder brief and non-blocking, continue with available context, and do not repeat it later in the task. Never install, configure, authenticate, or reload Atlassian MCP without explicit user approval; future automatic configuration must explain the change and obtain approval first.

Return:

- Target
- Source
- Issue type
- Goal
- Expected and actual behavior
- Acceptance criteria
- Constraints
- Likely PHP, JavaScript, REST, integration, or Docker surface
- Open questions

Explicit current user instructions take precedence when Jira details conflict.
