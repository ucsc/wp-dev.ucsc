---
title: "ADR-091: Identify the run target before invoking the driver"
status: Accepted
date: 2026-06-23
---

# ADR-091: Identify the run target before invoking the driver

## Status

Accepted

## Context

The `run` skill drives a single shared `wp-dev.ucsc` Docker runtime that hosts
two UCSC plugins — `ucsc-blocks` and `ucsc-gutenberg-blocks`. `run/driver.sh`
autodetects which plugin to build from the current working directory (any
`.../wp-content/plugins/<slug>` segment) and accepts a `UCSC_PLUGIN=<slug>`
override.

Relying on that autodetection effectively defers target identification into the
driver. When the working directory is ambiguous — invoked from the `wp-dev.ucsc`
root, from a subdirectory of one plugin while the other was intended, or from an
unrelated path — the driver can silently build, launch, or smoke-test the wrong
plugin. The skill's Universal Command Intake nominally resolves a target but only
asks "when it cannot be inferred safely," which lets the driver guess. This is
inconsistent with the target-first contract the other skills follow
(ADR-084/085/090).

## Decision

When entering the `run` skill, identify and declare the plugin/app target
**before** invoking `driver.sh`:

1. Resolve the target during Universal Command Intake — from explicit input, Jira
   context, or the current working directory — and confirm it when ambiguous,
   before the first driver call.
2. Pass the resolved target explicitly to the driver via `UCSC_PLUGIN=<slug>`
   rather than relying on cwd autodetection.
3. If the target cannot be determined unambiguously, ask one concise question
   offering the known plugins (`ucsc-blocks`, `ucsc-gutenberg-blocks`) plus an
   "other" slug — do not let the driver pick.
4. Echo the chosen target in the first status line so a wrong target is caught
   before a build or launch runs.

### Amendment (2026-06-23): the drive step resolves the block surface too

The decision above resolves the *plugin/app* target for `driver.sh`. The `drive`
phase introduces a second target — *which block surface* (published page / block)
to render and assert on. That selection MUST derive from the same cwd-resolved
target as the build, following ADR-090's CWD inference, and not from incidental
signals such as the current branch name or whichever published page happens to
exist:

5. When inference yields a `.../src/blocks/<slug>` segment, adopt `<slug>` as the
   block surface to drive and **state it before choosing a page**. This extends
   ADR-090's skill list (`develop`/`feature`/`fix`/`verify`/`validate`) to cover
   `run`'s `drive` step.
6. When multiple published pages embed the block, pick the page whose block
   matches the resolved surface and name the page (id/slug) in the status line.
7. When no cwd block slug is resolvable (e.g. invoked from the `wp-dev.ucsc`
   root), fall back to ADR-090's selection prompt rather than guessing a page.

## Consequences

- **Positive:** Prevents building/launching the wrong plugin in the shared
  runtime; makes `run` deterministic and testable; aligns `run` with the
  target-first family (ADR-084 block target, ADR-085 maintainer target,
  ADR-090 infer-from-cwd, ADR-066 validate `PLUGIN_SLUG`).
- **Negative:** Adds slight upfront intake friction — one confirmation when the
  target is ambiguous — which is intentional to avoid wide-scope mistakes.

## Related

- ADR-084: Make selecting a block target the primary workflow
- ADR-085: Treat maintainer mode target as the plugin itself
- ADR-090: Infer block target from CWD
- ADR-066: Validate driver targets the plugin via `PLUGIN_SLUG`
