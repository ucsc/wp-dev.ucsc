---
title: "ADR-034: Defer GitHub and Atlassian MCP login until needed"
status: Superseded
date: 2026-06-12
---

# ADR-034: Defer GitHub and Atlassian MCP login until needed

## Context

The GitHub and Atlassian MCP integrations are useful for retrieving pull requests, issues, checks, Jira tickets, Confluence pages, and related context. However, starting either integration during plugin or session startup can trigger connection, authentication, or login work before the current task has established a need for that service.

ADR-028 already selects just-in-time MCP activation to avoid unnecessary startup and token costs. This decision makes the authentication boundary explicit.

## Decision

Do not start, connect, authenticate, or log in to GitHub or Atlassian MCP during plugin or session startup.

- Keep both integrations inactive until the current task needs GitHub or Atlassian context.
- Start only the integration required by the task; do not start both automatically.
- If the required integration is not authenticated, request login or setup only at that point and obtain any required user approval.
- Continue with an available fallback when activation is unnecessary, declined, or unsuccessful.
- Do not perform speculative login for possible later work in the session.

This is the current operating policy, not a permanent rejection of either MCP integration. Reevaluate it as startup behavior, authentication UX, reliability, and token cost change.

## Consequences

- Local-only sessions avoid unrelated GitHub or Atlassian startup and login prompts.
- External context remains available just in time when a task needs it.
- The first relevant operation may incur connection or authentication latency.
- A future ADR may replace this policy if always-on startup becomes sufficiently low-cost and non-disruptive.
