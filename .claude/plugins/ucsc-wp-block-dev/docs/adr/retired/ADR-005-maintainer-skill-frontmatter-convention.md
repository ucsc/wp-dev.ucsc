---
title: "ADR-005: Skill frontmatter uses supported skill and command fields"
status: Superseded
date: 2026-06-09
---

# ADR-005: Skill frontmatter uses supported skill and command fields

## Status

Superseded by ADR-011

## Context

Early skill files carried extra YAML frontmatter keys beyond the standard Claude Code skill schema:

- `paths:` — globs scoping which plugin files the skill relates to
- `user-invocable: false` — marking the `blocks` skill as an auto-loaded reference rather than a slash command
- `argument-hint:` — a usage hint for the argument-taking skills (`develop`, `fix`, `maintainer`, `run`)

The plugin originally limited every skill to `name` and `description`. The
Laravel/Vue and WordPress plugins now share a command-intake contract, and
current command skills support invocation and argument metadata.

## Decision

Reference-only skills keep minimal frontmatter. User-facing command skills may
also use:

- `disable-model-invocation`
- `argument-hint`
- `arguments`

Unsupported fields such as `paths` and `user-invocable` remain excluded.

## Consequences

- Command discovery can show useful argument hints.
- Routers can remain manual-only or model-invocable by design.
- Tests reject unknown frontmatter keys.
