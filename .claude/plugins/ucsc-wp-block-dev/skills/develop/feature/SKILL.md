---
name: feature
description: This skill should be used when the user asks to "add new behavior", "create a new block", "add a feature", "implement editor controls", "add frontend output", or describes new functionality for UCSC block plugins (ucsc-blocks, ucsc-gutenberg-blocks) that is not a defect fix.
version: 0.1.0
argument-hint: "[block] [feature description] [Jira or GitHub URL/ID]"
---

# Feature Workflow

## Implements

implements: ADR-009-FEATURE-INTAKE, ADR-036-FEATURE-WORKFLOW, ADR-083-FEATURE-RETROSPECTIVE, ADR-093-FEATURE-BLOCK-TARGET

Use this as the preferred workflow for new behavior. Use `fix` when existing
behavior is incorrect.

## Universal Command Intake

Resolve the target block/app, natural-language request, and optional Jira/GitHub issue from the context. Always ask one concise question only and wait for the answer before using tools if information is missing.
- For Jira/pasted details, see [../references/issue-context.md](../references/issue-context.md). Prompt for a jira id up front; it is preferred, not required. When atlassian mcp tools are available, fetch the jira record; when atlassian mcp tools are unavailable, paste the ticket details.
- For GitHub CLI/issues, see [../references/github.md](../references/github.md).
- For the block target session persistence contract, see [../references/block-target-session.md](../references/block-target-session.md).

Determine the block target in this order:
1. **Explicit ARGUMENTS** — named target wins.
2. **Persisted session value** — run `bash scripts/session-target.sh get`.
3. **CWD inference** — run `bash "${CLAUDE_PLUGIN_ROOT}/skills/develop/scripts/resolve-target.sh"`.
4. **Prompt** — choose from [../references/targets.md](../references/targets.md).

Once resolved, persist it:
```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/develop/scripts/session-target.sh" set <slug> <repo> <abs-path>
```

## Define The Feature

1. Restate the desired user-visible outcome.
2. Identify acceptance criteria, affected users, and important edge cases.
3. Distinguish requirements from implementation suggestions.
4. Inspect the nearest existing block or workflow pattern.
5. Propose the smallest vertical slice and obtain confirmation when the request
   leaves a meaningful product decision unresolved.

## Implement

Before editing, check the current Git branch. Per ADR-047, if it is `main`,
`master`, or `develop`, warn that changes should normally happen on a feature
branch named `dev/developer_name/ISSUE-1234_short_desc`. Do not create or
switch branches unless the user explicitly asks.

Delegate implementation to the `develop` skill after the feature is defined. Invoke the develop skill explicitly with the resolved target, desired outcome, and acceptance criteria (for example: `develop <target> "Implement X" --jira ISSUE-1234`). Preserve the target, requirements, acceptance criteria, and Jira context during that handoff.

For `ucsc-gutenberg-blocks` domain guidance, read
[`../references/domain-blocks.md`](../references/domain-blocks.md)
inside the selected workflow. Resolve block-specific context through
[`../references/targets.md`](../references/targets.md)
rather than a top-level target skill.

## Complete

Run focused tests, use `run` for the Docker build and launch workflow, and use
`verify` for user-facing acceptance evidence. Summarize changed behavior and
offer to generate Conventional Commit syntax. Generate message text only if the
user accepts. Manual check-in is the default; do not run `git add`, `git
commit`, or equivalent staging/commit operations unless the user explicitly
asks. Never run `git push`, `git push --force`, `git push --force-with-lease`,
or equivalent remote-write operations; provide the command or PR URL for the
user to run instead.
