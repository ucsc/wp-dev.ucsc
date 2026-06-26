---
title: UCSC WordPress Block Development Plugin Guide
generated: 2026-06-25
version: 0.2.0
git-commit: fa2dd4595a5e612303cfa2be4206b027c4013188
source: README.md
source-hash: 604e2e6f18ca103c822484af4d253e02d0aed14eb13e73b497800311d7f7a050
---

# ucsc-wp-block-dev

**Generated:** 2026-06-25 · **Plugin version:** 0.2.0 · **Git commit:** `fa2dd4595a5e`

Claude Code plugin for developing the `ucsc-gutenberg-blocks` WordPress plugin at UCSC ITS.

Install it with the steps below, then type `hub` (`:hub`) inside Claude Code to
list the available skills. For a guided tour of every skill and the plugin's
design, see the companion slide deck.

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

