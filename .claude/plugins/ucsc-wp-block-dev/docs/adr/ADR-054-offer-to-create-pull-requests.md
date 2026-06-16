---
title: "ADR-054: Offer to create pull requests"
status: Accepted
date: 2026-06-15
---

# ADR-054: Offer to create pull requests

## Context

After a user finishes developing a feature or fixing a bug, they typically need to push their branch and create a pull request on GitHub for code review. While users can always perform these actions manually, offering an automated path reduces friction and speeds up the development cycle. 

## Decision

When a feature or fix workflow has successfully committed its changes to the repository, the AI assistant must offer to automatically create a Pull Request on GitHub.

The assistant should explicitly offer to do this via GitHub REST APIs, the `gh` CLI tool, or a GitHub MCP server, depending on the environment's capabilities. The assistant must wait for explicit user approval before pushing the branch and opening the pull request. Manual creation remains the default if the user declines or prefers to handle it themselves.

## Consequences

- **Positive:** Reduces manual steps at the end of a successful task, streamlining the path from commit to code review.
- **Negative:** Requires the environment to be authenticated with GitHub (via MCP, CLI, or API token) in order to successfully fulfill the offer.
