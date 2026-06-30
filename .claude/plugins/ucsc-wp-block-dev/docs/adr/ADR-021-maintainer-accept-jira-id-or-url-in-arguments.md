---
title: "ADR-021: Command handlers accept Jira IDs/URLs and GitHub/Bitbucket PR references"
status: Accepted
date: 2026-06-10
---

# ADR-021: Accept a Jira ID or URL in command arguments

## Context

Users reference Jira work in two natural forms: the bare issue key (e.g. `PROJECT-123`) and the full browse URL (e.g. `https://example.atlassian.net/browse/PROJECT-123`). [ADR-011](retired/ADR-011-maintainer-universal-command-intake.md) already treats Jira context as optional input resolved by meaning, but it did not state that both forms are first-class arguments for every command.

## Decision

Every command handler accepts an optional Jira reference in its arguments as **either** a bare issue key (`[A-Z]+-\d+`, e.g. `PROJECT-123`) **or** a full Atlassian URL (e.g. `https://example.atlassian.net/browse/PROJECT-123`), in any position, alongside the target and natural-language request.

The shared `issue-context` normalizer extracts the issue key from a URL (the trailing `/browse/<KEY>` segment) before resolving ticket details, so downstream skills always work from a canonical key. A reference that is neither a valid key nor a parseable Jira URL is treated as part of the natural-language request, not as a Jira key.

Jira remains optional per [ADR-008](retired/ADR-008-develop-prefer-jira-id-for-fix-and-develop.md); this ADR only fixes the accepted argument forms.

## Pull-request references (absorbed from ADR-022)

Every command handler also accepts an optional pull-request reference in any
argument position, alongside the target, natural-language request, and optional
Jira reference. Accepted forms:

- **GitHub PR** — full URL (`https://github.com/<org>/<repo>/pull/<n>`) or bare
  `#<n>` when the repo is unambiguous. Use `gh` CLI to fetch. GitHub is the
  canonical PR host for ucsc-gutenberg-blocks / wp-dev.ucsc work.
- **Bitbucket PR** — full URL (`https://bitbucket.org/<workspace>/<repo>/pull-requests/<n>`),
  used for related UCSC webapps repositories.

A Jira reference and a PR reference may appear together: Jira supplies the
issue/acceptance context, the PR supplies the code under review. A token matching
neither a Jira key/URL nor a PR URL/number is part of the natural-language request.

## Consequences

Users can paste a Jira URL, short key, GitHub PR link, or Bitbucket PR link in any
position, and the command resolves each through the appropriate normalizer. The
Jira-for-issues / GitHub-for-PRs split is explicit, and Bitbucket-hosted webapps
PRs are also supported.
