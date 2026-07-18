---
title: "ADR-111: Audit skill: comprehensive top-down repository audit"
status: Accepted
date: 2026-07-17
related: ["ADR-003", "ADR-021"]
---

# ADR-111: Audit skill: comprehensive top-down repository audit

## Status

Accepted

## Context

The `review` skill is scoped to a change surface — a diff, branch, PR, file,
or Jira-scoped block change. There is no workflow for auditing the *entire*
repository top-down, including code that has not changed recently: mapping
architecture and trust boundaries first, then sweeping security, correctness,
performance, data integrity, dependencies, tests, and operational concerns
across the whole application. Ad-hoc requests for this kind of audit were
re-derived from scratch each time, with inconsistent phases, unverified
findings, and no standard report shape.

## Decision

Add a top-level `audit` skill that performs a comprehensive, read-only,
top-down audit of a whole repository:

1. **Map first.** Identify architecture, entry points, trust boundaries,
   auth flows, data stores, integrations, jobs, and deployment config — and
   the vendor/generated/build directories to exclude — before any findings.
2. **Parallel specialist subagents** fan out across fixed audit areas
   (security, authn/authz, correctness, performance, data integrity,
   frontend, dependencies/config, testing/observability, architecture).
   This is a deliberate, user-invoked exception to the single-agent
   preference in ADR-003: the whole-repo surface is too large for one pass,
   and the skill is `disable-model-invocation: true`, so the token cost is
   only ever incurred on explicit user request.
3. **Read-only.** The skill runs existing analysis/lint/test commands where
   available and never modifies files.
4. **Verified findings only.** Every candidate finding is checked against
   the actual code; speculative, stylistic, or generic best-practice notes
   without concrete impact are dropped, and overlapping findings are
   deduplicated.
5. **Standard report.** Prioritized findings with severity, category,
   file/line, evidence, execution path, impact, remediation, confidence, and
   a suggested regression test — followed by an executive summary,
   attack-surface overview, remediation sequence, quick wins, unverified
   areas, and commands run.

6. **Modes and local review runners.** `audit` carries two modes: `full`
   (the phased audit above, the default when a scope is given) and `tools`,
   which runs only the local UCSC review runners — `ucsc-php-review` and
   `ucsc-node-review` (checkouts under `~/_code/_tools/`, or on `PATH` when
   installed globally). In `full` mode, phase 3 detects the runners and
   *offers* to run them, never running them unsolicited; runner output is
   always treated as candidate findings subject to the same verification.
   PHP runner execution uses its packaged Docker form — never host PHP.

`review` remains the skill for diffs, branches, PRs, and single files;
`audit` is for the whole repository.

## Consequences

- **Positive:** Whole-repo audits follow one repeatable phased method with
  verified, deduplicated, prioritized output instead of ad-hoc sweeps.
- **Negative:** A full audit is expensive in tokens and wall time; the
  `disable-model-invocation` guard means it only runs when explicitly
  invoked, and results depend on subagent availability.
