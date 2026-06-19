---
title: "ADR-022: Command handlers accept a GitHub or Bitbucket pull-request reference"
status: Accepted
date: 2026-06-10
---

# ADR-022: Accept GitHub and Bitbucket PR references in arguments

## Context

[ADR-021](ADR-021-accept-jira-id-or-url-in-arguments.md) made Jira IDs and URLs first-class arguments, but Jira tracks *issues*, not code review. For the WordPress blocks work, **issues live in Jira while pull requests live in GitHub** (e.g. `https://github.com/ucsc/wp-dev.ucsc/pull/5`). Related UCSC webapps repositories host their PRs on **Bitbucket** instead (e.g. `https://bitbucket.org/ucscwebapps/wdt-common/pull-requests/675`). Users want to paste either kind of PR reference into any command.

## Decision

Every command handler accepts an optional pull-request reference in its arguments, in any position alongside the target, natural-language request, and optional Jira reference. Accepted forms:

- **GitHub PR** — a full URL (`https://github.com/<org>/<repo>/pull/<n>`) or a bare `#<n>` / PR number when the GitHub repo is unambiguous. GitHub is the canonical PR host for the ucsc-gutenberg-blocks / wp-dev.ucsc work; use the `gh` CLI to fetch it.
- **Bitbucket PR** — a full URL (`https://bitbucket.org/<workspace>/<repo>/pull-requests/<n>`), used for related UCSC webapps repositories.

A Jira reference and a PR reference may both appear: Jira supplies the issue/acceptance context, the PR supplies the code under review. The normalizer parses each by host and pattern and keeps them distinct; a token matching neither a Jira key/URL ([ADR-021](ADR-021-accept-jira-id-or-url-in-arguments.md)) nor a PR URL/number is part of the natural-language request.

## Consequences

`review` and other commands can take a pasted GitHub or Bitbucket PR link directly. The Jira-for-issues / GitHub-for-PRs split for block work is explicit, and Bitbucket-hosted webapps PRs are also supported without conflating them with GitHub.
