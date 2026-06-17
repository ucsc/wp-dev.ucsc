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
