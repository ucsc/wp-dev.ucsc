---
title: "ADR-093: Persist the resolved block target across the session for all block skills"
status: Accepted
date: 2026-06-23
---

# ADR-093: Persist the resolved block target across the session for all block skills

## Status

Accepted

## Context

Most skills operate on a specific block target (e.g. `ucsc-events`,
`calendar-feed`, `class-schedule`). Today each skill resolves that target with its
own intake logic: ADR-084 established a selection contract for the develop family,
ADR-090 added cwd inference for `develop`/`fix`, and ADR-091 handles the *plugin*
target for `run`. The result is that the block target is re-derived (and often
re-asked) every time a different skill runs, even within one working session, and
the behavior is inconsistent from skill to skill.

The supported block targets span **two distinct git repos / WordPress plugins**:

- `ucsc-gutenberg-blocks` — https://github.com/ucsc/ucsc-gutenberg-blocks
- `ucsc-blocks` — https://github.com/ucsc/ucsc-blocks

(plus a third, `ucsc-custom-functionality`, maintained by a separate team).
`develop/references/targets.md` already enumerates targets across all of these and
each `target-<slug>.md` declares its owning plugin, so the cross-repo index
already exists. What is missing is a single, persistent, cross-skill resolution
contract.

## Decision

Treat the resolved block target as a **persistent session value** shared by all
block-operating skills.

### Persistence

The resolved target is stored in a session cache file:

```
~/.cache/ucsc-wp-block-dev/session-target   (override dir with $UCSC_WP_BLOCK_DEV_CACHE)
```

It records the canonical block slug, its owning repository/plugin, and the
target's absolute filesystem path (e.g.
`ucsc-events  ucsc-blocks  /…/plugins/ucsc-blocks/src/blocks/ucsc-events`; see the
2026-06-23 amendment below). This is the same cache root used by ADR-085's backlog
cache; it is session/dev-machine scoped, never committed, and may be cleared at
any time.

### Resolution order (every block-operating skill)

1. **Explicit ARGUMENTS** — a target named in the skill arguments always wins and
   **replaces** the persisted value (the user may switch targets mid-session by
   passing a new one).
2. **Session cache file** — if no argument is given and a value is persisted,
   adopt it without re-asking.
3. **CWD inference** — otherwise infer from the working directory: a
   `.../src/blocks/<slug>` segment, or a directory matching a slug/alias in
   `develop/references/targets.md` (ADR-090). State the inferred target so the
   user can correct it.
4. **Prompt** — only when the above are ambiguous or empty, prompt with the
   `targets.md` list plus an "other" option (ADR-084).

Whenever a target is newly resolved or changed (steps 1, 3, 4), write it back to
the cache file so subsequent skills reuse it.

### Scope

This contract applies to every skill that operates on a block target —
`develop` (+ `feature`/`fix`), `verify`, `validate`, `run`, and `review`. It
does **not** apply to `maintainer` (whose target is the plugin itself, ADR-085)
or `hub` (enumeration only, no target). `run` continues to also resolve its *plugin* target (ADR-091);
the block target persisted here additionally scopes its `drive` step (ADR-091
amendment).

## Consequences

- **Positive:** A target is resolved once per session and reused across skills;
  fewer repeated prompts; deterministic, cwd-aware behavior; one cross-repo
  resolution contract instead of per-skill variants.
- **Positive:** Switching targets is explicit and predictable — pass a new
  ARGUMENTS target and every later skill follows it.
- **Negative:** Introduces a small piece of session state on disk that can go
  stale (mitigated: ARGUMENTS and cwd always override; the file is cheap to
  clear). Rolling the contract into every skill is a multi-skill change tracked
  as follow-up.

## Amendment (2026-06-23) — secure repository, target, and filesystem path

When a block target is **secured**, specify all three of:

1. **Repository** — the owning repo/plugin (`ucsc-blocks` or
   `ucsc-gutenberg-blocks`). A slug is ambiguous across the two repos, so the
   repository must be named alongside the target, not inferred later.
2. **Target** — the canonical block slug.
3. **Filesystem path** — the absolute on-disk path to the block (the
   `src/blocks/<slug>/` directory in ucsc-blocks, or the single
   `src/blocks/<Name>.js` file in ucsc-gutenberg-blocks).

Rationale: downstream skills need the repository to disambiguate the slug and the
concrete path to act on files without re-deriving the location. The session cache
line therefore holds `"<slug> <repo> <path>"`, and
`develop/scripts/session-target.sh set <slug> <repo> [path]` now requires the
repository (its `get` emits all three; `repo` and `dir` print the individual
fields). The path should be validated with `block-target-check.sh` before it is
persisted. This refines — and does not replace — the resolution order above.

## Related

- ADR-084: Make selecting a block target the primary workflow
- ADR-090: Infer block target from CWD
- ADR-091: Identify the run target before invoking the driver (drive-step surface)
- ADR-085: Maintainer target is the plugin itself
