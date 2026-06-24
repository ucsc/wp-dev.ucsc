---
name: maintainer
description: This skill should be used when the user asks to "maintain the plugin", "validate the plugin structure", "run the plugin self-tests", "review or promote a skill", "check ADR consistency", "study upstream plugin patterns", "publish the maintainer docs", or prepare ucsc-wp-block-dev for release.
argument-hint: "[backlog|adr|skill|training|retro|self-test|validate|generate-docs|publish|all] [submode or target]"
disable-model-invocation: true
user-invocable: true
allowed-tools:
  - bash
  - grep
  - python
  - docker
  - docker-compose
  - wp
  - jq
  - sed
---

# Maintainer — ucsc-wp-block-dev

## Implements

implements: ADR-003-PLUGIN-LOW-TOKEN, ADR-004-MAINTAINER-VALIDATION, ADR-015-MAINTAINER-SLIDE-DATE, ADR-016-MAINTAINER-NO-BUNDLED-PYTHON, ADR-017-MAINTAINER-AGENTS-SYMLINKS, ADR-018-MAINTAINER-SLIDE-DECK, ADR-020-MAINTAINER-MENU, ADR-027-MAINTAINER-MCP-TOKEN-COST, ADR-028-MAINTAINER-JIT-MCP, ADR-032-MAINTAINER-REFERENCE-CHECKS, ADR-033-MAINTAINER-WORKLIST, ADR-038-MAINTAINER-CONTRIB, ADR-045-MAINTAINER-GENERATE-DOCS, ADR-048-MAINTAINER-GENERATE-DOCS-ADRS, ADR-063-MAINTAINER-PUBLISH, ADR-064-MAINTAINER-OPT-IN-AGENTS, ADR-065-MAINTAINER-NEW-ADR, ADR-067-MAINTAINER-SYNC-INVENTORY, ADR-070-MAINTAINER-FRONTMATTER, ADR-071-MAINTAINER-SKILL-DETAILS, ADR-072-MAINTAINER-SKILL-DISPLAY, ADR-075-MAINTAINER-SINGLE-AGENT, ADR-076-MAINTAINER-TOKEN-LOG, ADR-078-MAINTAINER-CLI-VALIDATE, ADR-079-MAINTAINER-PLUGIN-DEV, ADR-080-MAINTAINER-AGENTS-INVENTORY, ADR-081-MAINTAINER-SUB-SKILLS, ADR-083-MAINTAINER-RETROSPECTIVE, ADR-085-MAINTAINER-TARGET, ADR-086-MAINTAINER-CONVENTIONS, ADR-089-MAINTAINER-PUBLIC-SLASH, ADR-099-MAINTAINER-RETRO-MODE-ORCHESTRATION-WRAPPER-SCRIPTS

This body marker traces the skill to the ADRs it implements (ADR-086, decision C).
`scripts/check-adr-implements.py` validates that every referenced ADR is active.
`maintainer` is the pilot skill for this convention before wider rollout.

Maintenance workflow for the `ucsc-wp-block-dev` plugin (not for block code —
use `develop`/`develop fix`/`run` for that). Invoke as `maintainer`. For
Markdown artifact regeneration, read
[`references/generate-docs.md`](references/generate-docs.md).

Use this skill with one mode: `backlog`, `adr`, `skill`, `training`, `retro`,
`self-test`, `validate`, `generate-docs`, `publish` (bare = both; or
`guide`/`deck`), or `all`. Detailed compatibility modes: `review-skills`,
`review-contrib`, `promote-contrib`, `check-references`, `check-adr-implements`,
`sync-inventory`, and `skill-details`. `test` remains a legacy alias for
`self-test`; `new-adr` remains a legacy alias for `adr`. Run all commands below
from the repo root.

To work on the plugin itself, launch Claude Code from the repo root with the
plugin loaded directly from its development directory:

```bash
claude --plugin-dir .claude/plugins/ucsc-wp-block-dev
```

This loads the in-tree plugin (skills, agents, hooks) so maintainer edits take
effect without installing from a marketplace.

Keep token use low: run the validator and tests rather than reading every file by hand. See ADR-003 (low token use, single-agent default).

## Maintainer checklist

Use `references/maintainer-checklist.md` for a compact reviewer checklist that consolidates plugin-dev and skill-creator best practices. Run it before `validate` or `publish` operations.

