---
name: test
description: Create or run automated PHP, Jest, or e2e tests for a ucsc-gutenberg-blocks block, feature, fix, or Jira acceptance criterion. Use `verify` instead when proving behavior in the live running editor or frontend — `test` is for automated test suites only.
---

# Test

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

After confirmation, read exactly one operation reference:

- For `create`, read [`references/create.md`](references/create.md).
- For `run`, read [`references/run.md`](references/run.md).

Jira acceptance criteria may define assertions, but Jira is optional.
