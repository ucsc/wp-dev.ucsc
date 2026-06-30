---
title: "ADR-057: Do not inspect parent Git repos"
status: Superseded
date: 2026-06-15
---

# ADR-057: Do not inspect parent Git repos

## Context

The `wp-dev.ucsc` environment utilizes a nested repository structure where the WordPress scaffold is the parent Git repository, and the active Gutenberg blocks plugin (`ucsc-gutenberg-blocks`) acts as a nested inner repository. Inspecting or interacting with the parent repository's Git state can lead to confusion, accidental commits to the scaffolding, and out-of-scope modifications.

## Decision

When checking Git status, determining branch information, or preparing commits, the AI assistant must restrict its Git inspection solely to the active block repository (`public/wp-content/plugins/ucsc-gutenberg-blocks`). The assistant must deliberately ignore the state, branches, and tracked files of the parent scaffolding repository (`wp-dev.ucsc`), even when modifying the assistant plugin itself.

## Consequences

- **Positive:** Enforces strict boundaries around the developer's primary code artifacts, preventing accidental cross-repository entanglement.
- **Negative:** Modifications to the Claude Code plugin (which resides in the parent repository under `.claude`) will need to be committed manually by the user, as the assistant will no longer inspect or manage the parent Git state.