Per ADR-073, all plugin operations are scoped to `.claude/plugins/ucsc-wp-block-dev/`. Ignore `.agents/` — it holds legacy tooling unrelated to this plugin.

## Sub-workflows

Plugin self-maintenance also includes capturing session lessons back into the
skills:

- [`launcher.md`](launcher.md) — maintainer slash-command launcher; if a mode is
  provided, run it, otherwise load `skill-menu-mode.md` and show the mode menu
  first (ADR-086).
- [`skill-menu-mode.md`](skill-menu-mode.md) — bare-maintainer mode menu used by
  the launcher before any operation runs.
- [`retrospective/SKILL.md`](retrospective/SKILL.md) — capture lessons from a fix,
  feature, review, or run session into skill and reference files, and prompt for
  script/skill/test improvements (ADR-077). Reached through `maintainer` or by
  describing the goal at session end. See ADR-083. Past captured retrospectives
  are archived in the sub-skill dir, e.g.
  [`retrospective/archived-2026-06-18-gutenberg-hardening.md`](retrospective/archived-2026-06-18-gutenberg-hardening.md) and
  [`retrospective/archived-2026-06-24-adr-naming-and-orchestration.md`](retrospective/archived-2026-06-24-adr-naming-and-orchestration.md).

## External references

- [`references/external-references.md`](references/external-references.md) —
  upstream source-of-truth links for skill and command authoring: the official
  Claude Code Skills specification, Anthropic's `plugin-dev` toolkit, and the
  `skill-creator` skill. Consult these over any in-repo paraphrase when creating
  or refining skills, commands, or the run/verify drivers.
- [`references/self-test.md`](references/self-test.md) — deterministic pytest
  and upstream-inspired plugin checks, local-source options, deliberate
  adaptations, and companion-plugin guidance.
- [`references/upstream-plugin-patterns.md`](references/upstream-plugin-patterns.md)
  — a focused comparison matrix for Anthropic's broader plugin collection.
  Consult one or two analogous examples before major workflow, hook, agent,
  command, or validation architecture changes.
- [`references/training.md`](references/training.md) — source-guided maintainer
  training workflow for comparing selected upstream examples and applying
  evidence-backed local improvements.

## Universal Command Intake

Resolve the plugin target, natural-language maintenance request, and optional Jira key/URL from the full input and session context.

Per ADR-020, when the user enters maintainer mode **without an explicit mode** (a bare `maintainer`), do **not** launch into `validate`, `review-skills`, or any plugin-dev agent. First prompt the user for what to do. Present the durable modes first: `backlog`, `adr`, `skill`, `training`, and `retro`; then offer `self-test`, `validate`, `generate-docs`, `publish`, and `all`, with detailed compatibility modes available when needed. Per ADR-064, flag that `skill review`/`review-skills` and Tier 2 `validate` spawn token-heavy Anthropic `plugin-dev` agents; never run them automatically. Run the chosen mode only after selection. Treat `test` as a legacy alias for `self-test`, `new-adr` as a legacy alias for `adr`, and the older skill-specific modes as aliases under `skill`. Once a mode is running, ask one concise question only when missing or conflicting information prevents useful work.

When running token-heavy operations in CI, require a repository secret named `CLAUDE_AVAILABLE` set to `1` and restrict invocation to PRs from trusted collaborators. See `.github/workflows/ci.yml` for guarded execution.

## Anthropic plugin-dev tools

`plugin-dev` is the optional Tier 2 companion (ADR-079). Before agent-backed
validation or skill review, verify `claude plugin list` includes it. Installation,
tool inventory, upstream links, and the deterministic local profile live in
[`references/self-test.md`](references/self-test.md).

After launching a token-heavy Tier 2 operation, record it in the current
user's cache with
[`scripts/token-usage.py`](scripts/token-usage.py):

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/maintainer/scripts/token-usage.py" \
  append <operation> "<notes>"
