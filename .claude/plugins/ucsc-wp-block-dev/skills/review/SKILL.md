---
name: review
description: Review a WordPress block diff, branch, file, pull request, or Jira-scoped change for bugs, regressions, security, accessibility, and missing tests.
argument-hint: "[block | PR | branch | file | diff] [focus]"
---

# Review Mode

## Implements

implements: ADR-021-REVIEW-REFERENCES, ADR-022-REVIEW-PR-REFERENCES, ADR-023-REVIEW-COMMITS, ADR-025-REVIEW-ATLASSIAN-MCP, ADR-034-REVIEW-DEFER-MCP-LOGIN, ADR-035-REVIEW-WORKTREE-WARNING, ADR-037-REVIEW-ANTHROPIC-GUARDRAILS, ADR-047-REVIEW-BRANCH-WARNING, ADR-051-REVIEW-OFFER-COMMIT, ADR-052-REVIEW-AI-COAUTHOR, ADR-053-REVIEW-SKILLSET-TAG, ADR-054-REVIEW-OFFER-PR, ADR-055-REVIEW-NO-PUSH, ADR-056-REVIEW-GITHUB-ONLY, ADR-057-REVIEW-NO-PARENT-REPOS, ADR-062-REVIEW-GITHUB-FALLBACKS, ADR-069-REVIEW-FULL-PATHS, ADR-093-REVIEW-BLOCK-TARGET

## Universal Command Intake

Resolve the review target, natural-language review focus, and optional Jira key/URL from the full input. Infer the current diff when no target is supplied and it is unambiguous. Ask one concise question only when the review surface cannot be determined safely.

**Block target (ADR-093).** When the review is scoped to a specific block (a
diff, branch, or PR touching one block), resolve that block with the shared
contract in
[`../develop/references/block-target-session.md`](../develop/references/block-target-session.md):
ARGUMENTS → persisted session value (`../develop/scripts/session_target.sh get`)
→ cwd inference → prompt. Validate an inferred directory with
`../develop/scripts/block_target_check.sh` before adopting it, and persist a
newly resolved target with `session_target.sh set`. A PR/branch/diff review that
spans multiple blocks or the whole plugin needs no single block target.

Per ADR-022, the review target may be a pull-request reference: a **GitHub PR** — a full URL such as `https://github.com/ucsc/ucsc-gutenberg-blocks/pull/169` or a bare `#<n>` (GitHub is the canonical PR host for this plugin; fetch it with the `gh` CLI) — or a **Bitbucket PR** (`https://bitbucket.org/<workspace>/<repo>/pull-requests/<n>` for related UCSC webapps repos). A Jira reference (ADR-021) and a PR reference may both be supplied — Jira gives the issue/acceptance context, the PR gives the code under review.

Per ADR-025, when a Bitbucket PR, Jira reference, or Confluence URL is in use and Atlassian MCP tools are unavailable, mention once that the user can set up Atlassian MCP for direct access. Keep the reminder brief and non-blocking, continue with available context, and do not repeat it later in the task. Never install, configure, authenticate, or reload Atlassian MCP without explicit user approval.

When GitHub CLI tooling is needed for pull request creation or inspection, read
[`../develop/references/github.md`](../develop/references/github.md) before
proceeding.

# Note on relative references
The references above use a relative path into `develop/references/`. This is an
intentional dependency but fragile to directory moves/renames. Consider
promoting shared references (issue-context.md, targets.md) to a plugin-level
`skills/shared/references/` to avoid breakage. If you keep relative paths,
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

Per ADR-051, offer to generate Conventional Commit syntax for reviewed changes
or review follow-up edits. Generate message text only if the user accepts.
Manual check-in is the default: do not run `git add`, `git commit`, or
equivalent staging/commit operations unless the user explicitly asks. Never run
`git push`, `git push --force`, `git push --force-with-lease`, or equivalent
remote-write operations; provide the command or PR URL for the user to run
instead.

## Plugin-dev Tools

When reviewing plugin components (skills, manifest, hooks), use the following tools:

- **`plugin-dev:plugin-validator`** — validate plugin structure, manifest, and naming via `Agent` with `subagent_type: "plugin-dev:plugin-validator"`.
- **`plugin-dev:skill-reviewer`** — review skill quality and description effectiveness via `Agent` with `subagent_type: "plugin-dev:skill-reviewer"`.
- **`plugin-dev:skill-development`** — guidance on skill structure and frontmatter via `Skill` with `skill: "plugin-dev:skill-development"`.
