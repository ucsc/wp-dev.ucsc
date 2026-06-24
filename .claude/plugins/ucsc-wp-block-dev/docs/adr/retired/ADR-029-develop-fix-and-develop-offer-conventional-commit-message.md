---
title: "ADR-029: Offer Conventional Commit syntax after fixes, features, and reviews"
status: Superseded
date: 2026-06-10
---

# ADR-029: Offer Conventional Commit syntax after fixes, features, and reviews

## Context

[ADR-023](../ADR-023-maintainer-always-favor-conventional-commits.md) defines the format for commit messages the plugin generates, but it does not require implementation workflows to offer one at completion or distinguish message generation from executing Git commands.

## Decision

After every successfully completed fix, feature, or review of changes, offer
to provide Conventional Commit syntax for the change. This applies whether the
work was routed through `fix`, `feature`, `develop`, or `review`.

Make the offer at the completion handoff after validation results are known. Generate the message only when the user accepts the offer.

The offer is for commit-message text/syntax only. Manual check-in is the
default. The workflow must not run `git add`, `git commit`, `git push`, or any
equivalent staging, commit, or push operation. These Git operations remain
supported only when the user explicitly asks for them, and that request must
follow the active safety and approval rules.

Generated messages follow ADR-023, including a Jira footer when a Jira key is known.

## Consequences

Every completed fix, feature, or reviewed change receives a consistent handoff
from implementation to check-in without the plugin changing repository history
or remote state.
