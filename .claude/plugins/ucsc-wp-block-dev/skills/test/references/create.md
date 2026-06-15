# Create Tests

Read this reference when the selected test operation is `create`.

## Purpose

Create focused PHP, Jest, or end-to-end coverage for a target Gutenberg block,
feature, fix, or acceptance criterion.

## Workflow

1. Confirm the test type is `php`, `jest`, or `e2e`.
2. Read the nearest existing test pattern before adding coverage.
3. Add the smallest test that proves the behavior or regression.
4. Run the new or changed test.
5. Broaden validation only when risk or shared behavior requires it.

## Type Guidance

| Type | Use for |
| --- | --- |
| `php` | Render callbacks, sanitization, REST routes, transient behavior |
| `jest` | Block registration, attributes, editor controls, client behavior |
| `e2e` | WordPress editor insertion, frontend rendering, Docker/browser integration |

Build checks may support any type but are not a fourth test type.

## Check-In Text

When coverage is added or meaningfully changed, finish with ready-to-paste
check-in text:

1. A Jira title: short imperative summary of the test work.
2. A Conventional Commit description with a `test(scope): subject` header and a
   body naming the test type, behaviors covered, and runtime caveats.

Use `fix` or `feat` only when block behavior also changed. Reference a Jira key
in the footer when known.

