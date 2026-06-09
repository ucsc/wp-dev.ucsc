---
name: review
description: Review a WordPress block diff, branch, file, pull request, or Jira-scoped change for bugs, regressions, security, accessibility, and missing tests.
disable-model-invocation: false
argument-hint: "[target | review focus | Jira key/URL]"
arguments: [target, input]
---

# Review Mode

## Universal Command Intake

Apply ADR-011: resolve the review target, natural-language review focus, and optional Jira key/URL from the full input. Infer the current diff when no target is supplied and it is unambiguous. Ask one concise question only when the review surface cannot be determined safely.

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
