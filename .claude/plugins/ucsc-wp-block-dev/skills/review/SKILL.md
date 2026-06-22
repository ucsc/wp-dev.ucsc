---
name: review
description: Review a WordPress block diff, branch, file, pull request, or Jira-scoped change for bugs, regressions, security, accessibility, and missing tests.
---

# Review Mode

## Implements

implements: ADR-021-REVIEW-REFERENCES, ADR-022-REVIEW-PR-REFERENCES, ADR-023-REVIEW-COMMITS, ADR-025-REVIEW-ATLASSIAN-MCP, ADR-037-REVIEW-ANTHROPIC-GUARDRAILS, ADR-047-REVIEW-BRANCH-WARNING, ADR-051-REVIEW-OFFER-COMMIT, ADR-052-REVIEW-AI-COAUTHOR, ADR-053-REVIEW-SKILLSET-TAG, ADR-054-REVIEW-OFFER-PR, ADR-055-REVIEW-NO-PUSH, ADR-056-REVIEW-GITHUB-ONLY, ADR-057-REVIEW-NO-PARENT-REPOS, ADR-062-REVIEW-GITHUB-FALLBACKS, ADR-069-REVIEW-FULL-PATHS

## Universal Command Intake

Apply ADR-011: resolve the review target, natural-language review focus, and optional Jira key/URL from the full input. Infer the current diff when no target is supplied and it is unambiguous. Ask one concise question only when the review surface cannot be determined safely.

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

Per ADR-029, offer to generate Conventional Commit syntax for reviewed changes
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
