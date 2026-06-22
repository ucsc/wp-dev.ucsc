---
title: "ADR-036: Separate fix and feature workflows"
status: Accepted
date: 2026-06-12
---

# ADR-036: Separate fix and feature workflows

## Context

Fixes and features both lead to a similar implementation cycle: inspect the nearest code patterns, make a focused change, validate it, and hand off the result. Their intake and approval requirements are different.

A fix begins with incorrect behavior and needs evidence-based debugging before a solution is selected. A feature begins with a desired outcome and needs requirements clarification before a design is selected. Treating both as one generic development command obscures these differences and can cause premature implementation.

## Decision

Support `fix` and `feature` as distinct user-facing modes of the `develop`
skill, with unique pre-implementation workflows and a shared implementation
core. Menu and hub surfaces list them as `develop feature` and `develop fix`.

### Fix workflow

The `develop fix` mode must:

1. Secure the target and problem description.
2. Reproduce or otherwise gather evidence for the problem.
3. Debug the behavior and identify the root cause.
4. Present the diagnosis and proposed solution for user review.
5. Obtain user approval of the proposed solution before editing code.
6. Implement the approved fix, then validate the original reproduction and relevant regressions.

The diagnosis must distinguish observed evidence from inference. If new evidence materially changes the approved solution, pause and request approval for the revised solution.

### Feature workflow

The `develop feature` mode must:

1. Secure the target and initial feature request.
2. Clarify requirements, expected behavior, constraints, and acceptance criteria.
3. Inspect the nearest existing implementation patterns.
4. Present a proposed solution for user review, including meaningful behavior or architecture choices.
5. Obtain user approval of the clarified requirements and proposed solution before editing code.
6. Implement the approved feature, then validate it against the agreed requirements.

If implementation reveals a material requirement or design change, pause and request approval before continuing with that changed scope.

### Shared implementation and handoff

After approval, both commands use the same general implementation discipline:

- preserve pre-existing user changes;
- follow the nearest established code patterns;
- make the smallest coherent change that satisfies the approved solution;
- keep related schema, server, editor, and rendering changes synchronized;
- run risk-appropriate validation and report any validation gaps;
- offer to create focused tests for the completed fix or feature change set;
- offer Conventional Commit syntax under ADR-029.

The test offer is distinct from automatically creating tests. If accepted, route to the test workflow with the target, change-set context, and whether the work is a fix or feature preserved.

`develop feature` is the canonical mode name for new behavior. Routing,
documentation, and future workflow language should present feature and fix as
modes of `develop`, not as independent top-level skills.

## Consequences

- Fixes cannot move from a symptom directly into an unreviewed patch.
- Features cannot move from a broad request directly into implementation without clarified requirements and solution review.
- The implementation phase remains consistent and avoids duplicating engineering guidance.
- Tests remain user-approved follow-up work while being offered after every completed change set.
- Migrating from `develop` to `feature` requires coordinated skill, router, menu, test, and documentation updates.
