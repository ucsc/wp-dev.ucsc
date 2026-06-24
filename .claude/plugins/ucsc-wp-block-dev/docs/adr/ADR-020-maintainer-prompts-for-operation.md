---
title: "ADR-020: Maintainer mode prompts for the operation instead of auto-running"
status: Accepted
date: 2026-06-10
---

# ADR-020: Maintainer prompts for operation, does not auto-launch

## Context

A bare `maintainer` command previously implied the `all` health check, which immediately launched the `plugin-dev:plugin-validator` and `plugin-dev:skill-reviewer` agents. Those agent runs are slow and token-heavy, and the user often wants only one operation (or a different one) than `all`. Starting them unprompted spends budget the user did not ask for and conflicts with ADR-003.

## Decision

When the user enters maintainer mode **without an explicit operation**, the skill first prompts the user for what to do and offers the operations as options: `validate`, `test`, `review-skills`, `publish-slides`, and `all`. It runs the chosen operation only after the user selects.

It must **not** launch directly into any plugin-dev agent (`plugin-validator`, `skill-reviewer`) or other operation before the user chooses.

When the user already names an operation (e.g. `maintainer test`, `maintainer validate`), the skill honors it directly without prompting. This refines the intake gate of [ADR-011](retired/ADR-011-maintainer-universal-command-intake.md) for maintainer mode and upholds the low-token-use principle of [ADR-003](ADR-003-maintainer-low-token-use.md).

## Consequences

Maintainer mode starts with a cheap prompt rather than a heavyweight default run. The user controls which operations execute, avoiding unwanted validator/reviewer agent launches, while explicit invocations still run immediately.
