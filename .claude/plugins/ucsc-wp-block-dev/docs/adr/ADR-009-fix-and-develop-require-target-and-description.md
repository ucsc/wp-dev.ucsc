---
title: "ADR-009: Fix and develop require a target and work description"
status: Accepted
date: 2026-06-09
---

# ADR-009: Fix and develop require a target and work description

## Status

Accepted

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

## Consequences

- Fix and feature work begins with a named target and stated outcome.
- Plain-language requests are accepted without demanding formal diagnostics or acceptance criteria.
- Clarification is consolidated into one question when information is missing.
- Investigation and implementation do not begin from an ambiguous target or requirement.
