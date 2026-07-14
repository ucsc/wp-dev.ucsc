---
title: "ADR-105: Support multiple WP local runtimes (wp-env, Local, WP Engine) beyond home-rolled wp-dev.ucsc"
status: Proposed
date: 2026-06-25
related: ["ADR-002", "ADR-091", "ADR-095"]
---

# ADR-105: Support multiple WP local runtimes (wp-env, Local, WP Engine) beyond home-rolled wp-dev.ucsc

## Status

Accepted

Date: 2026-06-30

## Context

The `run`, `validate`, and `verify` skills are **hardwired to the home-rolled
`wp-dev.ucsc` Docker Compose stack** (ADR-002). The `run` driver
([`skills/run/driver.sh`](../../skills/run/driver.sh)) shells out directly to
`docker compose ...` and `docker compose exec wpcli wp ...`, and the canonical
URL/host (`https://wp-dev.ucsc/`), credentials, and container/service names are
baked into the skills (see
[`skills/run/references/environments.md`](../../skills/run/references/environments.md)).

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

Introduce a small **runtime abstraction** so the block skills target a
selectable WordPress local runtime instead of assuming `wp-dev.ucsc`. Adopted
and implemented in phases:

1. **Runtime profiles.** A named runtime (`wp-dev-ucsc` (default), `wp-env`,
   `local`, `wpe`, `byo`) resolves the three things the skills actually need:
   - **lifecycle** — how to build/up/down the stack,
   - **WP-CLI invocation** — how to run `wp <command>`,
   - **base URL / host + credentials** — what to build/drive against.
   Detection lives in `skills/run/lib/detect-environment.sh`; the profile
   itself is a driver script in `skills/run/drivers/`.

2. **Driver indirection.** `driver.sh` is a router: it resolves the runtime
   (explicit or auto-detected) and dispatches to `drivers/<runtime>.sh`, which
   exposes a common phase interface (`inspect`, `build`, `launch`, `smoke`,
   `drive <URL>`, `down`, `all`). `drivers/wp-dev-ucsc.sh` carries the original
   behavior verbatim — the default is unchanged. Shared, environment-agnostic
   logic (the headless-Chrome `drive` implementation) lives in
   `skills/run/lib/drive.sh` so drivers don't duplicate it.

3. **Solve LDAP first (gating constraint) — still open.** Campus Directory's
   LDAP/VPN need is **not** solved in any alternate runtime yet. `wp-env` is
   explicitly documented as unsupported for LDAP-dependent blocks; non-LDAP
   blocks work. This remains the precondition for full parity on any runtime.

4. **Opt-in, additive, default-unchanged.** Runtime support is additive: the
   default stays `wp-dev.ucsc` (auto-detection prefers it whenever this repo's
   own `docker-compose.yml` + LDAP `Dockerfile` markers are present — i.e.
   always, in this repo), and no existing workflow changes unless a developer
   explicitly selects another runtime (`driver.sh wp-env ...`, `driver.sh local
   ...`, `driver.sh byo ...`).

**Implementation status:**
- Phase 1–3 (detection layer, router, `wp-dev-ucsc` driver extraction, BYO
  fallback, multi-environment-aware `validate` scripts, portability docs): done.
- Phase 4a (`wp-env` full driver — `inspect`/`build`/`launch`/`smoke`/`drive`/
  `down` via the `wp-env` CLI, `.wp-env-example.json` scaffold): done.
- Phase 4b (`local` / LocalWP full driver): **done**. Local has no first-party
  scriptable CLI (the official `getflywheel/local-cli` is archived), so
  `drivers/local.sh` shells out to the third-party `lwp`
  (cartpauj/localwp-cli), which talks to Local's own local GraphQL API and
  requires the Local GUI app to be installed and running at least once.
  Requires `UCSC_LOCAL_SITE=<name-or-id>` (no sensible default — Local site
  names are per-developer); the site URL is resolved from `lwp status <site>`,
  overridable via `UCSC_LOCAL_URL`. Like `wp-env.sh`, the `build` phase runs
  `npm` on the host, assuming the standard Local workflow of symlinking the
  Local site's plugin directory to this repo's own checkout rather than a
  second, disconnected copy. Covered by `test-regression-local.sh`.
- `wpe` (WP Engine): still BYO-only, no dedicated driver.

**Not decided:** whether WP Engine warrants a dedicated driver beyond BYO.

## Consequences

- **Positive (realized for wp-env and Local, pending for WP Engine):**
  unhardwires the skills from one bespoke stack for non-LDAP work; a developer
  on `wp-env` or Local can now run the full lifecycle
  (`inspect`/`build`/`launch`/`smoke`/`drive`/`down`) without touching
  `wp-dev.ucsc`; isolates environment assumptions behind one abstraction
  (`lib/detect-environment.sh` + `drivers/*.sh`) instead of scattering them.
- **Negative / risks:** real complexity (each runtime has different lifecycle,
  CLI, URL, and cert handling) — now incurred for `wp-env` and `local`; the
  Local driver additionally depends on a third-party CLI (`lwp`, not an
  official Local project) and requires the Local GUI app running; the LDAP/VPN
  constraint still makes full parity impossible for Campus Directory on
  `wp-env` and `local` (and likely `wpe` too, until solved); the abstraction adds
  indirection and test surface, mitigated by `drivers/wp-dev-ucsc.sh` preserving
  the original behavior verbatim and a regression suite
  (`skills/run/test-regression-wp-dev-ucsc.sh`).
- **Tracking:** a dedicated `wpe` driver remains open; revisit when a
  developer is blocked on it, or when LDAP-in-wp-env/LDAP-in-local becomes
  worth solving.
