# Maintainer mode menu

implements: ADR-020-MAINTAINER-MENU, ADR-086-MAINTAINER-CONVENTIONS

When maintainer is invoked without a mode, present this menu and wait for the
user to choose.

| Mode | Use when |
|---|---|
| `validate` | Run plugin structural validation. Token-heavy Tier 2 agent review is opt-in only. |
| `test` | Run the deterministic pytest suite. |
| `review-skills` | Run the token-heavy plugin-dev skill reviewer after explicit choice. |
| `review-contrib` | Review a proposed or incubating contributed skill. |
| `promote-contrib` | Promote an incubating skill into production. |
| `check-references` | Verify each skill references its support files. |
| `check-adr-implements` | Verify ADR `implements:` markers. |
| `generate-docs` | Regenerate portable Markdown documentation artifacts. |
| `publish` | Publish slides, docs, or all after explicit approval. |
| `adr` | Create, update, inspect, reconcile, or index ADRs. |
| `sync-inventory` | Synchronize README, hub, AGENTS, deck, and tests with skill inventory. |
| `skill-details` | Show live frontmatter and invocation settings. |
| `backlog` | Generate the combined personal worklist plus ADR implementation backlog. |
| `all` | Run deterministic health checks; excludes token-heavy plugin-dev agents. |
