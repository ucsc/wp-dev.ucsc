---
name: review
description: Review a WordPress block diff, branch, file, pull request, or Jira-scoped change for bugs, regressions, security, accessibility, and missing tests.
---

# Review Mode

## Universal Command Intake

Apply ADR-011: resolve the review target, natural-language review focus, and optional Jira key/URL from the full input. Infer the current diff when no target is supplied and it is unambiguous. Ask one concise question only when the review surface cannot be determined safely.

Per ADR-022, the review target may be a pull-request reference: a **GitHub PR** — a full URL such as `https://github.com/ucsc/ucsc-gutenberg-blocks/pull/169` or a bare `#<n>` (GitHub is the canonical PR host for this plugin; fetch it with the `gh` CLI) — or a **Bitbucket PR** (`https://bitbucket.org/<workspace>/<repo>/pull-requests/<n>` for related UCSC webapps repos). A Jira reference (ADR-021) and a PR reference may both be supplied — Jira gives the issue/acceptance context, the PR gives the code under review.

Per ADR-025, when a Bitbucket PR, Jira reference, or Confluence URL is in use and Atlassian MCP tools are unavailable, mention once that the user can set up Atlassian MCP for direct access. Keep the reminder brief and non-blocking, continue with available context, and do not repeat it later in the task. Never install, configure, authenticate, or reload Atlassian MCP without explicit user approval.

Prioritize actionable findings:

1. Runtime bugs and behavior regressions.
2. Security, escaping, permissions, and unsafe external-data handling.
3. PHP/JavaScript attribute-schema drift.
4. REST, LDAP, PeopleSoft, transient, rewrite-rule, and Docker risks.
5. Accessibility regressions and missing focused tests.

Report findings first, ordered by severity, with file and line references. Keep summary secondary.

## Plugin-dev Tools

When reviewing plugin components (skills, manifest, hooks), use the following tools:

- **`plugin-dev:plugin-validator`** — validate plugin structure, manifest, and naming via `Agent` with `subagent_type: "plugin-dev:plugin-validator"`.
- **`plugin-dev:skill-reviewer`** — review skill quality and description effectiveness via `Agent` with `subagent_type: "plugin-dev:skill-reviewer"`.
- **`plugin-dev:skill-development`** — guidance on skill structure and frontmatter via `Skill` with `skill: "plugin-dev:skill-development"`.
