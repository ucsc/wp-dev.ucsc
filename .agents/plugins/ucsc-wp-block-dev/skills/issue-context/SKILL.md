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

Use available Jira tooling when present. Otherwise accept pasted ticket details or the user's description; Jira is preferred for feature and fix work but never required.

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
