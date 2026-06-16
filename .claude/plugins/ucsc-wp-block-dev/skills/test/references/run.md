# Run Tests

Read this reference when the selected test operation is `run`.

## Purpose

Run existing PHP, Jest, or end-to-end tests for a target Gutenberg block,
feature, fix, or acceptance criterion.

## Workflow

1. Confirm the test type is `php`, `jest`, or `e2e`.
2. Execute the narrowest existing test that can answer the question.
3. Capture the command, result, and relevant failure excerpt.
4. Broaden to related tests only when requested or when risk requires it.
5. Do not emit check-in text when no coverage changed.

## Type Guidance

| Type | Use for |
| --- | --- |
| `php` | Render callbacks, sanitization, REST routes, transient behavior |
| `jest` | Block registration, attributes, editor controls, client behavior |
| `e2e` | WordPress editor insertion, frontend rendering, Docker/browser integration |

Build checks may support any type but are not a fourth test type.

## Running PHP Tests

Always use Docker — never assume a local `php` binary (ADR-050):

```bash
# Run a single test file
docker run --rm -v "$PWD:/plugin" -w /plugin php:8.1-cli php tests/php/ClassName Test.php

# Run all existing PHP tests
docker run --rm -v "$PWD:/plugin" -w /plugin php:8.1-cli \
  sh -c 'for f in tests/php/*.php; do php "$f"; done'
```

Test files exit non-zero on failure — capture the pass/fail line at the end of output.

## Reporting

Report pass/fail, the exact command, and the smallest actionable detail. For
failures, identify whether the result points to test setup, stale build/runtime
state, or application behavior.

