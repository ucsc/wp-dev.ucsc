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

## Check-in text (ADR-019)

When you add or meaningfully change coverage, finish by emitting ready-to-paste check-in text:

1. A **Jira title** — short imperative summary of the test work.
2. A **description** as a [Conventional Commit](https://www.conventionalcommits.org/): a `type(scope): subject` header plus a body.

`type` is normally `test` (use `fix`/`feat` only if block behavior also changed); `scope` is the kebab-case target block. The body names the layer (PHP/Jest/Docker/Browser), the behaviors covered, and any runtime caveats. Reference a Jira key in the footer when known. Skip this step for a plain test run that changed no coverage.
