---
title: "ADR-104: claude-wordpress-skills is a recommended companion skillset for WP work"
status: Accepted
date: 2026-06-25
related: ["ADR-006", "ADR-037", "ADR-079"]
---

# ADR-104: claude-wordpress-skills is a recommended companion skillset for WP work

## Status

Accepted

## Context

`ucsc-wp-block-dev` is deliberately narrow: it targets the two UCSC block
plugins (`ucsc-gutenberg-blocks`, `ucsc-blocks`) in the `wp-dev.ucsc` Docker
environment and encodes UCSC-specific workflow (block targets, the run driver,
validate/verify suites). It does **not** carry general WordPress engineering
guidance — coding standards, plugin/theme architecture, security hardening, or
performance review — beyond what each block task needs. ADR-006 already points
`develop` at the official WordPress Block Development Examples for the same
reason: we link authoritative external references rather than re-deriving them.

Elvis Marin (`elvismdev`) maintains an MIT-licensed, marketplace-distributable
Claude Code plugin of general WordPress engineering skills that complements this
gap without overlapping our block-specific scope:

- **Source:** https://github.com/elvismdev/claude-wordpress-skills
- **License:** MIT · **Author:** Elvis Marin (`elvismdev`)

It provides these skills (status as of 2026-06-25):

| Skill | Purpose | Status |
| --- | --- | --- |
| `wp-performance-review` | Performance code review and optimization analysis | Active |
| `wp-security-review` | Security audit and hardening review | In development |
| `wp-gutenberg-blocks` | Block Editor / Gutenberg development | In development |
| `wp-theme-development` | Theme development best practices | In development |
| `wp-plugin-development` | Plugin architecture and standards | In development |

The active `wp-performance-review` skill analyzes WordPress-specific patterns we
do not cover: unbounded/`LIKE`/`NOT IN` database queries, object-cache and
transient strategy, N+1 template queries, AJAX and external HTTP calls, hook
usage, JS bundling, and `in_array()` hot paths — with platform notes for VIP,
WP Engine, Pantheon, and self-hosted. This is a natural fit alongside our
`review` and `validate` skills, much as Anthropic's `plugin-dev` is a companion
for `maintainer` Tier 2 work (ADR-079).

It is **not** bundled with `ucsc-wp-block-dev`. It is independently maintained,
independently versioned, and not under UCSC control, so we reference and
recommend it rather than vendoring it (consistent with ADR-006 and the
guardrail posture of ADR-037).

## Decision

Treat `claude-wordpress-skills` as a **recommended optional companion** for
general WordPress engineering concerns that fall outside this plugin's
block-specific scope, mirroring the ADR-079 companion model:

1. **Recommend, do not require.** No `ucsc-wp-block-dev` skill hard-depends on
   it. All current workflows (`develop`, `run`, `validate`, `verify`, `review`,
   `hub`, `maintainer`) continue to work unchanged when it is absent.

2. **Surface the recommendation where it pays off.** When a request drifts into
   general WordPress engineering beyond a block target — site-wide performance,
   security hardening, plugin/theme architecture, or WordPress coding standards
   — point the user at the companion skillset and how to install it, then
   continue the block-specific task. The `review` skill is the primary place to
   surface this (it already covers security/a11y/bugs for a block change but not
   site-wide performance/security auditing).

3. **Installation guidance.** Prefer the marketplace install; document the
   alternatives verbatim from upstream:

   ```text
   /plugin marketplace add elvismdev/claude-wordpress-skills
   ```

   ```bash
   git clone https://github.com/elvismdev/claude-wordpress-skills.git ~/.claude/plugins/wordpress
   git submodule add https://github.com/elvismdev/claude-wordpress-skills.git .claude/plugins/wordpress
   ```

   After installing, the user may need `/reload-plugins` for the new skills to
   be discoverable in the current session.

4. **Document, don't vendor.** Record the upstream as a reference (alongside the
   ADR-006 examples). Do not copy its skill bodies into this plugin; upstream
   wins on conflicts and is reviewed periodically.

5. **Future formal dependency (deferred).** A formal dependency — declaring it
   in the plugin manifest or marketplace metadata, or a `plugin-dev`-style
   pre-flight `claude plugin list | grep` check (ADR-079) before WP-engineering
   operations — is **explicitly deferred**, not adopted now. Reasons to wait:
   several of its skills are still "in development," it is third-party (not
   Anthropic-maintained like `plugin-dev`), and our scope is block-specific.
   Revisit when (a) `wp-security-review`/`wp-gutenberg-blocks` reach a stable
   release and (b) a concrete UCSC workflow routinely relies on one of its
   skills.

## Consequences

- **Positive:** Users get a clear, authoritative path for general WordPress
  performance/security/standards work without inflating this plugin's scope or
  token cost. Reinforces the link-don't-vendor posture of ADR-006/ADR-037 and the
  companion-dependency pattern of ADR-079. The recommendation appears only when
  relevant, so the common block-task path is unaffected.
- **Negative:** Recommends a third-party, not-yet-fully-released plugin we do not
  control; its skill set and triggers may change. Because there is no formal
  dependency check yet, a user who acts on the recommendation but skips
  `/reload-plugins` may not see the skills immediately. The status table above
  can drift and should be re-verified when this ADR is revisited.
