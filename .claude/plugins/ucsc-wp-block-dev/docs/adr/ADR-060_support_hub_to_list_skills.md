---
title: "ADR-060: Support :hub to list plugin skills"
status: Accepted
date: 2026-06-16
---

# ADR-060: Support :hub to list plugin skills

## Context

The `ucsc-wp-block-dev` plugin exposes several skills (`map`, `feature`, `fix`,
`develop`, `run`, `verify`, `test`, `review`, `retrospective`, and the hidden
`maintainer`). Users need a fast, predictable way to see *what the plugin can do*
without recalling each skill name or reading the README.

The `map` skill already routes a natural-language or Jira request to the right
workflow, but routing is not the same as enumeration: `map` answers "which skill
fits this request," whereas a user often just wants "list everything available."
Forcing discovery through `map` couples a simple inventory request to the
routing logic and its token cost.

## Decision

Support `:hub` as an explicit, lightweight way to list the plugin's skills.
Invoking `ucsc-wp-block-dev:hub` (shorthand `:hub`) prints the available skills
and commands with a one-line purpose for each, grouped by workflow, and points
to `map` for routing when the user is unsure which to use.

1. `:hub` is enumeration only — it lists skills and commands; it does not parse a
   request or perform routing (that remains `map`'s job).
2. The listing covers user-facing workflow skills. Hidden manual skills
   (e.g. `maintainer`, per ADR-046) are noted separately or omitted from the
   primary list, consistent with their hidden status.
3. `:hub` stays token-frugal (ADR-058): a static inventory, not a scan.

## Consequences

- **Positive:** Users get a one-shot overview of plugin capabilities without
  guessing skill names or invoking the router.
- **Positive:** Clear separation of concerns — `:hub` enumerates, `map` routes.
- **Negative:** The hub inventory is another surface to keep in sync with the
  skill set; the maintainer `check-references` / structural tests should guard it
  against drift.

## Amendment (2026-06-23): repository detection and session-target setting

Block work spans two repos with different layouts — `ucsc-blocks`
(`src/blocks/<slug>/`) and `ucsc-gutenberg-blocks` (`src/blocks/<Name>.js`).
Users repeatedly re-specified the block target across skills, and `:hub` already
sits at the start of a session, so it is the natural place to establish that
target once.

Extend `:hub` so it can resolve, validate, and **set** the session block target
(the ADR-093 contract) in addition to enumerating skills:

1. **Repository detection is allowed, scans are not.** `:hub` may inspect the
   working-directory *path string* to determine which repo it is in and offer
   that repo's targets. This is a token-free string operation
   (`resolve_target.sh`), not the filesystem scan that decision point 3 of this
   ADR forbids; that prohibition still stands for building the inventory.
2. **A passed target is validated before adoption.** When the user runs
   `:hub <block>`, validate it with `block_target_check.sh` and resolve its repo
   and on-disk path from `targets.md` before persisting. An invalid target is
   reported and not persisted; resolution falls through to CWD detection.
3. **`:hub` sets the session target but still does not route.** Persisting the
   target via `session_target.sh set <slug> <repo> <path>` lets later skills
   reuse it without re-asking. `:hub` still never invokes a workflow skill —
   setting session state is not routing.

This adds `argument-hint: "[block]"` to the hub skill and a "Current repository
and its block targets" section to its `SKILL.md`. The drift surface noted above
now also includes `targets.md` as the canonical per-repo target list.
