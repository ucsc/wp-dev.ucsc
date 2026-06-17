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

## Skill invocation settings

All skills currently run on platform defaults. "Documented in hub" is a
convention — not a frontmatter field — controlling whether a skill appears in
the public workflow table below (ADR-046).

| Skill | user-invocable | model-invocable | Discoverable | Documented in hub |
|---|---|---|---|---|
| `develop` | ✓ (default) | ✓ (default) | ✓ (default) | ✓ public |
| `feature` | ✓ (default) | ✓ (default) | ✓ (default) | ✓ public |
| `fix` | ✓ (default) | ✓ (default) | ✓ (default) | ✓ public |
| `hub` | ✓ (default) | ✓ (default) | ✓ (default) | ✓ public |
| `review` | ✓ (default) | ✓ (default) | ✓ (default) | ✓ public |
| `run` | ✓ (default) | ✓ (default) | ✓ (default) | ✓ public |
| `survey` | ✓ (default) | ✓ (default) | ✓ (default) | ✓ public |
| `test` | ✓ (default) | ✓ (default) | ✓ (default) | ✓ public |
| `verify` | ✓ (default) | ✓ (default) | ✓ (default) | ✓ public |
| `maintainer` | ✓ (default) | ✓ (default) | ✓ (default) | ✗ hidden |
| `retrospective` | ✓ (default) | ✓ (default) | ✓ (default) | ✗ hidden |

**Discoverable** = model sees the skill's description in context and may
auto-invoke it. Set `disable-model-invocation: true` to suppress this.
**user-invocable** = appears in the `/` slash menu. Set `user-invocable: false`
to hide from the menu while keeping model discoverability.

## Public workflows

| Skill | Purpose |
|---|---|
| `develop` | Add or modify block code (PHP, template, JS editor, REST, build) — use directly or invoked by `feature`/`fix`. |
| `feature` | Define and implement new block behavior, blocks, or editor/frontend enhancements. |
| `fix` | Debug and fix a described defect in a specified block, GUI, or app. |
| `review` | Review a diff, branch, file, PR, or Jira-scoped change for bugs, regressions, security, a11y, and missing tests. |
| `run` | Build, launch, and drive the plugin in the wp-dev.ucsc Docker environment. |
| `survey` | Run and interpret the WordPress block survey to audit UCSC custom block usage across CampusPress sites. |
| `test` | Create or run automated PHP, Jest, or e2e tests. |
| `verify` | Live DOM test of a change or acceptance criterion in the running WordPress editor or frontend. |

## Hidden manual skills

Reachable by typing the name directly; omitted from the routed workflow list.

- `maintainer` — Maintain the plugin itself: validate, test, review/promote contrib skills, check references, generate docs, publish slides (ADR-046).
- `retrospective` — Capture session lessons into skill and script files. Offered at the end of fix, feature, review, and run sessions (ADR-059).

## Routing

To act on a request rather than list options, invoke the specific skill directly
(e.g. `ucsc-wp-block-dev:fix <target> <description>`), or simply describe the
goal and let Claude select the skill from its description (ADR-061).
