---
title: "ADR-042: Test operations are references under validate"
status: Accepted
date: 2026-06-15
---

# ADR-042: Test operations are references under validate

## Status

Accepted

## Context

Test work has two different side-effect profiles: creating or changing coverage,
and running existing tests. Both share target, type, Jira, and acceptance
criteria intake, but their execution details and completion output differ.

## Decision

Keep `validate` as the single top-level automated-test entry point. It resolves the
target, test type, and operation, then loads exactly one operation reference:

- `skills/validate/references/create.md`
- `skills/validate/references/run.md`

`create` owns adding or modifying coverage and emitting check-in text. `run`
owns executing existing tests and never emits check-in text unless coverage
changed through a separate approved operation.

## Consequences

- Test creation and execution are separated without adding top-level skills.
- The top-level `test` skill remains small and portable.
- The side-effect boundary is explicit before tools are used.
- ADR-032 ensures both operation references stay linked from `test/SKILL.md`.

