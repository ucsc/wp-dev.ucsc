---
name: test
description: Create or run focused PHP, Jest, or end-to-end tests for a target Gutenberg block, feature, fix, or Jira acceptance criterion. Always clarify the test type and whether the user wants test creation or test execution before acting.
disable-model-invocation: false
argument-hint: "[php|jest|e2e] [target | test request | Jira key/URL]"
arguments: [type, input]
---

# Test Mode

## Universal Command Intake

Apply ADR-011: resolve the test target, natural-language test goal, and optional Jira key/URL from the full input.

## Confirm Type And Operation

Before reading files, creating coverage, or running commands, explicitly confirm both:

1. **Type** — `php`, `jest`, or `e2e`.
2. **Operation** — `create` tests or `run` existing tests.

Always ask one concise question only: confirm the resolved values and request any missing value in the same question. Example: "Should I create or run Jest tests for Class Schedule?" Wait for the answer before using tools, even when one value appears inferable from context.

Use these test types:

| Type | Use for |
|---|---|
| `php` | Render callbacks, sanitization, REST routes, transient behavior |
| `jest` | Block registration, attributes, editor controls, client behavior |
| `e2e` | WordPress editor insertion, frontend rendering, Docker/browser integration |

For `create`, read the nearest existing test pattern before adding focused coverage, then run the created test. For `run`, execute the narrowest existing test first and broaden only when requested or risk requires it. Build checks may support any type but are not a fourth test type. Jira acceptance criteria may define assertions but Jira is optional.

## Check-in text (ADR-019)

When `create` adds or meaningfully changes coverage, finish by emitting ready-to-paste check-in text:

1. A **Jira title** — short imperative summary of the test work.
2. A **description** as a [Conventional Commit](https://www.conventionalcommits.org/): a `type(scope): subject` header plus a body.

The commit `type` is normally `test` (use `fix`/`feat` only if block behavior also changed); `scope` is the kebab-case target block. The body names the test type, behaviors covered, and runtime caveats. Reference a Jira key in the footer when known. Skip this step for `run` when no coverage changed.
