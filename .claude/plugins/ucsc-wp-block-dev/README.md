# ucsc-wp-block-dev

Claude Code plugin for developing the `ucsc-gutenberg-blocks` WordPress plugin at UCSC ITS.

## Naming

The canonical machine-facing plugin ID is `ucsc-wp-block-dev` for both Claude
Code and Codex. Use that ID in manifests, directory names, marketplace entries,
and skill names. Use “WordPress” only in human-facing names and prose.

## Skills

Start with a target, describe the goal in ordinary language, and optionally
include a Jira key or URL. `map` is the primary entry point for routing requests.

**On `ucsc-gutenberg-blocks` (the WordPress plugin — the product):**

| Skill | Purpose |
|---|---|
| `map` | Detect the active app and route the request to a skill |
| `feature` | Add new behavior through the preferred feature workflow |
| `develop` | Use the existing development workflow during migration |
| `fix` | Fix a described problem in a specified target block, GUI, or app |
| `test` | Create or run focused PHP, Jest, or end-to-end tests |
| `review` | Review a diff, branch, file, block, or Jira-scoped change |
| `run` | Build, launch, and drive blocks via the wp-dev.ucsc Docker environment |
| `verify` | Verify a code change in the running WordPress editor or frontend |

`develop/references/issue-context.md` provides shared Jira and issue
normalization guidance for `develop`, `feature`, and `fix`.

Domain guidance for `ucsc-gutenberg-blocks` is intentionally hidden from the
top-level skill list and lives at `develop/references/domain/blocks.md`.

Block-specific guidance lives under `develop/references/targets/`. The
`develop` workflow requires a target and loads only the selected target
reference.

Maintenance is intentionally hidden from the public workflow list. Type
`maintainer` directly when you need to validate structure, run tests, review or
promote contributed skills, verify ADR consistency, or check skill reference
integrity.

Retrospectives are also hidden from the public workflow list. Type
`retrospective` directly when lessons from a fix, feature, review, or run
session should be saved into skill references.

Use the maintainer `generate-docs` reference at
`maintainer/references/generate-docs/generate-docs.md` to regenerate portable
Markdown artifacts before copying the guide or deck into Google Docs or
Confluence. Use `maintainer generate-docs` for regeneration and
`maintainer publish-slides` only when publishing the canonical deck to Google
Docs.

## Contributing skills

Propose and incubate skills outside the live plugin inventory under
`contrib/`. The lifecycle is:

```text
contrib/proposals/<skill-name>.md
    -> contrib/incubator/<skill-name>/
    -> skills/<skill-name>/
```

Use `contrib/proposals/TEMPLATE.md` for suggestions. A maintainer reviews
candidates with `maintainer review-contrib <candidate>` and owns final
integration through `maintainer promote-contrib <candidate>`. Drafts under
`contrib/` are not discovered or invoked as plugin skills.

## Plugin location

`wp-dev.ucsc/public/wp-content/plugins/ucsc-gutenberg-blocks/`

## Local development

See the `run` skill for the recorded setup and launch recipe, `verify` for live
behavior checks, and `test` for automated tests. The environment README owns
clean setup; the product plugin README owns its test commands.

For the routine lifecycle, the `run` and `verify` skills ship a token-frugal `driver.sh` that runs a whole phase in a single call and prints a compact PASS/FAIL summary (verbose output goes to a logfile it names on exit):

```bash
# Build + launch + smoke in one call (inspect → build → launch → smoke)
bash .claude/plugins/ucsc-wp-block-dev/skills/run/driver.sh all

# Deterministic pre-checks for a change (plugin active, build fresh, block registered)
bash .claude/plugins/ucsc-wp-block-dev/skills/verify/driver.sh <block-slug>
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

Maintenance and validation run through the `maintainer` skill (see ADR-004). It launches Anthropic's `plugin-dev:plugin-validator` agent and runs the test suite.

Install the validator dependency:

```
/plugin install plugin-dev@claude-plugins-official
```

Then run validation from Claude Code:

Use the `maintainer` skill with the `validate` operation.

Or run the full check (tests + validation):

Use the `maintainer` skill with the `all` operation.

The `all` flow also runs `check-references`, which enforces ADR-032 — every supporting file under a skill directory must be linked from that skill's `SKILL.md`. The pytest suite enforces the same invariant, so unreferenced reference/asset/script files fail `test` too.

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
