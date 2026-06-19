---
title: "ADR-025: Suggest Atlassian MCP when Atlassian references are in use"
status: Accepted
date: 2026-06-10
---

# ADR-025: Suggest Atlassian MCP for Atlassian references

## Context

Users may supply Jira issue keys or URLs, Confluence page URLs, or Bitbucket pull-request URLs while the Atlassian MCP integration is unavailable. The plugin can continue from pasted details or other available tooling, but the user may benefit from knowing that Atlassian MCP can provide direct access to this context.

A setup reminder should remain helpful rather than becoming a repeated interruption. Future plugin versions may be able to configure the integration, but changing MCP configuration is an external setup action that requires user approval.

## Decision

When a Jira, Confluence, or Bitbucket reference is actively used and Atlassian MCP tools are unavailable, the handling skill should include one brief, non-blocking reminder that the user can set up Atlassian MCP for direct access.

- Mention the option once per task or conversation context; do not repeat it during later phases or completion summaries.
- Continue with pasted details, the user's summary, or other available tooling. Missing Atlassian MCP must not block otherwise actionable work.
- Do not show the reminder when Atlassian MCP is already available.
- Do not prompt users to install Atlassian MCP when no Atlassian reference is in use.
- Do not automatically install, configure, authenticate, or reload MCP integrations.

Future automatic configuration may be added, but it must first explain the proposed configuration change and obtain explicit user approval.

## Consequences

Users discover the direct Atlassian integration at the point where it is relevant without being nagged. Existing fallback workflows remain usable, and MCP configuration stays an explicit user-controlled action.
