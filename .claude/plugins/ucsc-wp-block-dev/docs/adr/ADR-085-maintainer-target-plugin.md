---
title: "ADR-085: Treat maintainer mode target as the plugin itself"
status: Accepted
date: 2026-06-18
---

# ADR-085: Treat maintainer mode target as the plugin itself

## Context

Most maintainer operations (validation, reference checks, documentation generation, skill inventory sync, and publishing) operate over the plugin's meta-surface: SKILL.md files, ADRs, scripts, manifests, and test suites. These workflows are organizational and repository-scoped rather than block-scoped.

The earlier ADR-084 makes selecting a block target the primary workflow for development, test, verify flows. Maintainer work is conceptually different: it audits and modifies the plugin repository as a whole.

## Decision

When the `maintainer` skill or maintainer-mode operations run, the authoritative target is the plugin repository root rather than an individual block target. Maintainer-mode handlers should not prompt for a block target; instead they:

- Operate against the plugin root `${CLAUDE_PLUGIN_ROOT}` by default.
- Treat maintainer as a special mode: the session does not need to `clear` or re-resolve a block `target` when entering maintainer flows. If a target is already set in the session, the maintainer handlers must not reset or discard it — maintainer work is repository-scoped by default.
- Accept an explicit `BLOCK_TARGET` or `target` argument for narrow operations that incidentally need to focus on a single block, but do not require selecting one when starting maintainer flows.
- Continue to use the Universal Command Intake pattern for optional Jira or natural-language context, but skip the block-selection step unless the user requests block-scoped work.

## Consequences

Positive:
- Removes unnecessary prompts when doing repo-wide maintenance tasks.
- Ensures checks like `check-references`, ADR validation, and docs generation run deterministically across the plugin surface.

Negative / tradeoffs:
- If maintainers do want to focus on a block inside maintainer mode, they must supply the block target explicitly or switch to develop/verify/test workflows.

## Implementation notes

- Update maintainer/SKILL.md to state the plugin-root default (done).
- Ensure scripts under skills/maintainer accept optional `BLOCK_TARGET` env/arg and ignore it by default.
- Keep tests that validate target indexes (targets.md) separate from maintainer checks; maintainer checks examine repository-level invariants.
- Reference: ADR-011, ADR-084.
