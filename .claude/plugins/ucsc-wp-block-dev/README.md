<!-- BEGIN GUIDE -->
# ucsc-wp-block-dev

Claude Code plugin for developing the `ucsc-gutenberg-blocks` WordPress plugin at UCSC ITS.

Install it with the steps below, then type `hub` (`:hub`) inside Claude Code to
list the available skills. For a guided tour of every skill and the plugin's
design, see the companion slide deck.

## Environment configuration for publishing

The repository-root `.env` is gitignored and is the default place for private,
machine-specific plugin settings. Documentation publishing requires destination
URLs to be supplied there; the public plugin never contains real Google Doc IDs.

```dotenv
UCSC_WP_BLOCK_DEV_SLIDES_DOC_URL=https://docs.google.com/document/d/<SLIDES_DOCUMENT_ID>/edit
UCSC_WP_BLOCK_DEV_GUIDE_DOC_URL=https://docs.google.com/document/d/<GUIDE_DOCUMENT_ID>/edit
```

Copy each URL from the corresponding Google Doc while it is open. The URL is a
destination identifier, not an authentication credential. The publishing
account must separately have edit access to each document through one of the
credential locations described in `skills/maintainer/references/publish.md`.

The publishing scripts load `.env` automatically. To use another file, set
`UCSC_WP_BLOCK_DEV_ENV_FILE=/absolute/path/to/private.env`. When a required URL
is missing or is not a Google Docs edit URL, the command stops before uploading
and prints the exact variable and example to add. Refresh-only commands using
`--no-publish` do not require these variables.

The same `.env` may configure optional feedback delivery:

```dotenv
UCSC_FEEDBACK_ENDPOINT=https://feedback.example.test/plugin
UCSC_FEEDBACK_TOKEN=<optional-bearer-token>
# Or, instead of an endpoint:
UCSC_FEEDBACK_EMAIL=plugin-feedback@example.test
```

Keep `.env`, Google credential JSON, and tokens untracked. Commit only
placeholder examples such as the ones above.
<!-- END GUIDE -->

## Naming

The canonical machine-facing plugin ID is `ucsc-wp-block-dev` for both Claude
Code and Codex. Use that ID in manifests, directory names, marketplace entries,
and skill names. Use “WordPress” only in human-facing names and prose.

## Skills

Start with a target, describe the goal in ordinary language, and optionally
include a Jira key or URL. Claude routes to the right skill from each skill's
description; type `hub` (`:hub`) to list what's available, or invoke a skill
directly.

Although built for Claude Code, the same skills can be driven by natural-language
invocation from other agent CLIs — **Codex**, **GitHub Copilot**, and **Gemini
CLI** — which read the bundled root `AGENTS.md` routing table to see the live
skill set (ADR-080).

**On `ucsc-gutenberg-blocks` (the WordPress plugin — the product):**

```text
skills
├─ hub               [block]                                   — list skills and set an optional session block target
├─ develop           [feature|fix] [block] [request]           — add or modify WordPress block code
│  ├─ feature  [block] [request]  — implement planned block behavior
│  └─ fix      [block] [problem]  — diagnose and repair a block defect
├─ feedback          [bug|idea|question] [note]                — report a bug or idea about the plugin skills
├─ review            [target] [focus]                          — review code for bugs, security, a11y, and tests
├─ audit             [full|tools] [scope or emphasis]          — top-down read-only audit of the whole repository
│  ├─ full   [scope or emphasis]       — phased top-down audit with specialist subagents
│  └─ tools  [php|node|both] [target]  — run the local ucsc-php-review / ucsc-node-review runners
├─ run               [block] [change|URL]                      — launch and drive wp-dev.ucsc
├─ validate          [php|jest|e2e|all] [create|run] [target]  — create or run automated test suites
│  ├─ php   [create|run] [target]  — create or run PHP tests
│  ├─ jest  [create|run] [target]  — create or run Jest tests
│  ├─ e2e   [create|run] [target]  — create or run browser-driven tests
│  └─ all   [block]                — run PHP, Jest, and E2E sequentially
├─ verify            [block] [criterion]                       — confirm a change in the running app
├─ wp7-pattern-lock  [site-url] [pages]                        — diagnose and fix WP 7.0 pattern-locked pages
└─ maintainer        [mode] [submode|target]                   — maintain this plugin package
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

Use the maintainer `docs` reference at
`maintainer/references/generate-docs.md` to regenerate portable
Markdown artifacts before copying the guide or deck into Google Docs or
Confluence. Use `maintainer docs` for regeneration, `maintainer docs check` to
detect (via a git source hash) whether the artifacts are stale, and
`maintainer docs publish` to publish both slides and guide by default; name
`guide` or `slides` only to publish one. `deck` remains a compatibility alias.
`generate-docs` and `publish` remain legacy
aliases for `docs` and `docs publish`.

## Companion skills (recommended)

This plugin is intentionally scoped to UCSC **block** development in
`wp-dev.ucsc`. For **general WordPress engineering** that falls outside a block
target — site-wide performance/query auditing, security hardening, plugin/theme
architecture, and WordPress coding standards — install the optional,
MIT-licensed companion skillset by Elvis Marin (`elvismdev`). It complements
`review`/`validate` without overlapping their block scope (ADR-104):

- **`claude-wordpress-skills`** — https://github.com/elvismdev/claude-wordpress-skills
  - `wp-performance-review` (active) — DB query, caching/transient, N+1,
    AJAX/HTTP, hook, and JS-bundling analysis, with VIP/WP Engine/Pantheon/
    self-hosted notes.
  - `wp-security-review`, `wp-gutenberg-blocks`, `wp-theme-development`,
    `wp-plugin-development` — in development.

Install it (marketplace preferred):

```text
/plugin marketplace add elvismdev/claude-wordpress-skills
```

Alternatives:

```bash
git clone https://github.com/elvismdev/claude-wordpress-skills.git ~/.claude/plugins/wordpress
git submodule add https://github.com/elvismdev/claude-wordpress-skills.git .claude/plugins/wordpress
```

Run `/reload-plugins` after installing if the new skills aren't discovered yet.
It is a recommendation, not a dependency — every `ucsc-wp-block-dev` workflow
works without it. A formal dependency is deferred until its in-development skills
reach a stable release (ADR-104). This is separate from the Anthropic
`plugin-dev` companion used for plugin *maintenance* (see
[Validate the plugin](#validate-the-plugin) and ADR-079).

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

For developer quick-start and environment setup instructions, see [INSTALL.md](INSTALL.md).

<!-- BEGIN GUIDE -->
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
<!-- END GUIDE -->

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
