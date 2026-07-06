---
name: develop
description: This skill should be used when the user asks to "add a block", "create a Gutenberg block", "implement a feature", "modify block code", "extend a block", or when feature/fix scope is already defined and implementation is ready to begin on UCSC block plugins (ucsc-blocks, ucsc-gutenberg-blocks).
version: 0.1.0
argument-hint: "[feature|fix] [block] [description or Jira/GitHub URL or ID]"
---

# Develop — Add a Block or Feature

<!-- doc-slide: Adds or modifies block code — `feature` plans and builds new behavior, `fix` reproduces and repairs a described defect. -->

Guided flow for adding a new Gutenberg block or extending an existing one in `ucsc-gutenberg-blocks`.

## Implements

implements: ADR-001-DEVELOP-PLUGIN-SCOPE, ADR-006-DEVELOP-WP-EXAMPLES, ADR-009-DEVELOP-INTAKE, ADR-021-DEVELOP-REFERENCES, ADR-036-DEVELOP-FIX-FEATURE, ADR-040-DEVELOP-ISSUE-CONTEXT, ADR-041-DEVELOP-BLOCK-TARGETS, ADR-044-DEVELOP-DOMAIN-GUIDANCE, ADR-084-DEVELOP-TARGET-SELECTION, ADR-090-DEVELOP-CWD-TARGET, ADR-093-DEVELOP-SESSION-TARGET, ADR-094-DEVELOP-SCRIPTS, ADR-095-DEVELOP-SOURCE-BASE, ADR-096-DEVELOP-STACK-CHECK

## Modes

For scoped work, prefer the appropriate mode over invoking `develop` directly:

- `develop feature` ([`feature/SKILL.md`](feature/SKILL.md)) — define and implement new behavior (new blocks, editor enhancements, behavior additions).
- `develop fix` ([`fix/SKILL.md`](fix/SKILL.md)) — reproduce and repair a described defect in a specified target.

Primarily touches `classes/` and `src/blocks/`.

All paths relative to `public/wp-content/plugins/ucsc-gutenberg-blocks/`.

## Launcher

- [`launcher.md`](launcher.md) — slash-command launcher (ADR-086): if a mode is
  given, run it; otherwise load [`skill-menu-mode.md`](skill-menu-mode.md) and
  show the mode menu before acting.

## Universal Command Intake

Resolve the target block/app, natural-language request, and optional Jira/GitHub issue from the context. Always ask one concise question only and wait for the answer before using tools if information is missing.
- For Jira/pasted details, see [references/issue-context.md](references/issue-context.md). Prompt for a jira id up front; it is preferred, not required. When atlassian mcp tools are available, fetch the jira record; when atlassian mcp tools are unavailable, paste the ticket details.
- For GitHub CLI/issues, see [references/github.md](references/github.md).
- For the block target session persistence contract, see [references/block-target-session.md](references/block-target-session.md).

Determine the block target in this order:
1. **Explicit ARGUMENTS** — named target wins.
2. **Persisted session value** — run `bash scripts/session-target.sh get`.
3. **CWD inference** — run `bash "${CLAUDE_PLUGIN_ROOT}/skills/develop/scripts/resolve-target.sh"`.
4. **Prompt** — require the user to choose a target from [references/targets.md](references/targets.md) (do not load all target references). Dynamic blocks render templates using [references/domain-blocks.md](references/domain-blocks.md).

Once resolved, persist it:
```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/develop/scripts/session-target.sh" set <slug> <repo> <abs-path>
```
Verify the WordPress/Gutenberg stack (ADR-096):
```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/develop/scripts/stack-check.sh" <target-path>
```

### Script Execution & Layout (ADR-094, ADR-095)
Use harness-expanded `${CLAUDE_PLUGIN_ROOT}`:
```bash
# Check session target
bash "${CLAUDE_PLUGIN_ROOT}/skills/develop/scripts/check-session-target.sh"
# Resolve source base path
bash "${CLAUDE_PLUGIN_ROOT}/skills/develop/scripts/source-base.sh" plugin-dir ucsc-blocks
# Inspect layout
bash "${CLAUDE_PLUGIN_ROOT}/skills/develop/scripts/inspect-block-layout.sh" ucsc-gutenberg-blocks
```

