---
name: develop
description: This skill should be used when the user asks to "add a block", "create a Gutenberg block", "implement a feature", "modify block code", "extend a block", or when feature/fix scope is already defined and implementation is ready to begin on ucsc-gutenberg-blocks.
---

# Develop — Add a Block or Feature

Guided flow for adding a new Gutenberg block or extending an existing one in `ucsc-gutenberg-blocks`.

## Sub-workflows

For scoped work, prefer the appropriate sub-workflow over invoking `develop` directly:

- [`feature/SKILL.md`](feature/SKILL.md) — define and implement new behavior (new blocks, editor enhancements, behavior additions).
- [`fix/SKILL.md`](fix/SKILL.md) — reproduce and repair a described defect in a specified target.

Primarily touches `classes/` and `src/blocks/`.

All paths relative to `public/wp-content/plugins/ucsc-gutenberg-blocks/`.

## Universal Command Intake

Apply ADR-011: resolve the target, natural-language feature request, and
optional Jira key/URL from the full input and session context, regardless of
order. Preserve explicit user instructions and ask one concise question only
when missing or conflicting information blocks the workflow.

When Jira, Confluence, pasted ticket details, or issue normalization applies,
read [`references/issue-context.md`](references/issue-context.md) and merge its
compact implementation brief into this workflow.

When GitHub CLI tooling is needed for pull request creation or inspection, read
[`references/github.md`](references/github.md) before proceeding.

Before using tools, require the user to choose a target. Resolve known slugs and
aliases through
[`references/targets.md`](references/targets.md), then read only the
selected target reference. Do not load all target references.

Target references (ucsc-gutenberg-blocks):

- [`references/target-accordion.md`](references/target-accordion.md)
- [`references/target-campus-directory.md`](references/target-campus-directory.md)
- [`references/target-class-schedule.md`](references/target-class-schedule.md)
- [`references/target-content-sharer.md`](references/target-content-sharer.md)
- [`references/target-course-catalog.md`](references/target-course-catalog.md)
- [`references/target-events.md`](references/target-events.md)
- [`references/target-feedback.md`](references/target-feedback.md)
- [`references/target-news.md`](references/target-news.md)

Target references (ucsc-blocks):

- [`references/target-calendar-feed.md`](references/target-calendar-feed.md)
- [`references/target-ucsc-events.md`](references/target-ucsc-events.md)

Domain references:

- [`references/domain-blocks.md`](references/domain-blocks.md)
- [`references/domain-blocks-reference.md`](references/domain-blocks-reference.md)
- [`references/domain-detection.md`](references/domain-detection.md)
- [`references/domain-stack-profile.md`](references/domain-stack-profile.md)

## 1. Secure the Target and Feature Description

Before using tools, investigating, or writing code, obtain both required inputs from the user:

1. **Target** — the block, GUI, or app being worked on.
2. **Feature description** — what should be added or changed. A plain-language description is sufficient.

If either input is missing, ask one concise question for all missing inputs and wait for the answer. Prompt for a Jira ID up front in the same clarification when none was supplied. When Atlassian MCP tools are available and a Jira ID or URL is supplied, fetch the Jira record before implementation. When Atlassian MCP tools are unavailable, ask the user to paste the ticket details or summarize the relevant requirements. Jira is preferred, not required. See ADR-008 and ADR-009.

For an unlisted target, confirm its canonical slug and scope before proceeding.
Add a target reference only when the resulting domain guidance will be reused.
Follow the onboarding checklist at
[`references/domain-add-target.md`](references/domain-add-target.md).

After the required intake is complete, clarify implementation details as needed:

- **Render model** — dynamic (PHP render callback, server-rendered HTML) or static (editor `save()` returns JSX)?
- **Data source** — static content, REST API, LDAP, PeopleSoft, or none?
- **Editor controls** — what attributes does the editor need? (text, URL, toggle, select, etc.)

Default to dynamic blocks with PHP render callbacks unless the block has no server-side data needs.

## 2. Find the Nearest Existing Block

Before editing, check the current Git branch. Per ADR-047, if it is `main`,
`master`, or `develop`, warn that changes should normally happen on a feature
branch named `dev/developer_name/ISSUE-1234_short_desc`. Do not create or
switch branches unless the user explicitly asks.

Before writing from scratch, find the existing block that most closely resembles the new one:

```bash
ls classes/
ls src/blocks/
```

Read the nearest match — PHP class and JS file. Use its patterns for class structure, REST registration, transient caching, and block registration. Do not invent new patterns.

## 3–8. Implement the Block

Read [`references/block-templates.md`](references/block-templates.md) for the canonical skeletons for each file. Apply them in order:

3. **PHP Class** — `classes/<BlockName>.php` (constructor, `adminAssets`, `theHTML` render callback)
4. **Template** — `templates/block-name.php` (markup only; compute values in `theHTML`, not the template)
5. **Block JS** — `src/blocks/BlockName.js` (exports a function that calls `wp.blocks.registerBlockType`)
6. **index.js** — import and call the new module alongside existing registrations
7. **index.php** — `require_once` the new class and instantiate it
8. **REST API** — add `rest_api_init` hook and `register_routes` / `get_data` methods if the block needs its own endpoint

## 9. Validate

```bash
npm run build        # must complete without errors
```

Note: the plugin does not currently have a `test` script in `package.json`. If Jest tests are added in the future, run `npm test` and write tests in `src/blocks/__tests__/BlockName.test.js`.

## 10. Complete the Feature Phase

After implementing, remind the user that this change needs build verification
in the Docker environment with the `run` skill before it is treated as ready.

If applicable validation is complete and no Jira ID was captured, the completion summary may ask for it again. Do not repeat the prompt when an ID is already known, and do not treat a missing ID as incomplete work. See ADR-010.

Per ADR-029, offer to generate Conventional Commit syntax for the completed
feature. Generate message text only if the user accepts. Manual check-in is the
default: do not run `git add`, `git commit`, or equivalent staging/commit
operations unless the user explicitly asks. Never run `git push`,
`git push --force`, `git push --force-with-lease`, or equivalent remote-write
operations; provide the command or PR URL for the user to run instead.

## Plugin-dev Tools

When this workflow creates or modifies plugin components (skills, manifest, hooks), use the following tools:

- **`plugin-dev:plugin-validator`** — validate plugin structure, manifest, and naming via `Agent` with `subagent_type: "plugin-dev:plugin-validator"`.
- **`plugin-dev:skill-reviewer`** — review skill quality and description effectiveness via `Agent` with `subagent_type: "plugin-dev:skill-reviewer"`.
- **`plugin-dev:skill-development`** — guidance on skill structure and frontmatter via `Skill` with `skill: "plugin-dev:skill-development"`.
