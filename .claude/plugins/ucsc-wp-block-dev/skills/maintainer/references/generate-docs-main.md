---
title: UCSC WordPress Block Development Plugin Guide
generated: 2026-06-25
source: README.md
---

# ucsc-wp-block-dev

Claude Code plugin for developing the `ucsc-gutenberg-blocks` WordPress plugin at UCSC ITS.

## Naming

The canonical machine-facing plugin ID is `ucsc-wp-block-dev` for both Claude
Code and Codex. Use that ID in manifests, directory names, marketplace entries,
and skill names. Use “WordPress” only in human-facing names and prose.

## Skills

Start with a target, describe the goal in ordinary language, and optionally
include a Jira key or URL. Claude routes to the right skill from each skill's
description; type `hub` (`:hub`) to list what's available, or invoke a skill
directly.

**On `ucsc-gutenberg-blocks` (the WordPress plugin — the product):**

```text
skills
├─ hub         [block]                                   — list skills and set an optional session block target
├─ develop     [feature|fix] [block] [request]           — add or modify WordPress block code
│  ├─ feature  [block] [request]  — implement planned block behavior
│  └─ fix      [block] [problem]  — diagnose and repair a block defect
├─ feedback    [bug|idea|question] [note]                — report a bug or idea about the plugin skills
├─ review      [target] [focus]                          — review code for bugs, security, a11y, and tests
├─ run         [block] [change|URL]                      — launch and drive wp-dev.ucsc
├─ validate    [php|jest|e2e|all] [create|run] [target]  — create or run automated test suites
│  ├─ php   [create|run] [target]  — create or run PHP tests
│  ├─ jest  [create|run] [target]  — create or run Jest tests
│  ├─ e2e   [create|run] [target]  — create or run browser-driven tests
│  └─ all   [block]                — run PHP, Jest, and E2E sequentially
├─ verify      [block] [criterion]                       — confirm a change in the running app
└─ maintainer  [mode] [submode|target]                   — maintain this plugin package
   ├─ backlog                                   — build the personal and unimplemented-ADR backlog
   ├─ adr            [action] [ADR|decision]    — author, retire, inspect, and reconcile ADRs
   ├─ skill          [action] [name|candidate]  — maintain plugin skills, references, scripts, and inventory
   │  ├─ details         [name]       — inspect live frontmatter and invocation settings
   │  ├─ review          [name|all]   — run the opt-in qualitative skill reviewer
   │  ├─ review-contrib  <candidate>  — review a proposed or incubating skill
   │  ├─ promote         <candidate>  — promote an accepted candidate
   │  └─ sync                         — reconcile skill inventories across docs and tests
   ├─ training       [goal]                     — study upstream patterns and apply relevant lessons
   ├─ retro          [lesson|skill]             — capture reusable session lessons
   ├─ self-test                                 — run pytest contracts and deterministic plugin checks
   ├─ validate       [tier1|tier2]              — run structural validation; Tier 2 is opt-in
   ├─ generate-docs                             — regenerate portable guide and deck Markdown
   ├─ publish        [guide|deck|all]           — publish the guide, deck, or both after approval
   └─ all                                       — run the deterministic maintainer health checks
```

`run` and `verify` follow the bundled Claude Code v2.1.145+ contract. The
recorded recipe in this plugin plays the role of `/run-skill-generator`: `run`
launches and drives the app, `verify` confirms a supplied change against the
running app, and `validate` remains the PHP/Jest/e2e suite workflow.

`develop/references/issue-context.md` provides shared Jira and issue
normalization guidance for `develop`, `develop feature`, and `develop fix`.

Domain guidance for `ucsc-gutenberg-blocks` is intentionally hidden from the
top-level skill list and lives at `develop/references/domain-blocks.md`.

Block-specific guidance lives under `develop/references/targets/`. The
`develop` workflow requires a target and loads only the selected target
reference.

Use `maintainer` when you need to validate structure, run plugin self-tests,
review or promote contributed skills, verify ADR consistency, or check skill
reference integrity. The skill is user-invocable only; model auto-invocation is disabled.
Use `maintainer self-test` for this Claude plugin's pytest contracts and
deterministic best-practice checks; it does not test WordPress block targets or
the GUI app.

Use `maintainer training <goal>` to compare a focused local target with selected
Anthropic plugin or skill examples. Training can return a study report or, when
requested, enrich local skills, references, scripts, and tests. It never
executes or vendors upstream code merely for inspection.

The maintainer's durable entry points are `maintainer backlog`, `maintainer
adr`, `maintainer skill`, `maintainer training`, and `maintainer retro`.
Use `maintainer skill` for skill details, reviews, contribution promotion, and
inventory synchronization. Use `maintainer retro` to capture session lessons
through the hidden retrospective sub-workflow.

Retrospectives are a hidden `maintainer` sub-workflow at
`maintainer/retrospective`. Reach them through `maintainer retro`, or by
describing the goal at the end of a fix, feature, review, or run session, when
lessons should be saved into skill references (ADR-083).

Use the maintainer `generate-docs` reference at
`maintainer/references/generate-docs.md` to regenerate portable
Markdown artifacts before copying the guide or deck into Google Docs or
Confluence. Use `maintainer generate-docs` for regeneration and
`maintainer publish` (bare = both; or `guide`/`deck`) only when publishing the guide or
deck to Google Docs.

## Contributing skills

Propose and incubate skills outside the live plugin inventory under
`contrib/`. The lifecycle is:

```text
contrib/proposals/<skill-name>.md
    -> contrib/incubator/<skill-name>/
    -> skills/<skill-name>/
