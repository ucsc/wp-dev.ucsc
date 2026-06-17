---
title: "ADR-079: plugin-dev from claude-plugins-official is the required companion for Tier 2 maintainer operations"
status: Accepted
date: 2026-06-17
related: ["ADR-064", "ADR-075", "ADR-078"]
---

# ADR-079: plugin-dev companion plugin

## Status

Accepted

## Context

The `maintainer` skill's Tier 2 operations (`validate` agent,
`review-skills`) delegate to `plugin-dev:plugin-validator` and
`plugin-dev:skill-reviewer`. These agents are provided by Anthropic's official
`plugin-dev` plugin, distributed through `claude-plugins-official`:

- **Docs:** https://code.claude.com/docs/en/plugins
- **Source:** https://github.com/anthropics/claude-plugins-official

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
/plugin install plugin-dev@claude-plugins-official
```

After installation the user may need to run `/reload-plugins` for the new
agents and skills to be available in the current session.

The `plugin-dev` plugin is a companion dependency, not bundled with
`ucsc-wp-block-dev`. It is maintained by Anthropic and versioned
independently. The install command pins to the `claude-plugins-official`
distribution channel, which is the canonical source.

Tier 1 operations (`claude plugin validate`, pytest, `check-references`) do
**not** require `plugin-dev` and always run without it.

## Consequences

- Users who attempt `maintainer validate` (Tier 2) or `maintainer
  review-skills` without `plugin-dev` get a clear installation prompt instead
  of a confusing failure.
- The check is lightweight (one `claude plugin list` call) and only runs
  before Tier 2 operations.
- Tier 1 operations remain zero-dependency.
