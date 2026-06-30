---
title: "ADR-051: Offer to automatically commit in addition to providing message text"
status: Superseded
date: 2026-06-15
---

# ADR-051: Offer to automatically commit in addition to providing message text

## Context

[ADR-029](ADR-029-develop-fix-and-develop-offer-conventional-commit-message.md) stated that workflows should only offer commit message text and should default to manual check-ins without offering to automatically execute `git` operations unless explicitly requested. However, offering to automatically stage and commit the changes improves the developer experience and saves time.

## Decision

This ADR supersedes ADR-029.

After every successfully completed fix, feature, or review of changes, the plugin should:
1. Provide the suggested Conventional Commit message text.
2. Explicitly offer to automatically stage and commit the changes for the user using the suggested message.

The workflow must wait for the user to explicitly accept the offer before running `git add`, `git commit`, or equivalent operations.

Generated messages follow ADR-023, including a Jira footer when a Jira key is known.

## Consequences

- **Positive:** Reduces friction and manual effort by allowing the assistant to handle the Git operations upon approval.
- **Negative:** Reverses the "manual check-in is the strict default" rule, placing the responsibility on the assistant to run Git commands correctly.
