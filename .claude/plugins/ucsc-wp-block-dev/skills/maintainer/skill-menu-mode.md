# Maintainer mode menu

implements: ADR-020-MAINTAINER-MENU, ADR-086-MAINTAINER-CONVENTIONS

When maintainer is invoked without a mode, present this menu and wait for the
user to choose.

| Mode | Use when |
|---|---|
| `backlog` | Generate the combined personal worklist plus ADR implementation backlog. |
| `adr` | Create, update, inspect, reconcile, or index ADRs. |
| `skill` | Inspect, review, promote, or synchronize plugin skills. |
| `training` | Study selected upstream plugin/skill examples and turn relevant patterns into local recommendations or requested improvements. |
| `retro` | Capture reusable session lessons into skills, references, scripts, tests, or ADRs. |
| `self-test` | Run the plugin's pytest contracts and deterministic best-practice checks — tests this Claude plugin, not WordPress block targets or the GUI app. Legacy alias: `test`. |
| `validate` | Run plugin structural validation. Token-heavy Tier 2 agent review is opt-in only. |
| `review-skills` | Compatibility alias for `skill review`; token-heavy and opt-in. |
| `review-contrib` | Review a proposed or incubating contributed skill. |
| `promote-contrib` | Promote an incubating skill into production. |
| `check-references` | Verify each skill references its support files. |
| `check-adr-implements` | Verify ADR `implements:` markers. |
| `generate-docs` | Regenerate portable Markdown documentation artifacts. |
| `publish` | Publish both the guide and deck (bare), or a named `guide`/`deck`, after explicit approval. |
| `sync-inventory` | Synchronize README, hub, AGENTS, deck, and tests with skill inventory. |
| `skill-details` | Show live frontmatter and invocation settings. |
| `all` | Run deterministic health checks; excludes token-heavy plugin-dev agents. |
