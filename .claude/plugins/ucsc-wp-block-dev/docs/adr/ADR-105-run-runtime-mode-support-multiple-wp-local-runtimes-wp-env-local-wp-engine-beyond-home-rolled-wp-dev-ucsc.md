---
title: "ADR-105: Support multiple WP local runtimes (wp-env, Local, WP Engine) beyond home-rolled wp-dev.ucsc"
status: Proposed
date: 2026-06-25
related: ["ADR-002", "ADR-091", "ADR-095"]
---

# ADR-105: Support multiple WP local runtimes (wp-env, Local, WP Engine) beyond home-rolled wp-dev.ucsc

## Status

Proposed

> This is a forward-looking idea, not an accepted change. Nothing in the plugin
> behaves differently because of it yet. It records a direction and the
> constraint (LDAP) that must be solved first.

## Context

The `run`, `validate`, and `verify` skills are **hardwired to the home-rolled
`wp-dev.ucsc` Docker Compose stack** (ADR-002). The `run` driver
([`skills/run/driver.sh`](../../skills/run/driver.sh)) shells out directly to
`docker compose ...` and `docker compose exec wpcli wp ...`, and the canonical
URL/host (`https://wp-dev.ucsc/`), credentials, and container/service names are
baked into the skills (see
[`skills/run/references/environment.md`](../../skills/run/references/environment.md)).

This environment is **not** `@wordpress/env` (wp-env), Local (LocalWP), ddev, or
WP Engine — it is bespoke. The main reason it was home-rolled: the *Campus
Directory* block needs the PHP **LDAP** extension and a UCSC VPN connection to
the LDAP server, which off-the-shelf local runtimes did not cleanly support at
the time. So the repo ships a custom `Dockerfile`
(`wordpress:6.5.5-php8.1-apache` + LDAP + Xdebug) and a layered compose set.

The cost of hardwiring: a developer who runs their UCSC blocks under a different
local runtime (wp-env, Local, or a WP Engine local setup) cannot use `run` /
`validate e2e` / `verify` as-is — the driver assumes the `wp-dev.ucsc`
containers and host. There is no abstraction over "how to bring the stack up,"
"how to run WP-CLI," or "what base URL to drive."

## Decision

**Direction (not yet adopted):** introduce a small **runtime abstraction** so the
block skills target a selectable WordPress local runtime instead of assuming
`wp-dev.ucsc`. Sketch only — to be designed if/when prioritized:

1. **Runtime profiles.** Define a named runtime (e.g. `wp-dev-ucsc` (default),
   `wp-env`, `local`, `wp-engine`) that resolves the three things the skills
   actually need:
   - **lifecycle** — how to build/up/down the stack,
   - **WP-CLI invocation** — how to run `wp <command>`,
   - **base URL / host + credentials** — what to build/drive against.
   Model it on the existing source-base resolver pattern (ADR-095) and the
   "identify the target before driving" discipline (ADR-091), keeping the
   default behavior identical to today.

2. **Driver indirection.** `driver.sh` (and the validate/verify stack checks)
   call the profile's lifecycle/CLI/URL hooks rather than hardcoded
   `docker compose` + `wp-dev.ucsc`. The `wp-dev-ucsc` profile is the current
   behavior verbatim.

3. **Solve LDAP first (gating constraint).** Standardizing onto a portable
   runtime is only viable once Campus Directory's LDAP need is met there — e.g. a
   wp-env `.wp-env.json` with a custom PHP image / mappings that include the LDAP
   extension and VPN reachability, or documented Local/WP Engine equivalents.
   Until LDAP works in a candidate runtime, that runtime can only support
   non-LDAP blocks. **This is the precondition for the whole effort.**

4. **Opt-in, additive, default-unchanged.** Any runtime support is additive: the
   default stays `wp-dev.ucsc`, and no existing workflow changes unless a user
   explicitly selects another runtime.

**Not deciding now:** the profile schema, where it is configured (session value
vs. file), or which runtime to support first. Those are deferred until this is
prioritized.

## Consequences

- **Positive (if pursued):** unhardwires the skills from one bespoke stack;
  lets developers use their preferred local runtime; creates a natural home for
  solving LDAP portably and standardizing onto a maintained runtime; isolates
  environment assumptions behind one abstraction instead of scattering them.
- **Negative / risks:** real complexity (each runtime has different lifecycle,
  CLI, URL, and cert handling); the LDAP/VPN constraint may make full parity
  impossible for Campus Directory on some runtimes; an abstraction adds
  indirection and test surface. Because this is **Proposed**, none of that cost
  is incurred yet — the risk today is only that the idea is forgotten, which this
  ADR mitigates.
- **Tracking:** revisit when a concrete need arises (a developer blocked on a
  non-`wp-dev.ucsc` runtime, or a decision to standardize), and only after a
  viable LDAP path exists in the candidate runtime.
