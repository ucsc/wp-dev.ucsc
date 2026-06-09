---
name: develop
description: This skill should be used when the user asks to "add a block", "create a Gutenberg block", "implement a feature", "modify block code", "extend a block", or when feature/fix scope is already defined and implementation is ready to begin on ucsc-gutenberg-blocks.
argument-hint: "[feature|fix] [block] [description or Jira/GitHub URL or ID]"
---

# Develop — Add a Block or Feature

<!-- doc-slide: Adds or modifies block code — `feature` plans and builds new behavior, `fix` reproduces and repairs a described defect. -->

Guided flow for adding a new Gutenberg block or extending an existing one in `ucsc-gutenberg-blocks`.

## Implements

implements: ADR-001-DEVELOP-PLUGIN-SCOPE, ADR-006-DEVELOP-WP-EXAMPLES, ADR-008-DEVELOP-JIRA, ADR-009-DEVELOP-INTAKE, ADR-010-DEVELOP-JIRA-REPEAT, ADR-021-DEVELOP-REFERENCES, ADR-036-DEVELOP-FIX-FEATURE, ADR-040-DEVELOP-ISSUE-CONTEXT, ADR-041-DEVELOP-BLOCK-TARGETS, ADR-044-DEVELOP-DOMAIN-GUIDANCE, ADR-084-DEVELOP-TARGET-SELECTION, ADR-090-DEVELOP-CWD-TARGET, ADR-093-DEVELOP-SESSION-TARGET, ADR-094-DEVELOP-SCRIPTS, ADR-095-DEVELOP-SOURCE-BASE, ADR-096-DEVELOP-STACK-CHECK

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

Resolve the target, natural-language feature request, and an optional issue
reference — a **Jira key/URL or a GitHub issue/PR URL or ID** — from the full
input and session context, regardless of order. Preserve explicit user
instructions and ask one concise question only when missing or conflicting
information blocks the workflow.

When Jira, Confluence, pasted ticket details, or issue normalization applies,
read [`references/issue-context.md`](references/issue-context.md) and merge its
compact implementation brief into this workflow.

When a **GitHub issue or PR is supplied as the work scope**, fetch it for
context (GitHub MCP → `gh` → REST), and when GitHub CLI tooling is needed for
pull request creation or inspection, read
[`references/github.md`](references/github.md) before proceeding.

Before using tools, determine the target. The block target is a **persistent
session value** shared across skills (ADR-093) — see
[`references/block-target-session.md`](references/block-target-session.md) for the
full contract. Resolve it in this order:

1. **Explicit ARGUMENTS** — a target named in the arguments always wins and
   replaces any persisted value.
2. **Persisted session value** — else reuse the stored target without re-asking
   (`bash scripts/session-target.sh get`).
3. **CWD inference** — else infer from the working directory with
   `bash "${CLAUDE_PLUGIN_ROOT}/skills/develop/scripts/resolve-target.sh` (a
   `.../src/blocks/<slug>` segment, or a directory matching a slug in
   [`references/targets.md`](references/targets.md)); it resolves
   `<slug> <repo> <path>` deterministically with no token cost. State the inferred
   target so the user can correct it.
4. **Prompt** — only when ambiguous or empty, require the user to choose a target.

When a target is newly resolved or changed (steps 1, 3, 4), persist it with
`bash scripts/session-target.sh set <slug> <repo> <abs-path>` — specify the
repository and the target both, and record the filesystem path (ADR-093). Resolve known slugs and
aliases through [`references/targets.md`](references/targets.md), then read only
the selected target reference. Do not load all target references.
(ADR-084 selection contract, refined by ADR-090 CWD inference and ADR-093 session
persistence.)

**Stack sanity check (ADR-096).** This plugin was forked from the Laravel+Vue
sibling `ucsc-laravel-vue-dev` and shares the same skill names, so the wrong
plugin can load against a repo silently. Once per session — when the target is
first resolved or changes — confirm the codebase is WordPress/Gutenberg before
acting:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/develop/scripts/stack-check.sh" <target-path>
```

It exits 0 on a WordPress match or an ambiguous/undetectable stack (printing a
warning), and exits 3 only on a clear mismatch (Laravel/Vue signals, no
WordPress). On a mismatch, surface it and recommend switching to
`ucsc-laravel-vue-dev` rather than proceeding; on ambiguity, confirm the target
with the user. Do not hard-block an ambiguous stack.

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

Target resolution (ADR-093):

- [`references/block-target-session.md`](references/block-target-session.md) — persistent session-target contract (shared by feature/fix/run/validate/verify/review)
- [`scripts/session-target.sh`](scripts/session-target.sh) — get/set/clear the session target cache
- [`scripts/block-target-check.sh`](scripts/block-target-check.sh) — cheap check that a path is a real block code set, not just a folder
- [`scripts/resolve-target.sh`](scripts/resolve-target.sh) — zero-token CWD inference: derive `<slug> <repo> <path>` from a path string, validate, optional `--persist` (the ADR-093 step 3)
- [`scripts/check-session-target.sh`](scripts/check-session-target.sh) — one-call wrapper that reports the session target (ADR-094)
- [`scripts/stack-check.sh`](scripts/stack-check.sh) — once-per-session WordPress-vs-Laravel stack sanity check; warns on mismatch (ADR-096)

**Script execution (ADR-094).** Issue script commands with the harness-expanded
`${CLAUDE_PLUGIN_ROOT}` absolute path — do not assign script paths to temporary
shell variables (shell state does not persist between calls) or rely on the cwd.
For the session-target checks, run the single wrapper rather than a sequence of
ad-hoc commands:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/develop/scripts/check-session-target.sh"
```

**Source base (ADR-095).** Never hardcode an absolute base path like
`/Users/.../wp-dev.ucsc/...` and never hand-roll `find`/`ls` exploration in a
command. Resolve locations through the source-base resolver, and inspect a
plugin's block layout with the reusable inspector (quoted, `node_modules` pruned):

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/develop/scripts/source-base.sh" plugin-dir ucsc-blocks
bash "${CLAUDE_PLUGIN_ROOT}/skills/develop/scripts/inspect-block-layout.sh" ucsc-gutenberg-blocks
```

- [`scripts/source-base.sh`](scripts/source-base.sh) — resolve repo-root / plugin-root / wp-plugins / plugin-dir (ADR-095)
- [`scripts/inspect-block-layout.sh`](scripts/inspect-block-layout.sh) — safe block-layout inspection for either repo (ADR-095)

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

If applicable validation is complete and no Jira ID was captured, the completion summary may ask for it again. Do not repeat the prompt when an ID is already known, and do not treat a missing ID as incomplete work. See ADR-010.

Per ADR-051, offer to generate Conventional Commit syntax for the completed
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
