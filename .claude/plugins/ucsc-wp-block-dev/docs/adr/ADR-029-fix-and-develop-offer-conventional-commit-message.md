---
title: "ADR-029: Fix and develop offer a Conventional Commit message without Git operations"
status: Accepted
date: 2026-06-10
---

# ADR-029: Fix and develop offer a Conventional Commit message only

## Context

[ADR-023](ADR-023-always-favor-conventional-commits.md) defines the format for commit messages the plugin generates, but it does not require implementation workflows to offer one at completion or distinguish message generation from executing Git commands.

## Decision

After a completed `fix` or `develop` flow, offer to generate a Conventional Commit message for the verified change. Generate the message only when the user accepts the offer.

The offer is for commit-message text only. The workflow must not run `git add`, `git commit`, `git push`, or any equivalent staging, commit, or push operation. If the user separately requests a Git operation in a future interaction, that request is outside this ADR and must follow the active safety and approval rules.

Generated messages follow ADR-023, including a Jira footer when a Jira key is known.

## Consequences

Users receive a consistent handoff from implementation to check-in without the plugin changing repository history or remote state.
