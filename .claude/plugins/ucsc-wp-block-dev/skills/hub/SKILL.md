---
name: hub
description: List the ucsc-wp-block-dev plugin's skills and commands. Use when the user asks what this plugin can do, to list or show available skills or commands, or invokes `:hub`. Enumeration only — it lists skills; to act on a request, invoke the relevant skill directly.
---

# Hub — ucsc-wp-block-dev skill list

`:hub` is the plugin's inventory: it lists what `ucsc-wp-block-dev` can do. It
does **not** parse a request or route it — Claude routes natively from each
skill's `description` (ADR-061). Print the tables below as-is; this is a static
inventory, so do not scan the filesystem or spawn agents to build it (ADR-058).

The plugin ships **skills only** (no separate `commands/` directory); every
entry is invoked as `ucsc-wp-block-dev:<name>`.

## Public workflows

| Skill | Purpose |
|---|---|
| `feature` | Define and implement new block behavior, blocks, or editor/frontend enhancements. |
| `fix` | Debug and fix a described defect in a specified block, GUI, or app. |
| `develop` | Implementation core (PHP, template, JS editor, REST, build) — driven by `feature`/`fix`, not a direct entry point. |
| `run` | Build, launch, and drive the plugin in the wp-dev.ucsc Docker environment. |
| `verify` | Prove a change or acceptance criterion in the live WordPress editor or frontend. |
| `test` | Create or run automated PHP, Jest, or e2e tests. |
| `review` | Review a diff, branch, file, PR, or Jira-scoped change for bugs, regressions, security, a11y, and missing tests. |
| `survey` | Run and interpret the WordPress block survey to audit UCSC custom block usage across CampusPress sites. |

## Hidden manual skills

Reachable by typing the name directly; omitted from the routed workflow list.

- `retrospective` — Capture session lessons into skill and script files. Offered at the end of fix, feature, review, and run sessions (ADR-059).
- `maintainer` — Maintain the plugin itself: validate, test, review/promote contrib skills, check references, generate docs, publish slides (ADR-046).

## Routing

To act on a request rather than list options, invoke the specific skill directly
(e.g. `ucsc-wp-block-dev:fix <target> <description>`), or simply describe the
goal and let Claude select the skill from its description (ADR-061).
