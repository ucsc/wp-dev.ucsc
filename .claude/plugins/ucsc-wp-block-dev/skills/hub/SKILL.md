---
name: hub
description: This skill should be used when the user asks to "list skills", "what can you do", "show available commands", "what WordPress block skills are available", or invokes `:hub`. Lists the plugin inventory and can resolve, validate, and set the session block target (from a passed target or the current repo) so later skills reuse it; it does not route — to act, invoke the relevant skill directly.
argument-hint: "[block]"
---

# Hub — ucsc-wp-block-dev skill list

## Implements

implements: ADR-013-HUB-README, ADR-060-HUB-LIST-SKILLS, ADR-061-HUB-NATIVE-DISCOVERY, ADR-088-HUB-SKILL-MODES

`:hub` is the plugin's inventory: it lists what `ucsc-wp-block-dev` can do. It
does **not** parse a request or route it — Claude routes natively from each
skill's `description` (ADR-061). Print the public workflow tables below as-is;
this is a static inventory, so do not scan the filesystem or spawn agents to
build it (ADR-003). It may, however, detect the current **repository** from the
working-directory path string — a token-free string operation, not a filesystem
scan — to offer that repo's block targets (ADR-060 amendment); see
[Current repository and its block targets](#current-repository-and-its-block-targets).

When `:hub` is shown while the `maintainer` skill is already active, also print
the "Maintainer workflows" section below. Otherwise omit that section; the
general hub stays focused on product workflows (ADR-089).

The plugin ships **skills only** (no separate `commands/` directory); every
entry is invoked as `ucsc-wp-block-dev:<name>`.

## Skill invocation settings

All skills currently run on platform defaults. "Documented in hub" is a
convention — not a frontmatter field — controlling whether a skill appears in
the public workflow table below. The **Argument hint** column reproduces each
top-level skill's `argument-hint` frontmatter exactly; pipes are escaped only
because this is a Markdown table.

| Skill or mode | Argument hint | user-invocable | model-invocable | Discoverable | Documented in hub |
|---|---|---|---|---|---|
| `develop` | `[feature\|fix] [block] [description or Jira/GitHub URL or ID]` | ✓ (default) | ✓ (default) | ✓ (default) | ✓ public |
| `develop feature` | `[block] [feature description] [Jira or GitHub URL/ID]` | mode | mode | via develop | ✓ public |
| `develop fix` | `[block] [problem description] [Jira or GitHub URL/ID]` | mode | mode | via develop | ✓ public |
| `feedback` | `[bug\|idea\|question] [note]` | ✓ (default) | ✓ (default) | ✓ (default) | ✓ public |
| `hub` | `[block]` | ✓ (default) | ✓ (default) | ✓ (default) | ✓ public |
| `review` | `[block\|PR\|branch\|file\|diff] [bugs\|security\|a11y\|tests\|all]` | ✓ (default) | ✓ (default) | ✓ (default) | ✓ public |
| `run` | `[block] [change to demonstrate or URL]` | ✓ (default) | ✓ (default) | ✓ (default) | ✓ public |
| `validate` | `[php\|jest\|e2e\|all] [create\|run] [block\|feature\|Jira]` | ✓ (default) | ✓ (default) | ✓ (default) | ✓ public |
| `validate php` | `[create\|run] [block\|feature\|Jira]` | mode | mode | via validate | ✓ public |
| `validate jest` | `[create\|run] [block\|feature\|Jira]` | mode | mode | via validate | ✓ public |
| `validate e2e` | `[create\|run] [block\|feature\|Jira]` | mode | mode | via validate | ✓ public |
| `validate all` | `[block]` | mode | mode | via validate | ✓ public |
| `verify` | `[block] [change or acceptance criterion]` | ✓ (default) | ✓ (default) | ✓ (default) | ✓ public |

**Discoverable** = model sees the skill's description in context and may
auto-invoke it. Set `disable-model-invocation: true` to suppress this.
**user-invocable** = appears in the `/` slash menu. Set `user-invocable: false`
to hide from the menu while keeping model discoverability.

## Public workflows

Each skill is listed with its argument hint and purpose; a skill's modes are
indented beneath it.

- **`develop`** — `[feature|fix] [block] [description or Jira/GitHub URL or ID]` — Add or modify block code (PHP, template, JS editor, REST, build).
  - **`feature`** — `[block] [feature description] [Jira or GitHub URL/ID]` — Define and implement new behavior: a new block, editor control, or frontend output.
  - **`fix`** — `[block] [problem description] [Jira or GitHub URL/ID]` — Reproduce and repair a described defect in a specified target.
- **`feedback`** — `[bug|idea|question] [note]` — Report a bug or suggestion about the plugin's skills (the `/bug` analog); delivers to a configured endpoint/email or saves a local copy.
- **`review`** — `[block|PR|branch|file|diff] [bugs|security|a11y|tests|all]` — Review a diff, branch, file, PR, or Jira-scoped change for bugs, regressions, security, a11y, and missing tests.
- **`run`** — `[block] [change to demonstrate or URL]` — Launch and drive the app to see a change working.
- **`validate`** — `[php|jest|e2e|all] [create|run] [block|feature|Jira]` — Create or run automated PHP, Jest, or e2e tests.
  - **`php`** — `[create|run] [block|feature|Jira]` — Render callbacks, sanitization, REST routes, and transient/cache behavior.
  - **`jest`** — `[create|run] [block|feature|Jira]` — Block registration, attributes, editor controls, and client behavior.
  - **`e2e`** — `[create|run] [block|feature|Jira]` — Editor insertion and frontend rendering driven through a real browser.
  - **`all`** — `[block]` — Run every suite sequentially (PHP -> Jest -> E2E) in one agent (ADR-101).
- **`verify`** — `[block] [change or acceptance criterion]` — Build and run the app to confirm a specific change without substituting tests or type checks.

The `[…]` argument syntax mirrors each skill's `argument-hint` frontmatter, which
the `/` slash menu surfaces inline. The `hub` skill accepts one optional
`[block]` argument: when supplied, it validates the target and sets it as the
session value (see
[Current repository and its block targets](#current-repository-and-its-block-targets));
it still performs no routing.

## Block target

Most workflow skills — `develop` (+ `feature`/`fix`), `review`, `run`,
`validate`, and `verify` — operate on a **block target**: the canonical slug of
one block, optionally qualified by its repository and on-disk path. The target is
the first positional argument in the syntax above (the `[block]` token).

The target is a **persistent session value** resolved once and reused across
skills via the shared contract in
[`../develop/references/block-target-session.md`](../develop/references/block-target-session.md)
(ADR-093). Resolution order: explicit argument → persisted session value → cwd
inference → prompt from the [`targets.md`](../develop/references/targets.md) list.
Known block-hosting repos:

- `ucsc-blocks` — `src/blocks/<slug>/` (e.g. `ucsc-events`, `calendar-feed`)
- `ucsc-gutenberg-blocks` — `src/blocks/<Name>.js`

The maintainer skill takes no block target — its target is the plugin itself
(ADR-085). `hub` does not *require* a target and **never prompts for one**, but
it can resolve, validate, and **set** the session target as a convenience when
one is supplied or unambiguously inferred from the cwd — see
[Current repository and its block targets](#current-repository-and-its-block-targets).

## Current repository and its block targets

`:hub` resolves, validates, and **sets** the session block target so the next
workflow skill reuses it instead of making the user re-specify it (ADR-093,
ADR-060 amendment) — but only when a target is **supplied or unambiguously
inferred from the cwd**. The block target is **optional** for `:hub`: it never
prompts for a target and never blocks the inventory on a target selection.
Setting that session value is the only state `:hub` changes; it still does not
invoke a workflow skill (no routing). Resolution and validation order:

1. **Target passed to `:hub`** — when the user supplies a block (e.g.
   `:hub ucsc-events`), validate it before adopting it. Resolve its repo and
   on-disk path from
   [`../develop/references/targets.md`](../develop/references/targets.md), then
   confirm it is a real block:

   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/skills/develop/scripts/block-target-check.sh" <block-dir-or-file>
   ```

   On PASS, persist it (below); on FAIL, report the target as invalid and fall
   through to CWD detection rather than persisting a bogus value.

2. **CWD auto-set** — otherwise detect the repo and slug from the
   working-directory path string (token-free, no globbing) and, **only when a
   single slug resolves**, persist it:

   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/skills/develop/scripts/resolve-target.sh" --persist
   ```

   It prints `<slug> <repo> <path>`. A resolved slug auto-sets the session
   target; it does **not** scope which repos appear in the list below. When no
   single slug resolves (e.g. the cwd is a repo root, or exit 3), set nothing and
   fall through to step 3.

3. **List targets from every block repo that exists (no prompt)** — independent
   of the cwd, list the block targets for each known repo **that is present on
   disk**, and omit any repo that is absent. Check presence cheaply (a directory
   test, not a scan):

   ```bash
   plugins="$(bash "${CLAUDE_PLUGIN_ROOT}/skills/develop/scripts/source-base.sh" wp-plugins)"
   for repo in ucsc-blocks ucsc-gutenberg-blocks; do
     [ -d "$plugins/$repo" ] && echo "present: $repo"
   done
   ```

   For each repo reported `present:`, list that repo's targets from
   [`targets.md`](../develop/references/targets.md) (the canonical, drift-free
   source). If both repos exist, include both — the `ucsc-blocks` blocks **and**
   the `ucsc-gutenberg-blocks` blocks. If only one exists, list only that one. If
   neither is present, say no block repo is on disk and list no targets. This is
   an **informational** list shown beside the inventory: `:hub` leaves the
   session target unset and never blocks on a selection. The user may run
   `:hub <block>` or name the target when invoking a workflow skill. Listing
   available targets is not the same as requiring a selection.

When a target is resolved by step 1 or step 2, persist it with the ADR-093
contract so every later skill reuses it without re-asking:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/develop/scripts/session-target.sh" set <slug> <repo> <abs-path>
```

When a target was set (step 1 or 2), show it at the top of the inventory and
frame the workflow list around it (e.g. "what the plugin can do with `<slug>` as
the target"). When none was set, just show the inventory. Either way the user
then invokes a workflow skill to act — `:hub` itself never invokes one.

## Maintainer Workflows

Print this section only when `:hub` is shown from an active `maintainer`
workflow.

| Skill or mode | Arguments | Purpose |
|---|---|---|
| `maintainer` | `[backlog\|adr\|skill\|training\|retro\|self-test\|validate\|generate-docs\|publish\|all] [submode or target]` | User-invocable plugin maintenance skill for validation, skill upkeep, ADRs, docs, and release readiness; model auto-invocation is disabled. |
| `maintainer backlog` | — | Generate the combined personal worklist plus unimplemented active ADR backlog. |
| `maintainer adr` | `[create\|update\|inspect\|reconcile\|index] [ADR or decision]` | Create or update ADRs, preferring updates to existing skill ADRs when they fit. |
| `maintainer skill` | `[details\|review\|review-contrib\|promote\|sync] [name or candidate]` | Inspect, review, promote, or synchronize plugin skills through focused submodes. |
| `maintainer training` | `[goal] [from upstream examples]` | Study selected upstream plugin/skill examples and apply relevant lessons when requested. |
| `maintainer retro` | `[lesson or target skill]` | Capture reusable session lessons through the hidden retrospective sub-workflow. |
| `maintainer self-test` | — | Run pytest contracts plus deterministic plugin/skill best-practice checks; does not test WordPress block targets or the GUI app. |
| `maintainer validate` | `[tier1\|tier2]` | Run the CLI structural validator, then offer the token-heavy plugin-dev semantic review only if wanted. |
| `maintainer generate-docs` | — | Regenerate portable Markdown documentation artifacts without publishing. |
| `maintainer publish` | `[guide\|deck\|all]` | Publish maintainer-owned slides, docs, or both after explicit target selection. |
| `maintainer all` | — | Run token-frugal deterministic maintainer checks in order. |

## Routing

To act on a request rather than list options, invoke the specific skill directly,
including its mode and block target when needed (e.g.
`ucsc-wp-block-dev:develop feature ucsc-events <description>`, where `ucsc-events`
is the block target — see [Block target](#block-target) above), or simply
describe the goal and let Claude select the skill from its description (ADR-061).
