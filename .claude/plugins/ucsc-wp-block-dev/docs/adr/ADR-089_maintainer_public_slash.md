---
title: "ADR-089: Maintainer is a user-only slash skill with modes"
status: Accepted
date: 2026-06-22
related: ["ADR-020", "ADR-046", "ADR-083", "ADR-086"]
---

# ADR-089: Maintainer is a user-only slash skill with modes

## Status

Accepted

## Context

The Laravel/Vue plugin exposes `/ucsc-laravel-vue-dev:maintainer` as a
user-invocable maintenance entry while disabling model auto-invocation. The
WordPress block plugin already had a `maintainer` skill, but it was documented
as hidden/manual. That made the two UCSC plugin maintenance surfaces
inconsistent and obscured the slash command users should reach for.

## Decision

Expose the WordPress maintainer skill as `/ucsc-wp-block-dev:maintainer` for
explicit user invocation only.

- Set `user-invocable: true` and `disable-model-invocation: true` on
  `skills/maintainer/SKILL.md`.
- List `maintainer` in README, AGENTS.md, and the maintainer deck as a
  user-invocable, non-model-invocable maintenance skill.
- Omit `maintainer` from the general `:hub` public workflow table; the general
  hub stays focused on product workflows.
- When `:hub` is shown while the maintainer skill is already active, include a
  separate maintainer-only section that identifies `maintainer` as
  user-invocable and lists its modes.
- Treat maintainer subcommands as modes. Add `adr` as the canonical mode for
  creating or updating Architecture Decision Records. Keep `new-adr` as a
  legacy alias.
- Prefer one ADR per skill: update the existing ADR for the affected skill when
  it fits, and create a new ADR only when the user explicitly asks to add one or
  no existing skill ADR can reasonably hold the decision.
- Keep `maintainer/retrospective` as a hidden sub-workflow reached through the
  maintainer skill.

## Consequences

- WordPress and Laravel/Vue plugin maintenance now use parallel user-invoked
  slash commands:
  `/ucsc-wp-block-dev:maintainer` and `/ucsc-laravel-vue-dev:maintainer`.
- Maintainer remains protected from automatic model routing, so product work
  should still route to `develop`, `review`, `run`, `validate`, or `verify`.
- `:hub` does not advertise maintainer from normal product-development context,
  but maintainers already inside the maintainer workflow can see the available
  maintainer modes without leaving that context.
- Maintainer ADR work has one canonical entry point, `maintainer adr`, while old
  `maintainer new-adr` wording remains compatible.
- ADR-046 is superseded.
