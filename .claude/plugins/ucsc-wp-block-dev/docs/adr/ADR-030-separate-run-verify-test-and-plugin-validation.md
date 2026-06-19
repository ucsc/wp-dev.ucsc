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

## Consequences

The plugin follows the same responsibility split as Anthropic's `/run` and `/verify` workflow while preserving a separate UCSC plugin-maintenance validator. Agents reuse the recorded launch recipe instead of rediscovering it, and verification produces runtime evidence rather than reporting automated checks as proof.