```

## validate

Run Tier 1 structural validation first (ADR-078):

```bash
claude plugin validate --strict .claude/plugins/ucsc-wp-block-dev
```

After Tier 1 passes, offer the opt-in Tier 2 semantic review only when deeper
qualitative analysis is wanted (ADR-064):

- `subagent_type`: `plugin-dev:plugin-validator`
- `prompt`: "Validate the Claude Code plugin at `.claude/plugins/ucsc-wp-block-dev`. Report critical errors, warnings, and overall quality."

Consult [`references/self-test.md`](references/self-test.md) for the complete
two-tier profile, companion-plugin setup, deliberate adaptations, and local
upstream-source options. Relay actionable findings and fix critical errors
before publishing.

## self-test

Run the deterministic plugin contracts and the upstream-inspired
[`scripts/check-plugin-best-practices.py`](scripts/check-plugin-best-practices.py)
checks:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/maintainer/scripts/run-self-test.sh"
```

Use [`references/self-test.md`](references/self-test.md) for check coverage,
pytest-only diagnosis, the Docker fallback, expected CLI-dependent skips, and
strict-warning behavior. This mode validates the development plugin itself; it
does not replace WordPress runtime, PHP, Jest, or e2e validation. `maintainer
test` remains a legacy alias.

## review-skills

Compatibility alias for `skill review`. Opt-in and token-heavy (~14k tokens):
launch `plugin-dev:skill-reviewer` against this plugin, relay actionable
findings, and fix critical description/frontmatter issues before publishing.

## skill-development

Before creating or substantially refactoring a `SKILL.md`, invoke
`plugin-dev:skill-development` for structure, frontmatter, trigger-description,
argument, and progressive-disclosure guidance.

## skill

Use this umbrella mode for maintaining plugin skills:

| Submode | Compatibility mode | Purpose |
|---|---|---|
| `skill details [name]` | `skill-details` | Show live frontmatter and invocation settings. |
| `skill review [name\|all]` | `review-skills` | Run the opt-in plugin-dev qualitative reviewer. |
| `skill review-contrib <candidate>` | `review-contrib` | Review a proposed or incubating skill. |
| `skill promote <candidate>` | `promote-contrib` | Promote an accepted incubator candidate. |
| `skill sync` | `sync-inventory` | Reconcile skill inventories in docs and tests. |

When `skill` is invoked without a submode, show this table and wait for a
selection. Keep compatibility modes working, but prefer `maintainer skill
<submode>` in new guidance.

## review-contrib

Review a proposal under `contrib/proposals/` or an incubator candidate under
`contrib/incubator/`. Read `contrib/README.md` first, require the candidate name
when it is unclear, and return one decision (`reject`/`revise`/`incubate` for a
proposal; `revise`/`promote` for a candidate).
Do not place a candidate under `skills/` during review.
Per-stage checklists: [`references/contrib.md`](references/contrib.md).

## promote-contrib

Promote an accepted directory from `contrib/incubator/<skill-name>/` into
`skills/<skill-name>/` only after the name, trigger, description, and
support-file checks pass; then update the inventories (`README.md`, `AGENTS.md`,
`hub`, slide deck) and run `self-test`, `validate`, `check-references`, and
`review-skills`. Full before/after checklist:
[`references/contrib.md`](references/contrib.md).

## check-references

Enforce ADR-032: every supporting file under a skill directory must be referenced from that skill's `SKILL.md`, so nested `references/`, `assets/`, and `scripts/` files stay discoverable (progressive disclosure). Run the bundled scanner:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/maintainer/scripts/check-skill-references.sh"
```

It prints one line per skill and a PASS/FAIL summary, exiting non-zero when any nested file is not linked from its `SKILL.md`. Fix a FAIL by adding a skill-relative reference (e.g. `references/foo.md`) to the skill — under a "Reference files" heading when one is warranted — or by removing the obsolete file. The pytest suite runs this same check, so a gap fails `validate` too.

## check-adr-implements

Enforce ADR-086, decision C: verify the `implements:` traceability markers in
skills and scripts. Run the checker:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/maintainer/scripts/check-adr-implements.py"
```

It runs two checks: a hard **reverse** gate (every ADR named in an `implements:`
marker must resolve to an existing, active ADR) and an advisory **forward**
coverage report (active ADRs not yet implemented by any skill or script). Pass
`--strict` to also fail on coverage gaps once the per-skill rollout is complete.

## training

Read [`references/training.md`](references/training.md), resolve a concrete
local target, and compare one or two examples from
[`references/upstream-plugin-patterns.md`](references/upstream-plugin-patterns.md).
Study/report requests are read-only; requests to apply lessons make focused local changes and run `maintainer all`. Never execute or vendor upstream code.

