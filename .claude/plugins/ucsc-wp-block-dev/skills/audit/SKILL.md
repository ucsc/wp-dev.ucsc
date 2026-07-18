---
name: audit
description: This skill should be used when the user asks to "audit the repository", "audit the whole codebase", "do a top-down audit", or "run a full security audit" — existing code across the entire application, not a diff, branch, or PR (use review for those). Runs a phased, read-only audit of the whole repo (WordPress block plugin, theme, or any targeted repository) with parallel specialist subagents and reports prioritized, verified findings.
version: 0.1.0
argument-hint: "[full|tools] [scope or emphasis]"
disable-model-invocation: true
user-invocable: true
---

# Audit — comprehensive top-down repository audit

<!-- doc-slide: Audits the entire repository top-down — maps architecture and trust boundaries, fans out parallel specialist subagents, verifies every finding against real code, and delivers a prioritized read-only report; a tools mode runs the local ucsc-php-review / ucsc-node-review runners. -->

## Implements

implements: ADR-111-AUDIT-TOP-DOWN-REPO-AUDIT

This is **not a diff review** — for a diff, branch, PR, or single file, use
the `review` skill instead. Audit existing code across the whole application,
including code that has not changed recently.

## Modes

- `full` — the phased top-down audit below. Default when a scope or emphasis
  is given without a mode.
- `tools` — run only the local UCSC review runners (`ucsc-php-review`,
  `ucsc-node-review`) against a target and report their findings.

When `audit` is invoked bare with no mode and no scope text, load
[`skill-menu-mode.md`](skill-menu-mode.md) and wait for the user to choose.

Additional scope or emphasis: `$ARGUMENTS`

## Rules

- **Do not modify files.** This is a read-only audit; no code changes, no
  fixes, no formatting.
- Ignore vendor, generated, build, cache, coverage, compiled, and dependency
  directories except when reviewing manifests, lockfiles, or configuration.
- Map the architecture and trust boundaries **before** reporting findings.
- Use parallel specialist subagents where beneficial (this skill is a
  deliberate, user-invoked exception to the single-agent preference —
  see ADR-111).
- Run the repository's existing read-only analysis, test, lint, dependency,
  and profiling commands rather than inventing new standards.
- Verify every candidate finding against the actual code and its real
  execution path. Do not report speculative, stylistic, or generic
  best-practice observations without a concrete impact.
- Deduplicate overlapping findings before reporting.

## full mode — phases

### 1. Map the system

- Identify architecture, frameworks, entry points, trust boundaries,
  authentication flows, data stores, external integrations, queues,
  scheduled jobs, deployment configuration, and major subsystems.
- Identify generated, vendor, build, cache, and irrelevant directories that
  should not be reviewed directly.

### 2. Parallel specialist audits

Fan out specialist subagents to audit:

1. Security and data protection
2. Authentication and authorization
3. Input validation, injection, and output encoding
4. Correctness and error handling
5. Data integrity, transactions, and concurrency
6. Performance, database access, caching, and scalability
7. Frontend security, state management, and performance
8. Dependencies and configuration
9. Testing gaps, observability, and operational reliability
10. Architecture, maintainability, duplication, and dead code

### 3. Read-only analysis commands

Run appropriate read-only analysis commands where available, using the
repository's existing tools and configuration.

**Local review runners.** Detect the UCSC runners as described in
[tools mode](#tools-mode--local-review-runners) below. If either is
available, **offer to run it** as part of this phase (do not run it
unsolicited unless the user already asked for it); fold its output into the
candidate findings, subject to the same verification rules.

### 4. Verify

Check every candidate finding against the actual code before it is reported.

### 5. Report

For each finding provide:

- Severity: critical, high, medium, or low
- Category
- Exact file and line references
- Evidence and affected execution path
- Realistic impact
- Recommended remediation
- Confidence level
- Suggested validation or regression test

### 6. Conclude

- Executive summary
- Architecture and attack-surface overview
- Highest-priority remediation sequence
- Quick wins
- Areas that could not be adequately verified
- Commands and tests that were run

First inspect and map the repository, then conduct the specialist audits,
then consolidate and deduplicate the findings.

## tools mode — local review runners

Two local UCSC packages orchestrate static-analysis tools plus custom rule
packs into one report. Both are read-only and take `[target] [options]`,
with `--only <tools>` and `--json --out <file>` supported:

- **`ucsc-node-review`** — JS/TS/Vue: eslint (+security, a11y,
  no-unsanitized), oxlint, typescript, knip, jscpd, dependency-cruiser.
- **`ucsc-php-review`** — PHP: phpstan, phpcs (+security-audit), phpmd,
  phpcpd, deptrac, composer-unused.

**Detection** (in order; report which runners were found, skip missing ones
gracefully):

1. On `PATH`: `command -v ucsc-node-review` / `command -v ucsc-php-review`.
2. Local checkout fallback: `$HOME/_code/_tools/ucsc-node-review` and
   `$HOME/_code/_tools/ucsc-php-review`.

**Invocation:**

```bash
ucsc-node-review <target>
node "$HOME/_code/_tools/ucsc-node-review/bin/ucsc-node-review.mjs" <target>
```

For PHP in this repo, never use host PHP — run the packaged Docker form:

```bash
docker run --rm -v "$HOME/_code/_tools/ucsc-php-review":/app \
  -v "<target>":/target -w /app composer:2 bin/ucsc-php-review /target
```

(`bin/ucsc-php-review <target>` directly is fine on machines with PHP >= 8.2
and the package's `composer install` already run.)

The runners orchestrate; they do not configure the target — the target keeps
its own `phpcs.xml`, `phpstan.neon`, eslint config, etc. Treat runner output
as **candidate** findings: when folding into a `full` audit report, verify
them like any other candidate; in standalone `tools` mode, present the
runner reports with a short prioritized summary and flag anything that looks
like a false positive.
