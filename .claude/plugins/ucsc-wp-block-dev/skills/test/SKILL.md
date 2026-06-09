---
name: test
description: Add or run focused PHP, Jest, Docker, and browser tests for a target Gutenberg block, feature, fix, or Jira acceptance criterion.
disable-model-invocation: false
argument-hint: "[target | test request | Jira key/URL]"
arguments: [target, input]
---

# Test Mode

## Universal Command Intake

Apply ADR-011: resolve the test target, natural-language verification goal, and optional Jira key/URL from the full input. Infer the test type when the target makes it clear, and ask one concise question only when the missing target or test type prevents useful work.

Choose the narrowest useful layer:

| Layer | Use for |
|---|---|
| PHP | Render callbacks, sanitization, REST routes, transient behavior |
| Jest | Block registration, attributes, editor controls, client behavior |
| Build | Compilation and dependency regressions |
| Browser/Docker | Editor insertion, frontend rendering, integration smoke tests |

Read the nearest existing test pattern before adding coverage. Run focused checks first, then broaden only when risk requires it. Jira acceptance criteria may define the assertions but Jira is optional.
