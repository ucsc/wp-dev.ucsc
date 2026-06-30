---
title: "ADR-100: Add a user feedback skill for the plugin"
status: Accepted
date: 2026-06-24
---

# ADR-100: Add a user feedback skill for the plugin

## Status

Accepted

## Context

Users of the `ucsc-wp-block-dev` plugin had no in-product way to report a bug or
suggestion about the plugin's skills, the way Claude Code offers `/bug`. Feedback
was either lost or routed ad hoc. The plugin's existing `retro` mode captures
maintainer-side session lessons, but that is an internal sub-workflow, not a
user-facing channel, and it does not deliver anything off the machine.

A feedback channel must work without standing up bespoke infrastructure, must not
exfiltrate file contents or transcripts, and must never silently lose a note if
the network or destination is unavailable.

## Decision

Add a user-invocable `feedback` skill — the plugin analog of Claude Code's
`/bug`. It collects a short note plus a small, explicit set of session context
(category, named skill/target, plugin version, timestamp, and OS string) and
delivers it through `scripts/submit-feedback.sh`.

- **Configurable destination.** Delivery is chosen by environment variables, in
  order: a REST endpoint (`UCSC_FEEDBACK_ENDPOINT`, POST `application/json`,
  optional bearer `UCSC_FEEDBACK_TOKEN`), else email (`UCSC_FEEDBACK_EMAIL`),
  else a local-only saved copy. No endpoint is hardcoded.
- **Never lose feedback.** A local JSON copy is always written first (under the
  `ucsc-wp-block-dev` cache dir), then delivery is attempted; failures keep the
  saved copy and report its path.
- **Minimal, explicit payload.** Only the fields above are sent — no file
  paths, branch names, contents, diffs, or conversation transcripts. The payload is built with
  `python3 json.dumps` (values passed via env) to avoid injection.
- **Single deterministic script (ADR-094).** All collection, payload building,
  and transport live in one bundled wrapper the skill runs, rather than ad-hoc
  inline commands.

The skill is added to the live inventory (README, AGENTS routing, hub, slide
deck, and `EXPECTED_LIVE_SKILLS`) via `sync-inventory.sh`.

## Consequences

- **Positive:** plugin users get a first-class, Claude-`/bug`-style feedback path
  that works offline (local save) and scales up to a real endpoint or email with
  one env var; no PII or transcript leaves the machine without configuration.
- **Positive:** captured feedback is structured JSON, so it can later feed the
  maintainer backlog or a triage endpoint.
- **Negative:** delivery requires the operator to configure an endpoint or email;
  until then feedback only accumulates locally and must be collected by hand.
- **Negative:** adds another top-level skill to keep in inventory sync and a
  small env-var configuration surface to document.
