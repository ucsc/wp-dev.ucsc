---
title: "ADR-078: use claude plugin validate ./path as the primary structural check before the plugin-dev agent"
status: Accepted
date: 2026-06-17
related: ["ADR-003", "ADR-064", "ADR-075"]
---

# ADR-078: claude plugin validate as primary structural check

## Status

Accepted (consolidates ADR-079 2026-06-29)

## Context

The `maintainer validate` operation currently documents only the
`plugin-dev:plugin-validator` agent as the way to validate the plugin. That
agent is token-heavy (~10k tokens) and spawns a subagent. Per ADR-064, it is
opt-in only and never runs as part of `all`.

The Claude Code CLI has a built-in structural validator:

```bash
claude plugin validate ./path-to-plugin
claude plugin validate --strict ./path-to-plugin
```

This command checks the manifest, frontmatter, naming conventions, and file
structure. It runs synchronously, burns no agent tokens, and exits non-zero on
failure. It is already exercised by the pytest suite
(`test_plugin_validity.py::TestPluginValidate`) on every `maintainer test` run.

There is a clear two-tier model here that was not previously documented:

| Tool | Cost | Purpose |
|---|---|---|
| `claude plugin validate <path>` | Free (CLI) | Structural correctness — manifest, frontmatter, naming |
| `plugin-dev:plugin-validator` agent | ~10k tokens | Semantic quality — description effectiveness, workflow completeness |

## Decision

`claude plugin validate <path>` is the **primary** validation step. Run it
first, before offering the plugin-dev agent.

- In `maintainer validate`, run the CLI validator first. Only offer the
  plugin-dev agent as a second-tier escalation when structural validation
  passes and a deeper semantic review is wanted.
- In `maintainer all`, the CLI validator may be included (it is cheap and
  deterministic). The plugin-dev agent remains excluded per ADR-064.
- The `--strict` flag adds additional checks; use it as the default when
  running from the maintainer skill.

The exact command from the plugin root (one level below the project root):

```bash
claude plugin validate --strict .claude/plugins/ucsc-wp-block-dev
```

Or from the project root:

```bash
claude plugin validate --strict .claude/plugins/ucsc-wp-block-dev
```

## Tier 2 companion — plugin-dev (absorbed from ADR-079)

Before running any Tier 2 operation (`validate` agent, `review-skills`,
`skill-development`), verify that `plugin-dev` is installed:

```bash
claude plugin list | grep plugin-dev
```

If absent, prompt the user to install it:

```text
/plugin install plugin-dev@claude-code-marketplace
```

`plugin-dev` is a companion dependency maintained by Anthropic, not bundled with
`ucsc-wp-block-dev`. Tier 1 operations (`claude plugin validate`, `self-test`,
`check-references`) do not require it. The `maintainer training` mode uses
`plugin-dev` source as an upstream reference for focused source-guided learning —
it selects analogous upstream examples, records the source revision, and produces
recommendations; it does not execute or vendor upstream code.

## Consequences

- Structural regressions are caught cheaply on every `maintainer all` run.
- The plugin-dev agent is reserved for qualitative review, not routine CI.
- The distinction between structural and semantic validation is explicit.
- Users who attempt Tier 2 operations without `plugin-dev` get a clear install prompt instead of a confusing failure.
- `maintainer validate` documents both tiers so the choice is informed.
