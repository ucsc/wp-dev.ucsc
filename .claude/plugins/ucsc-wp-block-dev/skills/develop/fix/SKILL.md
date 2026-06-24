---
name: fix
description: This skill should be used when the user asks to "fix a block", "debug an issue", "something is broken", "block not showing", "wrong output", or reports any defect in a ucsc-gutenberg-blocks block, GUI, or app. Require the target and a plain-language problem description before investigating.
argument-hint: "[block] [problem description] [Jira or GitHub URL/ID]"
---

# Fix — Debug a Block Issue

## Implements

implements: ADR-007-FIX-PROBLEM, ADR-008-FIX-JIRA, ADR-009-FIX-INTAKE, ADR-010-FIX-JIRA-REPEAT, ADR-026-FIX-TOKEN-STUDY, ADR-036-FIX-WORKFLOW, ADR-059-FIX-RETROSPECTIVE, ADR-093-FIX-BLOCK-TARGET

Systematic flow for diagnosing and fixing failures in `ucsc-gutenberg-blocks`.

Primarily touches `classes/` and `src/`.

All paths relative to `public/wp-content/plugins/ucsc-gutenberg-blocks/` unless noted.

## Universal Command Intake

Resolve the target, natural-language problem description, and an optional issue
reference — a **Jira key/URL or a GitHub issue/PR URL or ID** — from the full
input and session context, regardless of order. Preserve explicit user
instructions and ask one concise question only when missing or conflicting
information blocks the fix workflow.

When Jira, Confluence, pasted ticket details, or issue normalization applies,
read
[`../references/issue-context.md`](../references/issue-context.md)
before investigating. When a **GitHub issue or PR** is supplied as the scope,
fetch it for context (GitHub MCP → `gh` → REST, per
[`../references/github.md`](../references/github.md)) the same way a Jira ticket
is fetched before investigating.

# Note on relative references
The references above use a relative path into `develop/references/`. This is an
intentional dependency but fragile to directory moves/renames. Consider
promoting shared references (issue-context.md, targets.md) to a plugin-level
`skills/shared/references/` to avoid breakage. Maintain awareness when
renaming directories.

Resolve known block targets through
[`../references/targets.md`](../references/targets.md)
and read only the selected target reference.

## 1. Secure the Target and Fix Description

Before using tools or investigating, obtain both required inputs from the user:

1. **Target** — the block, GUI, or app being worked on.
2. **Fix description** — what needs to be fixed. A plain-language description is sufficient.

A target alone is not sufficient, and a description without a target is not sufficient. A Jira ID alone is also insufficient unless its available details clearly supply both. If either required input is missing, ask one concise question for all missing inputs and wait for the answer.

**Block target (ADR-093).** The target is a persistent session value shared
across skills. Resolve it with the shared contract in
[`../references/block-target-session.md`](../references/block-target-session.md):
ARGUMENTS → persisted session value (`../scripts/session_target.sh get`) → cwd
inference → prompt. Validate an inferred directory with
`../scripts/block_target_check.sh` before adopting it, and persist a newly
resolved target with `session_target.sh set` so later skills reuse it without
re-asking.

Prompt for a Jira ID up front. If none was supplied, include the Jira request in
the same clarification as the concrete-problem question. When Atlassian MCP
tools are available and a Jira ID or URL is supplied, fetch the Jira record
before reproducing. When Atlassian MCP tools are unavailable, ask the user to
paste the ticket details or summarize the relevant requirements. The user may
say there is no ticket or skip it; Jira is preferred, not required. See ADR-008.

Do not inspect source files, logs, git history, browser or runtime state, builds, or tests until this gate is satisfied. See ADR-007 and ADR-009.

## 2. Reproduce First

Establish the smallest reproduction before changing anything:

- **Jest failure** — if a `test` script exists in `package.json`, run it **in-container** (never host `npm test`) and capture the exact failing assertion and file
- **Build error** — build via Docker (`bash "${CLAUDE_PLUGIN_ROOT}/skills/run/driver.sh" build`) and read the webpack/babel error
- **Browser block error** — open browser devtools console on the editor page; capture the exact JS error
- **PHP/REST error** — check `wp-dev.ucsc/` logs or run `docker compose exec wpcli wp --debug`
- **Blank/wrong output** — confirm the block is activated and the build is current