```

Use `contrib/proposals/TEMPLATE.md` for suggestions. A maintainer reviews
candidates with `maintainer skill review-contrib <candidate>` and owns final
integration through `maintainer skill promote <candidate>`. Drafts under
`contrib/` are not discovered or invoked as plugin skills.

## Plugin location

`wp-dev.ucsc/public/wp-content/plugins/ucsc-gutenberg-blocks/`

## Local development

See the `run` skill for the recorded setup and launch recipe, `verify` for live
behavior checks, and `validate` for automated tests. The environment README owns
clean setup; the product plugin README owns its test commands.

For the routine lifecycle, the `run`, `verify`, and `validate` skills ship a token-frugal driver that runs a whole phase in a single call and prints a compact PASS/FAIL summary (verbose output goes to a logfile it names on exit):

```bash
# Build + launch + smoke in one call (inspect → build → launch → smoke)
bash .claude/plugins/ucsc-wp-block-dev/skills/run/driver.sh all

# Deterministic pre-checks for a change (plugin active, build fresh, block registered)
bash .claude/plugins/ucsc-wp-block-dev/skills/verify/driver.sh <block-slug>

# Run PHP and Jest automated test suites in Docker
bash .claude/plugins/ucsc-wp-block-dev/skills/validate/validate-php.sh all
```

The raw commands below are the underlying steps those drivers automate:

```bash
# Build in Docker
docker compose -f docker-compose.yml -f docker-compose-start.yml run --rm \
  -w /var/www/html/wp-content/plugins/ucsc-gutenberg-blocks \
  plugin_npm_start npm run build

# Start wp-dev.ucsc
docker compose up -d

# Run Jest tests
docker compose -f docker-compose.yml -f docker-compose-start.yml run --rm \
  -w /var/www/html/wp-content/plugins/ucsc-gutenberg-blocks \
  plugin_npm_start npm test

# Run dependency-free PHP tests
docker run --rm -v "$PWD/public/wp-content/plugins/ucsc-gutenberg-blocks:/plugin" \
  -w /plugin php:8.1-cli php tests/php/ClassScheduleTest.php
```

## Plugin management

### Install

Install Claude Code if you haven't already:

```bash
npm install -g @anthropic-ai/claude-code
```

Install this plugin from the project marketplace:

```bash
claude plugin install ucsc-wp-block-dev@ucsc-wordpress --scope project
```

If the marketplace isn't registered yet:

```bash
claude plugin marketplace add ./.claude --scope project
```

After installing, restart Claude Code or run `/reload-plugins` inside a session
so the plugin skills are loaded.

### Uninstall

```bash
claude plugin uninstall ucsc-wp-block-dev --scope project
```

Add `--prune` to also remove auto-installed dependencies that are no longer
needed. Add `--keep-data` to preserve the plugin's persistent data directory.

### Reload after changes

When you edit skills, hooks, or the manifest during development, run
`/reload-plugins` inside Claude Code to pick up changes without restarting.
If the reload would change which MCP tools are loaded (invalidating the prompt
cache), the command warns and skips unless you pass `--force`:

```
/reload-plugins
/reload-plugins --force
```

### List installed plugins

```bash
claude plugin list
```

### Launch from source (without installing)

For local development or testing against the source tree, launch Claude Code
with `--plugin-dir` pointing at the plugin root:

```bash
claude --plugin-dir .claude/plugins/ucsc-wp-block-dev
```

This loads the plugin for the current session only — no install step needed.
You can combine multiple `--plugin-dir` flags to load several plugins at once.

### Validate the plugin

Maintenance and validation run through the `maintainer` skill (see ADR-004).
Deterministic checks run locally; Anthropic's `plugin-dev:plugin-validator`
agent remains an opt-in qualitative second tier.

The current upstream source and recommended companion toolkit are:

- https://github.com/anthropics/claude-code/tree/main/plugins/plugin-dev

Install the companion plugin when Tier 2 review is wanted:

```
/plugin install plugin-dev@claude-code-marketplace
```

Then run validation from Claude Code:

Use the `maintainer` skill with the `validate` operation.

Or run the full check (tests + validation):

Use the `maintainer` skill with the `all` operation.

The `all` flow runs `self-test`, then `check-references`, which enforces ADR-032
— every supporting file under a skill directory must be linked from that
skill's `SKILL.md`. The pytest suite enforces the same invariant.

Run the complete plugin self-test with:

```bash
bash .claude/plugins/ucsc-wp-block-dev/skills/maintainer/scripts/run-self-test.sh
```

To validate without the skill, ask Claude to "validate the plugin at `.claude/plugins/ucsc-wp-block-dev`" — it will launch the `plugin-dev:plugin-validator` agent. Run the bundled tests directly with:

```bash
cd .claude/plugins/ucsc-wp-block-dev && python3 -m pytest -q
```

The only test dependency is `pytest` (see `requirements-dev.txt`). Keep the virtualenv outside the plugin tree so the plugin root stays lean:

```bash
python3 -m venv ../ucsc-wp-block-dev-venv
../ucsc-wp-block-dev-venv/bin/pip install -r requirements-dev.txt
../ucsc-wp-block-dev-venv/bin/python -m pytest -q
```

## ADRs

Architecture decisions live in `docs/adr/`. See `docs/adr/index.md`.
