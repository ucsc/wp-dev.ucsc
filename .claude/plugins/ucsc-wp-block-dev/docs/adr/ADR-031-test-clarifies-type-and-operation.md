---
title: "ADR-031: Test clarifies type and operation"
status: Superseded
date: 2026-06-11
---

# ADR-031: Test clarifies type and operation

Superseded by ADR-042. The type and operation clarification remains, but the
operation-specific workflows now live in `test/references/create.md` and
`test/references/run.md`.

## Context

The `test` command serves two distinct workflows: creating or changing test coverage, and running existing tests. It also supports three different test systems with different setup and execution paths: PHP, Jest, and end-to-end browser/Docker testing.

Inferring either dimension can cause unwanted file changes, run the wrong suite, or spend time inspecting an irrelevant test layer.

## Decision

Before using tools, `test` always confirms:

1. Test type: `php`, `jest`, or `e2e`.
2. Operation: `create` or `run`.

The skill asks one concise confirmation question, combines missing values into that question, and waits for the user's answer. Build checks may support these workflows but are not a separate test type.

For now, one `test` skill owns both operations so users have one test entry point and shared target/Jira intake. A future ADR may split test creation and test execution into separate skills if usage, clarity, token cost, or permission boundaries justify it.

## Consequences

Test work begins with explicit scope and side-effect intent. Users are not surprised by generated files when they wanted execution, or by a test run when they wanted new coverage. The command remains unified while preserving a documented path to split it later.
