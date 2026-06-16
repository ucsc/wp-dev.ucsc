---
title: "ADR-055: Generally do not push to Git, never push without checking"
status: Accepted
date: 2026-06-15
---

# ADR-055: Generally do not push to Git, never push without checking

## Context

While [ADR-054](ADR-054-offer-to-create-pull-requests.md) encourages offering Pull Request creation, the underlying Git push operations present risks of pushing untested or unintended changes, especially when multiple repositories (outer plugin framework vs inner plugin source) are involved. 

## Decision

The AI assistant must generally default to *not* pushing to remote Git repositories automatically. Pushing is permitted only when explicitly required, and the assistant must **NEVER push without thoroughly checking** the current state (e.g., via `git status`, `git log`, and confirming the target branch and repository). 

If a push is necessary, the assistant must explicitly verify the current repository context (e.g., inner repo vs outer repo) and confirm exactly what is being pushed before proceeding.

## Consequences

- **Positive:** Prevents accidental pushes of unreviewed code or pushing to the wrong remote tracking branch.
- **Negative:** Requires slightly more user back-and-forth for final branch publishing.
