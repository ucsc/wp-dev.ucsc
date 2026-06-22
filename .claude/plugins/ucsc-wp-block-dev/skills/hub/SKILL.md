---
name: hub
description: This skill should be used when the user asks to "list skills", "what can you do", "show available commands", "what WordPress block skills are available", or invokes `:hub`. Enumeration only — lists the plugin inventory without routing; to act, invoke the relevant skill directly.
---

# Hub — ucsc-wp-block-dev skill list

## Implements

implements: ADR-013-HUB-README, ADR-060-HUB-LIST-SKILLS, ADR-061-HUB-NATIVE-DISCOVERY, ADR-088-HUB-SKILL-MODES

`:hub` is the plugin's inventory: it lists what `ucsc-wp-block-dev` can do. It
does **not** parse a request or route it — Claude routes natively from each
skill's `description` (ADR-061). Print the tables below as-is; this is a static
inventory, so do not scan the filesystem or spawn agents to build it (ADR-058).

The plugin ships **skills only** (no separate `commands/` directory); every
entry is invoked as `ucsc-wp-block-dev:<name>`.

## Skill invocation settings

All skills currently run on platform defaults. "Documented in hub" is a
convention — not a frontmatter field — controlling whether a skill appears in
the public workflow table below.

| Skill or mode | user-invocable | model-invocable | Discoverable | Documented in hub |
|---|---|---|---|---|
| `develop` | ✓ (default) | ✓ (default) | ✓ (default) | ✓ public |
| `develop feature` | mode | mode | via develop | ✓ public |
| `develop fix` | mode | mode | via develop | ✓ public |
| `hub` | ✓ (default) | ✓ (default) | ✓ (default) | ✓ public |
| `review` | ✓ (default) | ✓ (default) | ✓ (default) | ✓ public |
| `run` | ✓ (default) | ✓ (default) | ✓ (default) | ✓ public |
| `validate` | ✓ (default) | ✓ (default) | ✓ (default) | ✓ public |
| `validate create` | mode | mode | via validate | ✓ public |
| `validate run` | mode | mode | via validate | ✓ public |
| `verify` | ✓ (default) | ✓ (default) | ✓ (default) | ✓ public |

**Discoverable** = model sees the skill's description in context and may
auto-invoke it. Set `disable-model-invocation: true` to suppress this.
**user-invocable** = appears in the `/` slash menu. Set `user-invocable: false`
to hide from the menu while keeping model discoverability.

## Public workflows

| Skill or mode | Purpose |
|---|---|
| `develop` | Add or modify block code (PHP, template, JS editor, REST, build). |
| `develop feature` | Mode of `develop` for defining and implementing new behavior. |
| `develop fix` | Mode of `develop` for reproducing and repairing defects. |
| `review` | Review a diff, branch, file, PR, or Jira-scoped change for bugs, regressions, security, a11y, and missing tests. |
| `run` | Build, launch, and drive the plugin in the wp-dev.ucsc Docker environment. |
| `validate` | Create or run automated PHP, Jest, or e2e tests. |
| `validate create` | Mode of `validate` for creating automated PHP, Jest, or e2e tests. |
| `validate run` | Mode of `validate` for running existing automated PHP, Jest, or e2e tests. |
| `verify` | Live DOM test of a change or acceptance criterion in the running WordPress editor or frontend. |

## Routing

To act on a request rather than list options, invoke the specific skill directly,
including its mode when needed (e.g. `ucsc-wp-block-dev:develop feature <target>
<description>`), or simply describe the goal and let Claude select the skill from
its description (ADR-061).
