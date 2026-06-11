# ucsc-wp-block-dev

Claude Code plugin for developing the `ucsc-gutenberg-blocks` WordPress plugin at UCSC ITS.

## Naming

The canonical machine-facing plugin ID is `ucsc-wp-block-dev` for both Claude
Code and Codex. Use that ID in manifests, directory names, marketplace entries,
and slash commands. Use “WordPress” only in human-facing names and prose.

## Skills

The plugin uses the same interaction model as `ucsc-laravel-vue-dev`: start with a target, describe the goal in ordinary language, and optionally include a Jira key or URL. `/ucsc-wp-block-dev:start` is the primary entry point and `/ucsc-wp-block-dev:setup` gives a short capability overview.

**On `ucsc-gutenberg-blocks` (the WordPress plugin — the product):**

| Skill | Purpose |
|---|---|
| `/ucsc-wp-block-dev:start` | Detect the active app and route the request |
| `/ucsc-wp-block-dev:setup` | Show a concise capability overview |
| `/ucsc-wp-block-dev:develop` | Add a described feature to a specified target block, GUI, or app |
| `/ucsc-wp-block-dev:fix` | Fix a described problem in a specified target block, GUI, or app |
| `/ucsc-wp-block-dev:test [php\|jest\|e2e]` | Create or run focused tests after confirming the operation |
| `/ucsc-wp-block-dev:review` | Review a diff, branch, file, block, or Jira-scoped change |
| `/ucsc-wp-block-dev:run` | Build, launch, and drive blocks via the wp-dev.ucsc Docker environment |
| `/ucsc-wp-block-dev:verify` | Verify a code change in the running WordPress editor or frontend |
| `blocks` | Auto-loaded domain reference (not a slash command) — pulled in automatically when working on plugin files |

**On this plugin itself (the tooling):**

| Skill | Purpose |
|---|---|
| `/ucsc-wp-block-dev:maintainer` | Validate structure, run the test suite, and verify ADR index consistency |

## Plugin location

`wp-dev.ucsc/public/wp-content/plugins/ucsc-gutenberg-blocks/`

## Local development

See `/ucsc-wp-block-dev:run` for the recorded setup and launch recipe, `/ucsc-wp-block-dev:verify` for live behavior checks, and `/ucsc-wp-block-dev:test` for automated tests. The environment README owns clean setup; the product plugin README owns its test commands.

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

```
/ucsc-wp-block-dev:maintainer validate
```

Or run the full check (tests + validation):

```
/ucsc-wp-block-dev:maintainer all
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
