# Validate mode menu

implements: ADR-086-VALIDATE-LAUNCHER, ADR-088-VALIDATE-MODES

When `validate` is invoked without a clear test type or operation, present this
menu (the hub subtree for `validate`, ADR-088) and wait for the user to choose a
type plus `create` or `run`.

```text
validate  [php|jest|e2e|all] [create|run] [target]  — create or run automated test suites
├─ php   [create|run] [target]  — create or run PHP tests
├─ jest  [create|run] [target]  — create or run Jest tests
├─ e2e   [create|run] [target]  — create or run browser-driven tests
└─ all   [block]                — run PHP, Jest, and E2E sequentially
```

The tree above is rendered from `skills/hub/references/skill-tree.json` by
`sync-inventory.sh`, so it always matches the hub. Each type takes `create` or
`run` and an optional block/feature/Jira target; `all` is run-only and executes
every suite sequentially (PHP → Jest → E2E) in one battery (ADR-101). For a
token-frugal single-call run of existing suites, the `run` operation uses
[`validate-php.sh`](validate-php.sh).
