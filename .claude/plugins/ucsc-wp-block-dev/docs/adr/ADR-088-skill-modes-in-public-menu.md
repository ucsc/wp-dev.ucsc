---
title: "ADR-088: Skill modes appear as public menu lines"
status: Accepted
date: 2026-06-22
related: ["ADR-036", "ADR-081", "ADR-082", "ADR-087"]
---

# ADR-088: Skill modes appear as public menu lines

## Status

Accepted

## Context

The plugin had two kinds of nested workflow language: `develop/feature` and
`develop/fix` were treated as sub-workflows, while `validate` documented
`create` and `run` as modes. The hub table also retained an obsolete `test`
entry after the skill was renamed to `validate`.

`survey` was previously hidden under `develop`, but it is no longer part of the
active workflow surface.

## Decision

Use "mode" for user-facing variants inside a skill, and show each public mode on
its own line in menu and hub surfaces:

- `develop`
- `develop feature`
- `develop fix`
- `validate create`
- `validate run`

Retire `develop/survey` from the live skill inventory. Remove its skill file and
references from public routing surfaces, tests, and README guidance.

## Consequences

- Public workflow lists make the selectable paths explicit without promoting
  feature, fix, create, or run into top-level skills.
- `test` no longer appears in the hub inventory.
- The old survey workflow is no longer callable from the plugin skill tree.
