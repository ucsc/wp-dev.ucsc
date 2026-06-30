---
title: "ADR-054: Offer to create pull requests"
status: Superseded
date: 2026-06-15
---

# ADR-054: Offer to create pull requests

## Context

After a user finishes developing a feature or fixing a bug, they typically need
to publish their branch and create a pull request on GitHub for code review.
While users can always perform these actions manually, offering an automated PR
creation path reduces friction once the branch is already available remotely.

## Decision

When a feature or fix workflow has successfully committed its changes to the
repository, the AI assistant should offer to create a Pull Request on GitHub if
the branch already exists on the remote.

The assistant should explicitly offer to do this via GitHub REST APIs, the `gh`
CLI tool, or a GitHub MCP server, depending on the environment's capabilities.
Per ADR-055, the assistant must not push branches or rewrite remote history. If
the branch is not available remotely, provide the manual push command or compare
URL and stop.

## Consequences

- **Positive:** Reduces manual steps at the end of a successful task, streamlining the path from commit to code review.
- **Negative:** Requires the environment to be authenticated with GitHub (via MCP, CLI, or API token) in order to successfully fulfill the offer.