## retro

Invoke the hidden [`retrospective/SKILL.md`](retrospective/SKILL.md)
sub-workflow to capture reusable session lessons into the closest skill,
reference, script, test, or ADR. `retro` is the public maintainer mode name;
`retrospective` remains the internal sub-skill directory name. Do not use this
mode merely to summarize a task.

## backlog

Generate a combined backlog for the plugin (ADR-085) by merging the personal
worklist with the ADRs that are not yet implemented (computed on the fly from the
`implements:` markers). Run:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/maintainer/scripts/backlog.py"
```

Sources and outputs (all outside the repo, so nothing is checked in):

- **Personal worklist** — `~/.claude/ucsc-wp-block-dev/WORKLIST.md` (the user's
  personal `.claude` folder, not the repo). Override with `$UCSC_WP_BLOCK_DEV_WORKLIST`.
- **Unimplemented ADRs** — active ADRs with no `implements:` marker, recomputed
  each run (same source as `check-adr-implements`).
- **Generated list** — written to an ephemeral cache at
  `~/.cache/ucsc-wp-block-dev/backlog.md` (override with `$UCSC_WP_BLOCK_DEV_CACHE`).
  It is regenerated on demand and never committed; do not edit it by hand.

Pass `--print` to also echo the full combined backlog to stdout.

## refactor-links

When reference files are renamed or moved, update all markdown links in bulk
rather than one by one. See
[`references/refactor-links.md`](references/refactor-links.md) for the
`find`/`sed` one-liner and the threshold for manual vs. bulk approach.

## generate-docs

Regenerate portable Markdown documentation artifacts for Google Docs or
Confluence. Read
[`references/generate-docs.md`](references/generate-docs.md),
then run:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/maintainer/scripts/regenerate-docs.sh"
```

This writes generated artifacts under
`skills/maintainer/references/`, including
[`references/generate-docs-main.md`](references/generate-docs-main.md)
and
[`references/generate-docs-presentation.md`](references/generate-docs-presentation.md).
It does not publish or upload anything.

## publish

Per ADR-063, **bare `publish` publishes both** the guide and the deck; or name a
single output (`guide` for the prose docs, `deck` for the slides). Publishing is
always explicit and is **never** part of the `all` health-check mode. Legacy
aliases: `docs` = `guide`, `slides` = `deck`, `all` = both. The canonical Marp
deck source is maintainer-owned at `assets/ucsc-wp-block-dev-presentation.md`; do
not restore a second deck at the repository root (ADR-018).

Fast paths — each refreshes the date/artifacts, runs the contract tests, then
publishes in one call (pass `--no-publish` to refresh and test only):

- deck: `bash "${CLAUDE_PLUGIN_ROOT}/skills/maintainer/scripts/refresh-and-publish-slides.sh"`
- guide: `bash "${CLAUDE_PLUGIN_ROOT}/skills/maintainer/scripts/refresh-and-publish-docs.sh"`

For the pre-publish reconciliation steps and the explicit `publish_to_gdoc.py`
invocations and destination docs, read
[`references/publish.md`](references/publish.md).

## adr

Create or update Architecture Decision Records for plugin-maintainer decisions.
Default to updating the existing ADR for the affected skill when it fits; one ADR per skill is preferred over a stream of tiny decision files. Create a new ADR
only when the user explicitly asks to add one, or when no existing skill ADR can
reasonably hold the decision.

When creating a new ADR, automatically allocate the next available ADR number,
create a markdown file with standard frontmatter and skeleton, and update the ADR
index file. Per ADR-065, new ADRs follow the hyphenated `ADR-NNN-<skill>-<mode>-mode-<detail>.md` form. The legacy slug form is still accepted as an alias. Number
detection matches ADR files by their leading number regardless of separator. Per
ADR-086 decision B, default to extending an existing ADR and create a new one
only when the user says "add" or no existing ADR fits.

```bash
# Preferred (ADR-065): ADR-NNN-<skill>-<mode>-mode-<detail>.md
bash "${CLAUDE_PLUGIN_ROOT}/skills/maintainer/scripts/new-adr.sh" <skill> <mode> "<title>"

# Legacy alias: ADR-NNN-<slug>.md
bash "${CLAUDE_PLUGIN_ROOT}/skills/maintainer/scripts/new-adr.sh" <slug> "<title>"
```

