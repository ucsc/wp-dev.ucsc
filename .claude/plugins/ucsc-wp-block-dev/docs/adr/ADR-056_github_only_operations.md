---
title: "ADR-056: Do not offer operations on non-GitHub repositories"
status: Accepted
date: 2026-06-15
---

# ADR-056: Do not offer operations on non-GitHub repositories

## Context

While the `ucsc-wp-block-dev` plugin and the associated assistant capabilities can theoretically interface with multiple source control providers, the team exclusively uses GitHub for this ecosystem. Offering to create Pull Requests or perform operations on other platforms like Bitbucket or GitLab adds unnecessary noise and confusion.

## Decision

The AI assistant must restrict all its remote repository operation offers (like creating Pull Requests or interacting with an MCP server) strictly to GitHub. It must never offer to perform these operations on Bitbucket, GitLab, or any other non-GitHub repository platform.

## Consequences

- **Positive:** Keeps assistant interactions focused, relevant, and tied to the active GitHub-based toolchain.
- **Negative:** If the team ever migrates to another platform, this ADR will need to be superseded.
