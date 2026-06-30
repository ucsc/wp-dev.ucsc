---
title: "ADR-055: Git remote operations — no push, PR offer, GitHub-only, no parent repo inspection"
status: Accepted
date: 2026-06-15
---

# ADR-055: Do not push to Git remotes

## Context

While [ADR-054](retired/ADR-054-maintainer-offer-to-create-pull-requests.md) encourages offering Pull Request creation, the underlying Git push operations present risks of pushing untested or unintended changes, especially when multiple repositories (outer plugin framework vs inner plugin source) are involved.

Force-pushing is especially risky because it can rewrite remote branch history. Even when the user is trying to create or update a pull request, branch publication should remain a human-controlled action.

## Decision

The AI assistant must not run `git push`, `git push --force`, `git push --force-with-lease`, or equivalent remote-write operations in this repository.

When pull request creation or branch publication is needed, the assistant may:

1. Verify and summarize the local repository state.
2. Provide the exact push command for the user to run manually.
3. Provide a GitHub compare URL or PR title/body.
4. Create a PR only when the branch is already available remotely and PR creation does not require pushing.

Remote history rewrites are never performed by the assistant. This includes `--force` and `--force-with-lease`.

## Pull request offer (absorbed from ADR-054)

After a fix or feature has committed its changes, offer to create a Pull Request on
GitHub when the branch already exists on the remote. Use GitHub REST API, `gh` CLI,
or GitHub MCP. Per the no-push rule above, if the branch is not remote, provide the
manual push command or compare URL and stop.

## GitHub-only remote operations (absorbed from ADR-056)

Restrict all remote repository operation offers (PR creation, MCP interactions)
strictly to GitHub. Do not offer equivalent operations on Bitbucket, GitLab, or
other platforms.

## No parent repository inspection (absorbed from ADR-057)

In the nested repo structure (`wp-dev.ucsc` outer / `ucsc-gutenberg-blocks` inner),
restrict all Git inspection and operations to the active block plugin repository.
Do not inspect status, branches, or tracked files of the parent scaffolding
repository (`wp-dev.ucsc`), even when modifying the plugin files under `.claude/`.
Modifications to the Claude Code plugin must be committed manually by the user.

## Consequences

- **Positive:** Prevents accidental pushes of unreviewed code, wrong-repository pushes, and unintended remote history rewrites.
- **Positive:** Enforces strict boundaries between inner and outer repositories.
- **Negative:** Requires the user to publish branches manually before PR creation when the remote branch is missing or stale.
