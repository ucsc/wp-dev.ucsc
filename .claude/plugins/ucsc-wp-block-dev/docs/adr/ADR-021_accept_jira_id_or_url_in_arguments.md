---
title: "ADR-021: Command handlers accept a Jira ID or a full Jira URL in arguments"
status: Accepted
date: 2026-06-10
---

# ADR-021: Accept a Jira ID or URL in command arguments

## Context

Users reference Jira work in two natural forms: the bare issue key (e.g. `WPM-97`) and the full browse URL (e.g. `https://ucsc-its.atlassian.net/browse/WPM-97`). [ADR-011](retired/ADR-011_universal_command_intake.md) already treats Jira context as optional input resolved by meaning, but it did not state that both forms are first-class arguments for every command.

## Decision

Every command handler accepts an optional Jira reference in its arguments as **either** a bare issue key (`[A-Z]+-\d+`, e.g. `WPM-97`) **or** a full Atlassian URL (e.g. `https://ucsc-its.atlassian.net/browse/WPM-97`), in any position, alongside the target and natural-language request.

The shared `issue-context` normalizer extracts the issue key from a URL (the trailing `/browse/<KEY>` segment) before resolving ticket details, so downstream skills always work from a canonical key. A reference that is neither a valid key nor a parseable Jira URL is treated as part of the natural-language request, not as a Jira key.

Jira remains optional per [ADR-008](ADR-008_prefer_jira_id_for_fix_and_develop.md); this ADR only fixes the accepted argument forms.

## Consequences

Users can paste a Jira URL straight from the browser or type the short key, and any command resolves it identically through `issue-context`. The `argument-hint` "Jira key/URL" already advertised on the skills now has a defined contract behind it.
