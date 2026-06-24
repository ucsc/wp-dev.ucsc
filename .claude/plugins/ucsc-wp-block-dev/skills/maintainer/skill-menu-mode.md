# Maintainer mode menu

implements: ADR-020-MAINTAINER-MENU, ADR-086-MAINTAINER-CONVENTIONS

When maintainer is invoked without a mode, present this menu and wait for the
user to choose.

| Mode | Arguments | Use when |
|---|---|---|
| `backlog` | — | Generate the combined personal worklist plus ADR implementation backlog. |
| `adr` | `[create\|update\|inspect\|reconcile\|index] [ADR or decision]` | Create, update, inspect, reconcile, or index ADRs. |
| `skill` | `[details\|review\|review-contrib\|promote\|sync] [name or candidate]` | Inspect, review, promote, or synchronize plugin skills. |
| `training` | `[goal] [from upstream examples]` | Study selected upstream plugin/skill examples and turn relevant patterns into local recommendations or requested improvements. |
| `retro` | `[lesson or target skill]` | Capture reusable session lessons into skills, references, scripts, tests, or ADRs. |
| `self-test` | — | Run the plugin's pytest contracts and deterministic best-practice checks — tests this Claude plugin, not WordPress block targets or the GUI app. Legacy alias: `test`. |
| `validate` | `[tier1\|tier2]` | Run plugin structural validation. Token-heavy Tier 2 agent review is opt-in only. |
| `generate-docs` | — | Regenerate portable Markdown documentation artifacts. |
| `publish` | `[guide\|deck\|all]` | Publish both the guide and deck (bare), or a named output, after explicit approval. |
| `all` | — | Run deterministic health checks; excludes token-heavy plugin-dev agents. |

Compatibility modes remain accepted: `review-skills`, `review-contrib`,
`promote-contrib`, `check-references`, `check-adr-implements`,
`sync-inventory`, and `skill-details`.

When `skill` is selected, present its submodes:

| Skill submode | Use when |
|---|---|
| `skill details [name]` | Inspect one skill or all live frontmatter and invocation settings. |
| `skill review [name|all]` | Run the opt-in qualitative skill reviewer. |
| `skill review-contrib <candidate>` | Review a proposed or incubating contributed skill. |
| `skill promote <candidate>` | Promote an accepted candidate into the live inventory. |
| `skill sync` | Reconcile skill inventories across docs and tests. |
