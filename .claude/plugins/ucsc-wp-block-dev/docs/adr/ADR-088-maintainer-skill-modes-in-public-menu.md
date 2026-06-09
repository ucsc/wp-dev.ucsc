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
- `validate php`
- `validate jest`
- `validate e2e`

`run` and `verify` do not invent submodes: their arguments describe the app
change/URL to demonstrate or the change/acceptance criterion to confirm.

The first bracketed group in a mode-bearing skill's `argument-hint` is the
canonical mode list. Its `skill-menu-mode.md` must explain every listed mode and
show the remaining arguments. Hub, README, and bare-skill menu surfaces use a
compact monospaced text tree: top-level skills reproduce their `argument-hint`
values in a compact basic form, and modes appear as indented children. The
slash menu remains the source for full argument syntax.

The tree is data-driven from `skills/hub/references/skill-tree.json`.
`sync-inventory.sh` discovers live top-level `SKILL.md` directories, rejects
missing or stale tree entries, checks mode lists against each mode-bearing
skill's frontmatter, and renders the README, public hub, maintainer-context hub,
and bare-maintainer menu from the same data. Each node supplies a basic argument
hint and a one-line short description.

`map` is no longer a live skill (ADR-061). The equivalent inventory policy is
owned by `hub`: omit `maintainer` from the public context and show it only in
the explicit maintainer context after the maintainer skill has been invoked.

Retire `develop/survey` from the live skill inventory. Remove its skill file and
references from public routing surfaces, tests, and README guidance.

## Amendment (2026-06-25): every mode-bearing skill's bare menu is a hub-style subtree

The original decision said bare-skill menus "use a compact monospaced text tree,"
but in practice only `maintainer/skill-menu-mode.md` did; `develop` and
`validate` rendered their modes as **Markdown tables**. This amendment makes the
convention uniform and explicit:

- Every **mode-bearing** skill (`develop`, `validate`, `maintainer`, and any
  future one) renders its bare-invocation menu (`skill-menu-mode.md`) as the same
  compact monospaced text tree used by `:hub`, **scoped to that skill's own
  subtree** — the skill as the root node with its modes (and sub-modes) as
  indented children, each line showing the basic argument hint and one-line short
  description. Example:

  ```text
  develop  [feature|fix] [block] [request]   — add or modify WordPress block code
  ├─ feature  [block] [request]  — implement planned block behavior
  └─ fix      [block] [problem]  — diagnose and repair a block defect
  ```

- The tree is rendered from the **same** `skills/hub/references/skill-tree.json`
  data as the hub and README — no skill hand-maintains its own mode list in a
  divergent format. A skill's bare menu is exactly the hub subtree rooted at that
  skill. `run` and `verify` have no modes, so they have no such subtree.
- `sync-inventory.sh` renders each mode-bearing skill's `skill-menu-mode.md` tree
  from `skill-tree.json` (alongside README, public hub, maintainer-context hub,
  and bare-maintainer menu) and `--check` fails on drift, so the per-skill menus
  stay consistent with the hub by construction.
- Prose framing around the tree (when to pick each mode) may remain, but the
  selectable inventory itself is the tree, not a table.

## Consequences

- Public workflow trees make selectable paths explicit without promoting modes
  into top-level skills.
- Slash-menu hints, skill menus, and hub syntax are test-enforced against drift.
- `test` no longer appears in the hub inventory.
- The old survey workflow is no longer callable from the plugin skill tree.
- (2026-06-25) A user who invokes a mode-bearing skill bare sees the same tree
  shape everywhere — hub, README, and each skill's own menu — instead of a tree
  in one place and a table in another. `develop` and `validate` menus convert
  from Markdown tables to hub-style subtrees; `sync-inventory.sh` and the tests
  gain per-skill menu rendering/enforcement (implementation follow-up).
