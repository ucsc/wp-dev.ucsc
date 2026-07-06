---
title: UCSC WordPress Block Development Plugin Guide
generated: 2026-07-05
version: 0.2.0
git-commit: e7294b3991eb4632759ff3bebdc2ab97456f4f04
source: README.md
source-hash: b7a54239a48468e2aebab355b5cb394de83a87cd466ff113e920470d83b259b7
---

# ucsc-wp-block-dev

**Generated:** 2026-07-05 · **Plugin version:** 0.2.0 · **Git commit:** `e7294b3991eb`

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


## After installing — what you can do

Type `hub` (`:hub`) in Claude Code to list the available skills, or invoke one directly by name:

* **`hub`** `[block]` — list skills and set an optional session block target
* **`develop`** `[feature|fix] [block] [request]` — add or modify WordPress block code
* **`feedback`** `[bug|idea|question] [note]` — report a bug or idea about the plugin skills
* **`review`** `[target] [focus]` — review code for bugs, security, a11y, and tests
* **`run`** `[block] [change|URL]` — launch and drive wp-dev.ucsc
* **`validate`** `[php|jest|e2e|all] [create|run] [target]` — create or run automated test suites
* **`verify`** `[block] [criterion]` — confirm a change in the running app
* **`maintainer`** `[mode] [submode|target]` — maintain this plugin package