### Target references:
- **ucsc-gutenberg-blocks**: [accordion](references/target-accordion.md) | [campus-directory](references/target-campus-directory.md) | [class-schedule](references/target-class-schedule.md) | [content-sharer](references/target-content-sharer.md) | [course-catalog](references/target-course-catalog.md) | [events](references/target-events.md) | [feedback](references/target-feedback.md) | [news](references/target-news.md)
- **ucsc-blocks**: [calendar-feed](references/target-calendar-feed.md) | [ucsc-events](references/target-ucsc-events.md)
- **Domain refs**: [domain-blocks](references/domain-blocks.md) | [domain-blocks-reference](references/domain-blocks-reference.md) | [domain-detection](references/domain-detection.md) | [domain-stack-profile](references/domain-stack-profile.md)

## 1. Secure the Target and Feature Description

Before using tools, investigating, or writing code, obtain both required inputs from the user:

1. **Target** — the block, GUI, or app being worked on.
2. **Feature description** — what should be added or changed. A plain-language description is sufficient.

If either input is missing, ask one concise question for all missing inputs and wait for the answer. Prompt for a Jira ID up front in the same clarification when none was supplied. When Atlassian MCP tools are available and a Jira ID or URL is supplied, fetch the Jira record before implementation. When Atlassian MCP tools are unavailable, ask the user to paste the ticket details or summarize the relevant requirements. Jira is preferred, not required. See ADR-021 and ADR-009.

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

> **Never run `npm`, `wp-scripts`, `composer`, or PHP directly on the host.**
> This is a laptop **dev-only** environment — all build, test, and PHP execution
> go through Docker. Local Node/PHP is not the project toolchain (it will fail or
> mislead), and the real WordPress server is production, not Docker. The repo
> `README.md` is the source of truth for build/run.

Build through the Dockerized `run` driver (must complete without errors):

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/run/driver.sh" build   # Dockerized `npm run build`
```

Note: the plugin does not currently have a `test` script in `package.json`. If
Jest tests are added in the future, run them **in-container** (never host
`npm test`) and write tests in `src/blocks/__tests__/BlockName.test.js`.

## 10. Complete the Feature Phase

After implementing, remind the user that this change needs build verification
in the Docker environment with the `run` skill before it is treated as ready.

If applicable validation is complete and no Jira ID was captured, the completion summary may ask for it again. Do not repeat the prompt when an ID is already known, and do not treat a missing ID as incomplete work. See ADR-021.

Per ADR-023, offer to generate Conventional Commit syntax for the completed
feature. Generate message text only if the user accepts. Manual check-in is the
default: do not run `git add`, `git commit`, or equivalent staging/commit
operations unless the user explicitly asks. Never run `git push`,
`git push --force`, `git push --force-with-lease`, or equivalent remote-write
operations; provide the command or PR URL for the user to run instead.

## Examples

- [`examples/conventional-commit.md`](examples/conventional-commit.md) — copy-ready Conventional Commit message patterns for block features, fixes, tests, and chores

## Plugin-dev Tools

When this workflow creates or modifies plugin components (skills, manifest, hooks), use the following tools:

- **`plugin-dev:plugin-validator`** — validate plugin structure, manifest, and naming via `Agent` with `subagent_type: "plugin-dev:plugin-validator"`.
- **`plugin-dev:skill-reviewer`** — review skill quality and description effectiveness via `Agent` with `subagent_type: "plugin-dev:skill-reviewer"`.
- **`plugin-dev:skill-development`** — guidance on skill structure and frontmatter via `Skill` with `skill: "plugin-dev:skill-development"`.

## Supporting Files
- [scripts/block-target-check.sh](scripts/block-target-check.sh)