`new-adr` remains a legacy alias for this mode.

To bulk rename active and retired ADR files on disk and automatically update their references across the plugin codebase, run the utility script:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/maintainer/scripts/rename-adrs.py"
```

### Retiring and consolidating ADRs

When an ADR becomes Superseded, Deprecated, or Rejected, move it out of the
active set with the [`retire-adr.sh`](scripts/retire-adr.sh) helper (subcommands
`refs` and `retire`) instead of hand-editing the four affected files. Prefer one
ADR per skill/theme over a stream of tiny decision files (ADR-086). For the full
retire and merge workflows — map refs → fold into the lowest-numbered survivor →
repoint markers/prose → grep-verify zero dangling → gates — read
[`references/adr-consolidation.md`](references/adr-consolidation.md).

## sync-inventory

Enforces skill inventory consistency across all documentation and testing assets
by treating the directories in `skills/` as the source of truth. Per ADR-080,
this includes the root `AGENTS.md` routing table so Codex sees the live skill
set before plugin work begins. Run the script:

```bash
# Check for any drift (dry-run check)
bash "${CLAUDE_PLUGIN_ROOT}/skills/maintainer/scripts/sync-inventory.sh" --check

# Reconcile and regenerate all files automatically
bash "${CLAUDE_PLUGIN_ROOT}/skills/maintainer/scripts/sync-inventory.sh" --write
```

## skill-details

Live developer view of every skill's actual frontmatter and invocation settings (ADR-071). Shows `user-invocable`, `model-invocable`, `discoverable`, `disable-model-invocation`, `allowed-tools`, `context`, `agent`, and any extra fields — resolved to their actual values, not static defaults. Flags any skill that differs from the all-defaults baseline.

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/maintainer/scripts/skill-details.py"
```

Run after any `SKILL.md` frontmatter change to confirm the intended invocation
posture. The `hub` static grid is a snapshot; this script is the authoritative
live source.

## all

Run the token-frugal deterministic checks in order: `self-test`,
`check-references`, then the CLI structural validator.
Report a single combined summary.

**Single-command wrapper (preferred):** run the whole battery at once with

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/maintainer/scripts/run-all-plugin-tests.sh"
```

It runs `self-test`, `check-references`, and `claude plugin validate --strict`
in order, prints a per-step PASS/FAIL, and exits non-zero if any step fails.
It skips the validate step gracefully when the `claude` CLI is unavailable.
The individual command below remains available for running just the Tier 1
structural check:

```bash
# Tier 1 structural validation included in `all` (ADR-078)
claude plugin validate --strict .claude/plugins/ucsc-wp-block-dev
```

Per ADR-064, `all` deliberately **excludes** the agent-backed checks
(`plugin-dev:plugin-validator` and `plugin-dev:skill-reviewer`) — each spawns
a token-heavy subagent, so they run only when explicitly requested. Offer them
after `all` if a deeper semantic review is wanted.

Contribution candidates are also excluded from `all`; run
`review-contrib <candidate>` explicitly because proposals and incubator skills
may be incomplete.

## Skill visibility and invocation (hidden skills)

For frontmatter fields (`user-invocable`, `disable-model-invocation`), combined behavior tables, platform capabilities (`when_to_use`, dynamic context injection, `context: fork`), and how this plugin currently hides skills, see [`references/skill-visibility.md`](references/skill-visibility.md).

## When the manifest or skills change

After editing `plugin.json`, any `SKILL.md`, or adding components, run `validate` to catch structure regressions, `check-references` to catch unreferenced support files, and `review-skills` to catch description and quality issues early. Use `skill-development` for guidance when writing new skills. When the main guide or deck should be prepared for Google Docs or Confluence without publishing, use the `generate-docs` operation in this skill.

## Maintenance gotchas

See [`references/maintenance-gotchas.md`](references/maintenance-gotchas.md) for the full list. Critical items:

- **Claim the ADR number before writing** — check both `docs/adr/index.md` and `ls docs/adr/` before creating a new ADR file.
- **Skill inventory sync set** — adding/removing a skill requires updating README, hub, slide deck, AGENTS.md, and two test files together. Run `sync-inventory.sh --write` first.
