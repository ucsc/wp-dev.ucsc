---
name: feature
description: This skill should be used when the user asks to "add new behavior", "create a new block", "add a feature", "implement editor controls", "add frontend output", or describes new functionality for ucsc-gutenberg-blocks that is not a defect fix.
---

# Feature Workflow

Use this as the preferred workflow for new behavior. Use `fix` when existing
behavior is incorrect.

## Universal Command Intake

Apply ADR-011: resolve the target block, GUI, or app; the natural-language
feature request; and optional Jira key/URL from the full input. Ask one concise question only when missing or conflicting information prevents useful work.

When Jira, Confluence, pasted ticket details, or issue normalization applies,
read
[`../references/issue-context.md`](../references/issue-context.md)
before defining the feature.

# Note on relative references
The references above use a relative path into `develop/references/`. This is an
intentional dependency but fragile to directory moves/renames. Consider
promoting shared references (issue-context.md, targets.md) to a plugin-level
`skills/shared/references/` to avoid breakage. Maintain awareness when
renaming directories.

Before using tools, require:

- **Target:** the block, GUI, or app that will change.
- **Desired outcome:** a plain-language description of the new behavior.

Prompt for a Jira ID up front in the initial clarification when none was
supplied. When Atlassian MCP tools are available and a Jira ID or URL is
supplied, fetch the Jira record before defining the feature. When Atlassian MCP
tools are unavailable, ask the user to paste the ticket details or summarize
the relevant requirements. Jira is preferred, not required.

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
