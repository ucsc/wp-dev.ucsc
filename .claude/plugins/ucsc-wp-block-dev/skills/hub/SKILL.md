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
build it (ADR-058). It may, however, detect the current **repository** from the
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
the public workflow table below.

| Skill or mode | user-invocable | model-invocable | Discoverable | Documented in hub |
|---|---|---|---|---|
| `develop` | ✓ (default) | ✓ (default) | ✓ (default) | ✓ public |
| `develop feature` | mode | mode | via develop | ✓ public |
| `develop fix` | mode | mode | via develop | ✓ public |
| `hub` | ✓ (default) | ✓ (default) | ✓ (default) | ✓ public |
| `review` | ✓ (default) | ✓ (default) | ✓ (default) | ✓ public |
| `run` | ✓ (default) | ✓ (default) | ✓ (default) | ✓ public |
| `validate` | ✓ (default) | ✓ (default) | ✓ (default) | ✓ public |
| `validate create` | mode | mode | via validate | ✓ public |
| `validate run` | mode | mode | via validate | ✓ public |
| `verify` | ✓ (default) | ✓ (default) | ✓ (default) | ✓ public |

**Discoverable** = model sees the skill's description in context and may
auto-invoke it. Set `disable-model-invocation: true` to suppress this.
**user-invocable** = appears in the `/` slash menu. Set `user-invocable: false`
to hide from the menu while keeping model discoverability.

## Public workflows

| Skill or mode | Arguments | Purpose |
|---|---|---|
| `develop` | `[feature\|fix] [block] [description]` | Add or modify block code (PHP, template, JS editor, REST, build).<br>- `develop feature` - defining and implementing new behavior<br>- `develop fix` - reproducing and repairing defects |
| `review` | `[block \| PR \| branch \| file \| diff] [focus]` | Review a diff, branch, file, PR, or Jira-scoped change for bugs, regressions, security, a11y, and missing tests. |
| `run` | `[block] [start\|build\|watch\|open]` | Build, launch, and drive the plugin in the wp-dev.ucsc Docker environment. |
| `validate` | `[create\|run] [block \| feature \| Jira]` | Create or run automated PHP, Jest, or e2e tests.<br>- `validate create` - creating automated PHP, Jest, or e2e tests<br>- `validate run` - running existing automated PHP, Jest, or e2e tests |
| `verify` | `[block] [behavior or acceptance criterion]` | Live DOM test of a change or acceptance criterion in the running WordPress editor or frontend. |

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
(ADR-085). `hub` does not *require* a target, but it can resolve, validate, and
**set** the session target as a convenience — see
[Current repository and its block targets](#current-repository-and-its-block-targets).

## Current repository and its block targets

`:hub` resolves, validates, and **sets** the session block target so the next
workflow skill reuses it instead of making the user re-specify it (ADR-093,
ADR-060 amendment). Setting that session value is the only state `:hub` changes;
it still does not invoke a workflow skill (no routing). Resolution and
validation order:

1. **Target passed to `:hub`** — when the user supplies a block (e.g.
   `:hub ucsc-events`), validate it before adopting it. Resolve its repo and
   on-disk path from
   [`../develop/references/targets.md`](../develop/references/targets.md), then
   confirm it is a real block:

   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/skills/develop/scripts/block_target_check.sh" <block-dir-or-file>
   ```

   On PASS, persist it (below); on FAIL, report the target as invalid and fall
   through to CWD detection rather than persisting a bogus value.

2. **CWD detection** — otherwise detect the repo and slug from the
   working-directory path string (token-free, no globbing) and persist when a
   slug resolves:

   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/skills/develop/scripts/resolve_target.sh" --persist
   ```

   It prints `<slug> <repo> <path>`. Use the `<repo>` field to scope the offer:

   - **`ucsc-blocks`** — directory blocks under `src/blocks/<slug>/`.
   - **`ucsc-gutenberg-blocks`** — single-file blocks `src/blocks/<Name>.js`.
   - **Neither** (exit 3, or a repo not listed) — say the cwd is not inside a
     known block repo and offer targets from both repos.

3. **Offer the repo's targets** — list the matching repo's targets from
   `targets.md` (the canonical, drift-free source) and let the user pick one.
   On selection, persist it.

Persist a resolved or chosen target with the ADR-093 contract so every later
skill reuses it without re-asking:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/develop/scripts/session_target.sh" set <slug> <repo> <abs-path>
```

Once set, show the target at the top of the inventory and frame the workflow
list around it (e.g. "what the plugin can do with `<slug>` as the target"). The
user then invokes a workflow skill to act — `:hub` itself never invokes one.

## Maintainer Workflows

Print this section only when `:hub` is shown from an active `maintainer`
workflow.

| Skill or mode | Purpose |
|---|---|
| `maintainer` | User-invocable plugin maintenance skill for validation, skill upkeep, ADRs, docs, and release readiness; model auto-invocation is disabled. |
| `maintainer backlog` | Generate the combined personal worklist plus unimplemented active ADR backlog. |
| `maintainer adr` | Create or update ADRs, preferring updates to existing skill ADRs when they fit. |
| `maintainer skill` | Inspect, review, promote, or synchronize plugin skills through focused submodes. |
| `maintainer training` | Study selected upstream plugin/skill examples and apply relevant lessons when requested. |
| `maintainer retro` | Capture reusable session lessons through the hidden retrospective sub-workflow. |
| `maintainer validate` | Run the CLI structural validator, then offer the token-heavy plugin-dev semantic review only if wanted. |
| `maintainer self-test` | Run pytest contracts plus deterministic plugin/skill best-practice checks; does not test WordPress block targets or the GUI app. |
| `maintainer review-skills` | Opt-in token-heavy skill quality review through the plugin-dev skill reviewer. |
| `maintainer review-contrib` | Review a proposal or incubator candidate under `contrib/`. |
| `maintainer promote-contrib` | Promote a reviewed incubator candidate into the live `skills/` inventory. |
| `maintainer check-references` | Verify each skill support file is linked from its parent `SKILL.md`. |
| `maintainer check-adr-implements` | Verify `implements:` ADR markers resolve to active ADRs and report coverage. |
| `maintainer generate-docs` | Regenerate portable Markdown documentation artifacts without publishing. |
| `maintainer publish` | Publish maintainer-owned slides, docs, or both after explicit target selection. |
| `maintainer sync-inventory` | Reconcile README, AGENTS.md, hub, deck, and test inventory lists. |
| `maintainer skill-details` | Show live frontmatter and invocation settings for every skill. |
| `maintainer all` | Run token-frugal deterministic maintainer checks in order. |

## Routing

To act on a request rather than list options, invoke the specific skill directly,
including its mode and block target when needed (e.g.
`ucsc-wp-block-dev:develop feature ucsc-events <description>`, where `ucsc-events`
is the block target — see [Block target](#block-target) above), or simply
describe the goal and let Claude select the skill from its description (ADR-061).
