---
title: "ADR-001: ucsc-wp-block-dev plugin scope — ucsc-gutenberg-blocks is the target"
status: Accepted
date: 2026-06-08
origin: Adapted from sw-dev ADR-040
---

# ADR-001: ucsc-wp-block-dev plugin scope — ucsc-gutenberg-blocks is the target

## Status

Accepted

## Context

WordPress Gutenberg block development skills and workflow were previously hosted in the `sw-dev` plugin (a Laravel/Vue/WordPress multi-stack toolkit). The block-specific skills (`wp-gutenberg-blocks-ucsc-its`, `run-wordpress`) were too specific to belong alongside Laravel guidance, and the sw-dev plugin was growing unwieldy.

The `ucsc-gutenberg-blocks` WordPress plugin is the primary code target:

- **Repository:** `https://github.com/ucsc/ucsc-gutenberg-blocks`
- **Stack:** WordPress plugin — `@wordpress/scripts`, PHP render callbacks, Jest unit tests
- **Local dev env:** `wp-dev.ucsc` (see ADR-002)

## Decision

The `ucsc-wp-block-dev` Claude Code plugin owns all guidance, skills, and ADRs for `ucsc-gutenberg-blocks` development. It replaces the WP-specific skills that were in `sw-dev`.

**Plugin skills:**

| Skill | Purpose |
|---|---|
| `blocks` | Domain reference — architecture, PHP classes, REST API, LDAP, transients |
| `develop` | Guided flow for adding a new block |
| `fix` | Debug and fix block issues |
| `run` | Build, launch, and smoke-test via wp-dev.ucsc Docker |

The plugin must be loaded explicitly — `.claude/plugins/` is not an auto-discovery path. Load with `claude --plugin-dir .claude/plugins/ucsc-wp-block-dev` or install via `claude plugin install`. Project skills under `.claude/skills/` auto-discover, but plugins require explicit loading or installation.

Other UCSC WordPress plugin repos can be supported by creating additional skills in this plugin or extending existing ones.

## Consequences

- Block work gets focused guidance without Laravel/Vue noise from sw-dev.
- sw-dev no longer carries WP-specific skills — cleaner separation of concerns.
- The `develop` and `fix` skills provide a complete workflow analogous to sw-dev's modes, specific to the WordPress/Gutenberg stack.
