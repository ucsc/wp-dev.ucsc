---
title: "ADR-009: Fix and develop require a target and work description"
status: Accepted
date: 2026-06-09
---

# ADR-009: Fix and develop require a target and work description

## Status

Accepted (consolidates ADR-007, ADR-008, ADR-010 2026-06-29)

## Context

Fix and feature requests need two distinct pieces of information. The agent must know where the work belongs and what outcome the user wants. Either one without the other encourages investigation of the wrong block, GUI, or app, or implementation based on an assumed requirement.

The requested work does not need to arrive as formal acceptance criteria. A plain-language description is sufficient.

## Decision

Before investigation or implementation, both `fix` and `develop` must secure these two required inputs from the user:

1. **Target** — the block, GUI, or app being worked on.
2. **Work description** — the thing to fix or the feature to add. A plain-language description is sufficient.

If either input is missing, ask one concise clarification that requests all missing required inputs and optionally the preferred Jira ID. Wait for the user's answer before using tools or inspecting the codebase.

A Jira ID remains preferred under ADR-008, but it is optional and does not replace either required input unless the available ticket details clearly identify both the target and work description.

For fixes, this decision refines ADR-007: error messages, logs, failing tests, and expected-versus-actual behavior are useful forms of description, but they are not required when the user's plain-language description clearly states what needs fixing.

## Fix intake gate (absorbed from ADR-007)

For `fix`, a target alone (e.g. "fix course catalog") is not sufficient. Before any
investigation, `fix` must obtain a concrete problem: a symptom or broken behavior,
an error message or log output, a failing test, or expected-vs-actual behavior.
Until this gate is satisfied, `fix` must not inspect source files, logs, git
history, browser state, builds, or tests.

## Jira preference (absorbed from ADR-008)

Prompt for a Jira ID upfront during the initial clarification, combined with any
other missing-input question (not as a separate turn). When a Jira ID is supplied,
preserve it as task context and use the ticket when available via Atlassian MCP.
When Atlassian MCP is unavailable, ask the user to paste or summarize relevant
requirements. A missing Jira ID must not block work when the target and description
are sufficient.

## Jira repeat at phase completion (absorbed from ADR-010)

When a fix or develop phase is completed and no Jira ID has been captured, the
skill may repeat the Jira prompt alongside the completion summary. Do not repeat
it when an ID is already known. The repeat is optional and non-blocking; completed
work remains complete without an ID.

## Consequences

- Fix and feature work begins with a named target and stated outcome.
- Plain-language requests are accepted without demanding formal diagnostics or acceptance criteria.
- Fix requires a concrete problem before investigation begins; broad targets get one clarifying question.
- Jira is preferred context gathered upfront but never a blocker; it may be collected at completion if missed.
- Clarification is consolidated into one question when information is missing.
- Investigation and implementation do not begin from an ambiguous target or requirement.
