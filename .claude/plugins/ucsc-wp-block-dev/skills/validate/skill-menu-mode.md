# Validate mode menu

implements: ADR-086-VALIDATE-LAUNCHER, ADR-088-VALIDATE-MODES

When `validate` is invoked without a clear test type or operation, ask one
question that selects a type plus `create` or `run`.

| Type | Arguments | Use when |
|---|---|---|
| `validate php` | `[create\|run] [block\|feature\|Jira]` | Create or run PHP test coverage. |
| `validate jest` | `[create\|run] [block\|feature\|Jira]` | Create or run JavaScript editor/unit tests. |
| `validate e2e` | `[create\|run] [block\|feature\|Jira]` | Create or run browser-driven end-to-end tests. |

For a token-frugal single-call run of existing suites, the `run` operation
uses [`validate_driver.sh`](validate_driver.sh).
