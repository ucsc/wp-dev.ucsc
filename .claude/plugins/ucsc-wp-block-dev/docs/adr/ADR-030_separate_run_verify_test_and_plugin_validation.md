---
title: "ADR-030: Separate run, verify, test, and plugin validation"
status: Accepted
date: 2026-06-11
---

# ADR-030: Separate run, verify, test, and plugin validation

## Context

Anthropic's run-and-verify workflow distinguishes launching and driving an application from proving a code change in the running application. The `wp-dev.ucsc` environment also requires a nonstandard recipe: Docker, a hosts entry, an environment file, cloned product repositories, dependency installation, WordPress initialization, HTTPS handling, and optional UCSC VPN access.

The existing `run` skill mixed build, startup, tests, and manual smoke checks. The maintainer's `validate` operation checks the development plugin itself, not the WordPress application's behavior.

## Decision

- `run` records and executes the reusable `wp-dev.ucsc` clean-setup, Docker build, launch, and app-driving recipe.
- `verify` builds and launches through that recipe, then checks requested behavior or acceptance criteria in the live WordPress editor or frontend.
- `test` owns automated Jest, PHP, Docker, and browser test execution or creation.
- `maintainer validate` owns Claude plugin structure and quality validation.

Runtime verification must not claim success from a build, lint, type check, or automated test alone. It must observe the requested behavior in the running application. Clean setup runs only when prerequisites are missing and requires approval for privileged, network, destructive, or environment-changing actions.

The environment `README.md` remains authoritative for clean setup. The `ucsc-gutenberg-blocks` `README.md` and `package.json` remain authoritative for product test commands.

### 2026-06-23 amendment — "is it alive?" boundary between `run` and `verify`

Anthropic's run-and-verify guidance frames `verify` as an "are you alive?"
check: prove the change is actually live by observing concrete signals in the
running application, not by trusting the build. This amendment sharpens the
`run`/`verify` split accordingly:

- **`run` only has to prove a DOM is served.** Its success bar is that the
  `wp-dev.ucsc` stack is up and the WordPress app returns a rendered page
  (HTTP 200 with HTML) at the expected URL. `run` does not assert anything about
  a specific block's correctness.
- **`verify` is the per-block "alive" test.** It loads the relevant page(s) in
  the running editor/frontend and asserts on **DOM vitals** — concrete
  landmarks/signals that prove the target block rendered and behaves as
  specified (expected wrapper/class, block markup, rendered content, interactive
  state). `verify` is what actually tests each block; an `argument-hint` of
  `[block] [behavior or acceptance criterion]` reflects this.

**Block fixtures for `verify`.** Preferred: seed a known **sample block on
sample page(s)** as part of the `wp-dev.ucsc` bring-up, so `verify` always has a
deterministic place to look for each block's DOM vitals. Until such fixtures
exist, `verify` falls back to a **smoke test**: look for general signals and
landmarks on the site's main page (and optionally a few other pages) confirming
the app and target block are alive, rather than asserting against a guaranteed
fixture. Seeding the sample-block fixtures during bring-up is a recommended
follow-up, not a precondition for `verify` to run.

This refinement is consistent with the per-repo coverage scope in
[ADR-074](ADR-074_verify_skill_block_coverage_scope.md) and the run-target
resolution in
[ADR-091](ADR-091_run_target_identify_the_run_target_before_invoking_the_driver.md).

## Consequences

The plugin follows the same responsibility split as Anthropic's `/run` and `/verify` workflow while preserving a separate UCSC plugin-maintenance validator. Agents reuse the recorded launch recipe instead of rediscovering it, and verification produces runtime evidence rather than reporting automated checks as proof.
