---
title: "ADR-079: Anthropic plugin-dev is the upstream reference and optional Tier 2 companion"
status: Superseded
date: 2026-06-17
related: ["ADR-064", "ADR-075", "ADR-078"]
---

# ADR-079: Anthropic plugin-dev upstream reference and optional Tier 2 companion

## Status

Accepted

## Context

The `maintainer` skill's Tier 2 operations (`validate` agent,
`review-skills`) delegate to `plugin-dev:plugin-validator` and
`plugin-dev:skill-reviewer`. Anthropic now maintains the current `plugin-dev`
source in the main `claude-code` repository and distributes it through the
Claude Code marketplace:

- **Docs:** https://code.claude.com/docs/en/plugins
- **Source:** https://github.com/anthropics/claude-code/tree/main/plugins/plugin-dev

If `plugin-dev` is not installed, Tier 2 operations silently fail or produce
confusing errors. The current SKILL.md mentions installation passively but does
not prompt a check before use.

## Decision

Before running any Tier 2 operation (`validate` agent, `review-skills`,
`skill-development`, `plugin-structure`), verify that the `plugin-dev` plugin
is installed:

```bash
claude plugin list | grep plugin-dev
```

If it is absent, prompt the user to install it before proceeding:

```text
/plugin install plugin-dev@claude-code-marketplace
```

After installation the user may need to run `/reload-plugins` for the new
agents and skills to be available in the current session.

The `plugin-dev` plugin is a companion dependency, not bundled with
`ucsc-wp-block-dev`. It is maintained by Anthropic and versioned independently.

Stable rules from the upstream validator and skill guidance are adapted into
the deterministic `maintainer self-test`. Its best-practice checker covers manifest
metadata, component placement, naming, trigger descriptions, progressive
disclosure, executable helpers, repository hygiene, and high-confidence secret
signatures. Subjective findings remain warnings unless strict mode is requested.

The maintainer also exposes a `training` mode for focused source-guided
learning. Training selects one or two analogous upstream plugins or skills,
records the source revision, distinguishes transferable patterns from local
policy conflicts, and produces recommendations or requested local
improvements. It does not execute or vendor upstream code.

Tier 1 operations (`claude plugin validate`, `self-test`,
`check-references`) do **not** require `plugin-dev` and always run without it.

## Consequences

- Users who attempt `maintainer validate` (Tier 2) or `maintainer
  review-skills` without `plugin-dev` get a clear installation prompt instead
  of a confusing failure.
- The check is lightweight (one `claude plugin list` call) and only runs
  before Tier 2 operations.
- Tier 1 operations remain zero-dependency.
- `maintainer self-test` and `maintainer all` catch a larger class of
  plugin-dev best-practice drift
  without spending agent tokens.
- Upstream guidance is linked from the maintainer skill and reviewed
  periodically rather than copied wholesale; current CLI/docs win on conflicts.
- Source-guided learning has an explicit maintainer entry point instead of
  accumulating ad hoc browsing instructions across unrelated skills.
