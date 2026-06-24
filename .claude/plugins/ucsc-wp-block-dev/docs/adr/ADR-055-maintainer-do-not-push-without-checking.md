---
title: "ADR-055: Do not push to Git remotes"
status: Accepted
date: 2026-06-15
---

# ADR-055: Do not push to Git remotes

## Context

While [ADR-054](ADR-054-maintainer-offer-to-create-pull-requests.md) encourages offering Pull Request creation, the underlying Git push operations present risks of pushing untested or unintended changes, especially when multiple repositories (outer plugin framework vs inner plugin source) are involved.

Force-pushing is especially risky because it can rewrite remote branch history. Even when the user is trying to create or update a pull request, branch publication should remain a human-controlled action.

## Decision

The AI assistant must not run `git push`, `git push --force`, `git push --force-with-lease`, or equivalent remote-write operations in this repository.

When pull request creation or branch publication is needed, the assistant may:

1. Verify and summarize the local repository state.
2. Provide the exact push command for the user to run manually.
3. Provide a GitHub compare URL or PR title/body.
4. Create a PR only when the branch is already available remotely and PR creation does not require pushing.

Remote history rewrites are never performed by the assistant. This includes `--force` and `--force-with-lease`.

## Consequences

- **Positive:** Prevents accidental pushes of unreviewed code, wrong-repository pushes, and unintended remote history rewrites.
- **Negative:** Requires the user to publish branches manually before PR creation when the remote branch is missing or stale.
