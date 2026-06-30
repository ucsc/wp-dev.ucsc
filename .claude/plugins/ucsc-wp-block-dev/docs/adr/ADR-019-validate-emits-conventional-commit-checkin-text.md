---
title: "ADR-019: Test mode emits a Jira title and conventional-commit description for check-in"
status: Accepted
date: 2026-06-10
---

# ADR-019: Test mode emits check-in text in conventional-commit syntax

## Context

After generating or running tests, the maintainer still has to hand-write a Jira summary and a commit message for the check-in. The work the `test` skill just did already contains everything those need — the target block, the layer exercised, and the behaviors covered.

## Decision

When `test` adds or meaningfully changes test coverage, it concludes by emitting ready-to-paste check-in text:

1. A **Jira title** — a short imperative summary of the test work.
2. A **description** formatted as a [Conventional Commit](https://www.conventionalcommits.org/): a `type(scope): subject` header followed by a body explaining what is covered and why.

Conventions:

- `type` is normally `test`; use `fix`/`feat` only when the same change also alters block behavior.
- `scope` is the kebab-case target block (e.g. `class-schedule`).
- The body names the layer (PHP/Jest/Docker/Browser), the behaviors covered, and any runtime caveats (e.g. "runs in the Docker WP container").

This output is the closing step of test mode; it does not gate the run and is skipped when no coverage changed (a plain test execution). Jira remains optional per [ADR-008](retired/ADR-008-develop-prefer-jira-id-for-fix-and-develop.md) — when a Jira key is known it is referenced in the footer.

## Consequences

Check-in text is consistent and derived from the actual test work, so the maintainer can paste a Jira summary and a conventional-commit message without re-deriving context.