## 3. Identify the Layer

| Symptom | Likely layer | Where to look |
|---|---|---|
| Block not in inserter | JS registration | `src/index.js` import, `src/blocks/<BlockName>.js` `registerBlockType` call |
| Editor JS error | Block edit() component | `src/blocks/<BlockName>.js`, browser console stack trace |
| Build fails | Webpack/Babel | webpack error output, check `import` paths and JSX syntax |
| Jest test fails (only if a `test` script exists) | Unit test | `src/blocks/__tests__/<BlockName>.test.js` |
| Frontend renders blank | PHP render | `classes/<BlockName>.php` `render()`, `templates/<block-name>.php` |
| API data missing | REST route | `classes/<BlockName>.php` `register_routes()` / `get_data()`, transient cache |
| LDAP data wrong | CampusDirectoryAPI | `classes/CampusDirectoryAPI.php`, `DOCKER_DEV` env, transient flush |
| PeopleSoft data stale | Transient cache | `wp transient delete --all` then retry |

## 4. Read Before Patching

Before editing, check the current Git branch. Per ADR-047, if it is `main`,
`master`, or `develop`, warn that changes should normally happen on a feature
branch named `dev/developer_name/ISSUE-1234_short_desc`. Do not create or
switch branches unless the user explicitly asks.

Read the relevant class and JS file fully before editing. Check:

- Is the block registered in `index.php` and `src/index.js`?
- Does the PHP class `register_block_type` attribute schema match the JS `attributes` definition?
- Are transients being set and read with matching keys?
- Is all output escaped?

## 5. Minimal Patch

Make the smallest change that fixes the reproduction. Do not refactor surrounding code during a fix.

If the fix touches the attribute schema (PHP ↔ JS), update both sides together — schema drift is a common source of silent bugs.

## 6. Validate

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
one exists, run it **in-container** (never host `npm test`) to check for
regressions.

For PHP issues, verify in Docker:

```bash
docker compose exec wpcli wp eval 'echo "ok";'
```

Visit the block editor and confirm the block renders correctly.

## 7. Transient / Cache Gotchas

If API data looks wrong after a fix:

```bash
docker compose exec wpcli wp transient delete --all
```

Then reload the page. Stale transients are the most common cause of "I fixed it but the output didn't change."

## 8. LDAP in Local Docker

Campus Directory uses anonymous LDAP bind when `DOCKER_DEV=docker_dev` is set. If LDAP lookups fail locally but pass in production, check:

```bash
docker compose exec wpcli printenv DOCKER_DEV
```

If missing, add it to the service env in `docker-compose.yml`.

## 9. Verify in Docker

After fixing, prove the behavior change in the running environment with the `verify`
skill. Use `run` only if the environment is not already up.

## 10. Complete the Fix Phase

Summarize the completed fix and validation. If no Jira ID was captured, the completion summary may ask for it again. Do not repeat the prompt when an ID is already known, and do not treat a missing ID as incomplete work. See ADR-010.

Per ADR-051, offer to generate Conventional Commit syntax and automatically commit the completed
fix. Generate message text only if the user accepts. Manual check-in is the
default: do not run `git add`, `git commit`, or equivalent staging/commit
operations unless the user explicitly asks. Never run `git push`,
`git push --force`, `git push --force-with-lease`, or equivalent remote-write
operations; provide the command or PR URL for the user to run instead.

## Plugin-dev Tools

When this workflow creates or modifies plugin components (skills, manifest, hooks), use the following tools:

- **`plugin-dev:plugin-validator`** — validate plugin structure, manifest, and naming via `Agent` with `subagent_type: "plugin-dev:plugin-validator"`.
- **`plugin-dev:skill-reviewer`** — review skill quality and description effectiveness via `Agent` with `subagent_type: "plugin-dev:skill-reviewer"`.
- **`plugin-dev:skill-development`** — guidance on skill structure and frontmatter via `Skill` with `skill: "plugin-dev:skill-development"`.
