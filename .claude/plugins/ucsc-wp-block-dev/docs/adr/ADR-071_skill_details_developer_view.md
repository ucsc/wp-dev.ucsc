---
title: "ADR-071: Add skill-details operation to show per-skill frontmatter and invocation settings"
status: Accepted
date: 2026-06-16
---

# ADR-071: Add skill-details operation to show per-skill frontmatter and invocation settings

## Status

Accepted

## Context

The `hub` skill shows a static invocation grid that notes "(default)" for every
skill because no skill currently sets explicit frontmatter flags. This is
accurate today but becomes misleading as soon as any skill adds
`user-invocable`, `disable-model-invocation`, `allowed-tools`, or other
platform fields — the hub grid would still show the old static defaults.

A developer maintaining the plugin needs a live view of each skill's actual
frontmatter to audit invocation posture, spot unintended settings, and confirm
that changes took effect. Reading each `SKILL.md` by hand is the current
workaround; it is error-prone and token-heavy.

## Decision

Add a `skill-details` operation to the `maintainer` skill, backed by a script
at `skills/maintainer/scripts/skill_details.py`. The script reads every
`skills/*/SKILL.md`, parses its YAML frontmatter, and prints:

1. A per-skill row showing actual values for all invocation-relevant fields
   (resolving absent fields to their platform default, not printing "(default)").
2. A flag on any skill that differs from the all-defaults baseline.

Fields reported: `user-invocable`, `disable-model-invocation`,
`model-invocable` (derived: NOT `disable-model-invocation`), `allowed-tools`,
`disallowed-tools`, `context`, `agent`, and any other non-name/description
frontmatter present.

The hub's static grid remains for quick orientation. `skill-details` is the
authoritative live source; run it after any `SKILL.md` frontmatter change.

## Consequences

- **Positive:** Developers can audit actual invocation settings in one call
  without reading individual SKILL.md files.
- **Positive:** Catches frontmatter drift that the static hub grid would
  silently hide.
- **Negative:** One more script to keep in sync when new official frontmatter
  fields are added (ADR-070 allowlist is the reference).
