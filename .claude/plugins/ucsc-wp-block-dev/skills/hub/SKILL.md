---
name: hub
description: This skill should be used when the user asks to "list skills", "what can you do", "show available commands", "what WordPress block skills are available", or invokes `:hub` (lists plugin inventory and handles session block target resolution).
version: 0.1.0
argument-hint: "[block]"
---

# Hub — ucsc-wp-block-dev skill list

<!-- doc-slide: Lists the plugin's skills and sets the session block target so later skills reuse it — it inventories, it does not route. -->

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

The tree below gives a compact form of each top-level skill's `argument-hint`.
Use `maintainer skill details [name]` for the full invocation settings
(`user-invocable`, model invocation, tools, context, and agent).

## Public workflows

The compact tree below lists each top-level skill with its argument hint and
nests public modes beneath their parent.

```text
skills
├─ hub       [block]                                   — list skills and set an optional session block target
├─ develop   [feature|fix] [block] [request]           — add or modify WordPress block code
│  ├─ feature  [block] [request]  — implement planned block behavior
│  └─ fix      [block] [problem]  — diagnose and repair a block defect
├─ feedback  [bug|idea|question] [note]                — report a bug or idea about the plugin skills
├─ review    [target] [focus]                          — review code for bugs, security, a11y, and tests
├─ run       [block] [change|URL]                      — launch and drive wp-dev.ucsc
├─ validate  [php|jest|e2e|all] [create|run] [target]  — create or run automated test suites
│  ├─ php   [create|run] [target]  — create or run PHP tests
│  ├─ jest  [create|run] [target]  — create or run Jest tests
│  ├─ e2e   [create|run] [target]  — create or run browser-driven tests
│  └─ all   [block]                — run PHP, Jest, and E2E sequentially
└─ verify    [block] [criterion]                       — confirm a change in the running app
```

The `[…]` syntax is a compact summary of the full `argument-hint` frontmatter,
which the `/` slash menu surfaces inline. The `hub` skill accepts one optional
`[block]` argument: when supplied, it validates the target and sets it as the
session value (see
[Current repository and its block targets](#current-repository-and-its-block-targets));
it still performs no routing.

## Block target

Most workflow skills — `develop` (+ `feature`/`fix`), `review`, `run`,
`validate`, and `verify` — operate on a **block target**: the canonical slug of
one block, optionally qualified by its repository and on-disk path. It is the
first positional argument (the `[block]` token) and a **persistent session
value** resolved once and reused across skills via the shared contract in
[`../develop/references/block-target-session.md`](../develop/references/block-target-session.md)
(ADR-093). Resolution order: explicit argument → persisted session value → cwd
inference → prompt from the [`targets.md`](../develop/references/targets.md) list.

The maintainer skill takes no block target — its target is the plugin itself
(ADR-085). `hub` does not *require* a target and **never prompts for one**, but
it can resolve, validate, and **set** the session target when one is supplied or
unambiguously inferred from the cwd — see
[Current repository and its block targets](#current-repository-and-its-block-targets).

## Current repository and its block targets

`:hub` resolves, validates, and **sets** the session block target so the next
workflow skill reuses it — but only when a target is **supplied or unambiguously
inferred from the cwd** (ADR-093, ADR-060 amendment). It never prompts for a
target and never blocks the inventory on a selection; setting that session value
is the only state `:hub` changes (no routing). When a block repo is on disk it
also shows that repo's available targets beside the inventory as information, not
a required choice.

For the full resolution and validation order — passed-target check, cwd auto-set,
listing targets from every present repo, and the persistence commands — read
[`references/repo-target.md`](references/repo-target.md).

The inventory tree is generated from
[`references/skill-tree.json`](references/skill-tree.json). Its `contexts`
field enforces the visibility policy: `maintainer` is excluded from the public
hub tree and appears only after the maintainer skill has been explicitly
invoked.

## Maintainer Workflows

Print this section only when `:hub` is shown from an active `maintainer`
workflow.

```text
maintainer  [mode] [submode|target]  — maintain this plugin package
├─ backlog                                           — build the personal and unimplemented-ADR backlog
├─ adr        [action] [ADR|decision]                — author, retire, inspect, and reconcile ADRs
├─ skill      [action] [name|candidate]              — maintain plugin skills, references, scripts, and inventory
│  ├─ details         [name]       — inspect live frontmatter and invocation settings
│  ├─ review          [name|all]   — run the opt-in qualitative skill reviewer
│  ├─ review-contrib  <candidate>  — review a proposed or incubating skill
│  ├─ promote         <candidate>  — promote an accepted candidate
│  └─ sync                         — reconcile skill inventories across docs and tests
├─ training   [goal]                                 — study upstream patterns and apply relevant lessons
├─ retro      [lesson|skill]                         — capture reusable session lessons
├─ self-test                                         — run pytest contracts and deterministic plugin checks
├─ validate   [tier1|tier2]                          — run structural validation; Tier 2 is opt-in
├─ docs       [update|check|publish [guide|slides]]  — regenerate portable guide+slides Markdown (publish is the optional final step)
│  ├─ update                   — regenerate the guide+slides artifacts from their sources (synonym for bare docs)
│  ├─ check                    — report whether generated docs are stale vs. their sources (git hash)
│  └─ publish  [guide|slides]  — publish both by default; name one to publish only that output
└─ all                                               — run the deterministic maintainer health checks
```

## Routing

To act on a request rather than list options, invoke the specific skill directly,
including its mode and block target when needed (e.g.
`ucsc-wp-block-dev:develop feature ucsc-events <description>`, where `ucsc-events`
is the block target — see [Block target](#block-target) above), or simply
describe the goal and let Claude select the skill from its description (ADR-061).
