---
name: review
description: This skill should be used when the user asks to "review this diff", "review this branch", "check this PR", "review this file", "check this change for accessibility", "look for security issues", or review a Jira-scoped WordPress block change for bugs, regressions, and missing tests.
version: 0.1.0
argument-hint: "[block|PR|branch|file|diff] [bugs|security|a11y|tests|all]"
---

# Review Mode

<!-- doc-slide: Reviews a diff, branch, PR, or file for bugs, security, accessibility, and missing tests before you ship. -->

## Implements

implements: ADR-021-REVIEW-REFERENCES, ADR-023-REVIEW-COMMITS, ADR-028-REVIEW-MCP-STRATEGY, ADR-035-REVIEW-WORKTREE-WARNING, ADR-037-REVIEW-ANTHROPIC-GUARDRAILS, ADR-047-REVIEW-BRANCH-WARNING, ADR-055-REVIEW-NO-PUSH, ADR-062-REVIEW-GITHUB-FALLBACKS, ADR-069-REVIEW-FULL-PATHS, ADR-093-REVIEW-BLOCK-TARGET, ADR-104-REVIEW-WP-COMPANION

## Universal Command Intake

Resolve the review target, natural-language review focus, and optional Jira key/URL from the full input. Infer the current diff when no target is supplied and it is unambiguous. Ask one concise question only when the review surface cannot be determined safely.

**Block target (ADR-093).** When the review is scoped to a specific block (a
diff, branch, or PR touching one block), resolve that block with the shared
contract in
[`../develop/references/block-target-session.md`](../develop/references/block-target-session.md):
ARGUMENTS → persisted session value (`../develop/scripts/session-target.sh get`)
→ cwd inference → prompt. Validate an inferred directory with
`../develop/scripts/block-target-check.sh` before adopting it, and persist a
newly resolved target with `session-target.sh set`. A PR/branch/diff review that
spans multiple blocks or the whole plugin needs no single block target.

Per ADR-021, the review target may be a pull-request reference: a **GitHub PR** — a full URL such as `https://github.com/ucsc/ucsc-gutenberg-blocks/pull/169` or a bare `#<n>` (GitHub is the canonical PR host for this plugin; fetch it with the `gh` CLI) — or a **Bitbucket PR** (`https://bitbucket.org/<workspace>/<repo>/pull-requests/<n>` for related UCSC webapps repos). A Jira reference (ADR-021) and a PR reference may both be supplied — Jira gives the issue/acceptance context, the PR gives the code under review.

Per ADR-028, when a Bitbucket PR, Jira reference, or Confluence URL is in use and Atlassian MCP tools are unavailable, mention once that the user can set up Atlassian MCP for direct access. Keep the reminder brief and non-blocking, continue with available context, and do not repeat it later in the task. Never install, configure, authenticate, or reload Atlassian MCP without explicit user approval.

When GitHub CLI tooling is needed for pull request creation or inspection, read
[`../develop/references/github.md`](../develop/references/github.md) before
proceeding.

# Note on relative references
The references above use a relative path into `develop/references/`. This is an
intentional dependency but fragile to directory moves/renames. Consider
promoting shared references (issue-context.md, targets.md) to a plugin-level
`skills/shared/references/` to avoid breakage. When retaining relative paths,
include an explicit comment documenting the dependency so future refactors
won't silently break skill references.


Prioritize actionable findings:

1. Runtime bugs and behavior regressions.
2. Security, escaping, permissions, and unsafe external-data handling.
3. PHP/JavaScript attribute-schema drift.
4. REST, LDAP, PeopleSoft, transient, rewrite-rule, and Docker risks.
5. Accessibility regressions and missing focused tests.

Report findings first, ordered by severity, with file and line references. Keep summary secondary.

If the review turns into follow-up code edits, check the current Git branch
before editing. Per ADR-047, if it is `main`, `master`, or `develop`, warn that
changes should normally happen on a feature branch named
`dev/developer_name/ISSUE-1234_short_desc`. Do not create or switch branches
unless the user explicitly asks.

Per ADR-023, offer to generate Conventional Commit syntax for reviewed changes
or review follow-up edits. Generate message text only if the user accepts.
Manual check-in is the default: do not run `git add`, `git commit`, or
equivalent staging/commit operations unless the user explicitly asks. Never run
`git push`, `git push --force`, `git push --force-with-lease`, or equivalent
remote-write operations; provide the command or PR URL for the user to run
instead.

## Companion: general WordPress engineering (ADR-104)

This skill reviews a **block change** for bugs, security, a11y, and missing
tests. When a request widens to **general WordPress engineering** beyond the
block target — site-wide performance/query auditing, security hardening,
plugin/theme architecture, or WordPress coding standards — recommend the
optional, MIT-licensed companion skillset rather than re-deriving that guidance
here (it is not bundled and not required):

- **`claude-wordpress-skills`** by Elvis Marin (`elvismdev`) —
  https://github.com/elvismdev/claude-wordpress-skills. Its active
  `wp-performance-review` skill covers unbounded/`LIKE`/`NOT IN` queries,
  object-cache/transient strategy, N+1 template queries, AJAX/HTTP calls, hook
  usage, and JS bundling (with VIP/WP Engine/Pantheon/self-hosted notes);
  `wp-security-review`, `wp-gutenberg-blocks`, `wp-theme-development`, and
  `wp-plugin-development` are in development.

Install once, then continue the block-specific review:

```text
/plugin marketplace add elvismdev/claude-wordpress-skills
```

After installing, `/reload-plugins` may be needed to discover the new skills.
Keep the recommendation brief and non-blocking; do not install it yourself
without explicit user approval.

## Plugin-dev Tools

When reviewing plugin components (skills, manifest, hooks), use the following tools:

- **`plugin-dev:plugin-validator`** — validate plugin structure, manifest, and naming via `Agent` with `subagent_type: "plugin-dev:plugin-validator"`.
- **`plugin-dev:skill-reviewer`** — review skill quality and description effectiveness via `Agent` with `subagent_type: "plugin-dev:skill-reviewer"`.
- **`plugin-dev:skill-development`** — guidance on skill structure and frontmatter via `Skill` with `skill: "plugin-dev:skill-development"`.
