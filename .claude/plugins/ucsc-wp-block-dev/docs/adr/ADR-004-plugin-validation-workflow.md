---
title: "ADR-004: Plugin maintenance and validation via plugin-dev:plugin-validator"
status: Accepted
date: 2026-06-09
---

# ADR-004: Plugin maintenance and validation via plugin-dev:plugin-validator

## Status

Accepted

## Context

`ucsc-wp-block-dev` is itself a Claude Code plugin that needs upkeep — manifest correctness, skill frontmatter, naming conventions, structure, and security. Anthropic's `plugin-dev` plugin ships a `plugin-validator` agent that checks exactly these. Relying on it avoids hand-rolling validation logic and keeps maintenance low-token (see ADR-003).

The block-dev skills (`develop`, `fix`, `run`) operate on `ucsc-gutenberg-blocks` code and should not be cluttered with plugin self-maintenance concerns. Hidden domain references under `develop/references/domain/` provide shared WordPress block context without adding another top-level skill.

## Decision

Plugin self-maintenance lives in a dedicated `maintainer` skill, separate from the block-dev skills.

- The `maintainer` skill launches the `plugin-dev:plugin-validator` agent and runs the bundled pytest suite.
- The README's **Maintainer setup** section documents how to install `plugin-dev` and run validation.
- `plugin-dev` is a maintainer-time dependency only; it is not required to use the block-dev skills.

## Consequences

- Validation guidance has one home (`maintainer` skill + README), discoverable near other maintainer setup steps.
- Block-dev skills stay focused on code.
- Maintainers must install `plugin-dev@claude-plugins-official` before validating.
