---
title: "ADR-023: Always favor Conventional Commits for commit messages"
status: Accepted
date: 2026-06-10
---

# ADR-023: Always favor Conventional Commits

## Context

[ADR-019](ADR-019-test-emits-conventional-commit-checkin-text.md) established Conventional Commit output for test-mode check-in text, but commit messages are produced by any workflow that lands a change (`develop`, `fix`, `review` follow-ups, maintainer edits). A single, consistent commit convention keeps history scannable and tool-friendly.

## Decision

Every commit message this plugin generates or suggests follows the [Conventional Commits](https://www.conventionalcommits.org/) format by default: a `type(scope): subject` header, optional body, and optional footer.

- `type` reflects the change: `feat`, `fix`, `test`, `docs`, `refactor`, `chore`, etc.
- `scope` is the kebab-case target (block, skill, or area), when one applies.
- The subject is imperative and concise; details go in the body.
- A known Jira key is referenced in a footer (`Refs: WPM-97`), not stitched into the subject, per [ADR-021](ADR-021-accept-jira-id-or-url-in-arguments.md).

This generalizes ADR-019 from test mode to all commit-message generation. Deviate only when the user explicitly asks for a different format.

## Consequences

Commit history stays uniform and machine-parseable across every workflow, and check-in text from `test`, `develop`, and `fix` shares one convention.
