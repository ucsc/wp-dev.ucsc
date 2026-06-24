# Validate mode menu

implements: ADR-086-VALIDATE-LAUNCHER, ADR-088-VALIDATE-MODES

When `validate` is invoked without a mode and the intended mode is not clear from
the request, present this menu and wait for the user to choose. Confirm the test
type (`php`, `jest`, or `e2e`) in the same question.

| Mode | Use when |
|---|---|
| `validate create` | Create automated PHP, Jest, or e2e tests for a target, feature, fix, or Jira acceptance criterion. |
| `validate run` | Run existing automated PHP, Jest, or e2e tests. |

For a token-frugal single-call run of existing suites, the `validate run` path
uses [`validate_driver.sh`](validate_driver.sh).
