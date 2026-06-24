---
title: "ADR-061: Remove map, rely on native skill discovery"
status: Accepted
date: 2026-06-16
---

# ADR-061: Remove map, rely on native skill discovery

## Status

Accepted

## Context

ADR-039 introduced `map` as a single app-aware skill router and inventory.
Review against Anthropic's official plugin documentation
(`plugin-dev:plugin-structure`) confirms that a "router" or "entry point" skill
is **not** a standard plugin component. Claude Code's standard surface is
`commands/`, `agents/`, `skills/`, and `hooks/`, all auto-discovered, and:

- **Routing is native.** Claude selects the right skill from each skill's
  `description` field. A `map` skill hand-rolls behavior the platform already
  provides for free.
- **Listing is native.** User-invocable skills already appear in the `/` slash
  menu.

`map` therefore duplicated platform behavior and overlapped with `hub`
(ADR-060), which provides a curated human-readable inventory. Maintaining `map`
also imposed a routing contract on the test suite (`routers = ["map"]`, a
dedicated entry-point test) for no functional gain.

## Decision

Remove the `map` skill. Rely on Claude Code's native skill discovery for
routing — i.e. invest in clear, well-triggered skill `description`s rather than a
router skill. Keep `hub` (ADR-060) as the single curated inventory surface; it
enumerates skills but does not route. To act on a request, invoke the relevant
skill directly or let Claude select it by description.

This supersedes ADR-039. The input-resolution contract from ADR-011 still
applies to the workflow handler skills (`feature`, `fix`, `develop`, `run`,
`verify`, `test`, `review`, `maintainer`); it is simply no longer mediated by a
router.

## Consequences

- **Positive:** Removes a non-standard component and the duplicated routing
  contract; fewer skills and tests to maintain.
- **Positive:** Reinforces that skill `description` quality is the routing
  mechanism (see `plugin-dev:skill-development`).
- **Negative:** No bespoke app-detection/routing narrative; that responsibility
  moves into individual skill descriptions and the `hub` inventory.
- The public workflow inventory now lives in `README` and `hub`, not `map`.
