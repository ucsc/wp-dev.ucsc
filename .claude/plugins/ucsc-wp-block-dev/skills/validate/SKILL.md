---
name: validate
description: Create or run automated PHP, Jest, or e2e tests for a ucsc-gutenberg-blocks block, feature, fix, or Jira acceptance criterion. Modes are `create` and `run`. Use `verify` instead when proving behavior in the live running editor or frontend — `validate` is for automated test suites only.
argument-hint: "[create|run] [block | feature | Jira]"
allowed-tools:
  - bash
  - python
  - docker
  - docker-compose
  - npm
  - yarn
  - wp
---

# Validate

## Implements

implements: ADR-019-VALIDATE-CHECKIN-TEXT, ADR-030-VALIDATE-SEPARATION, ADR-042-VALIDATE-REFERENCES, ADR-050-VALIDATE-NO-LOCAL-DEPS, ADR-066-VALIDATE-DRIVER, ADR-087-VALIDATE-RENAME, ADR-088-VALIDATE-MODES, ADR-093-VALIDATE-BLOCK-TARGET

## Launcher

- [`launcher.md`](launcher.md) — slash-command launcher (ADR-086): if a mode
  (`create`/`run`) is given, run it; otherwise load
  [`skill-menu-mode.md`](skill-menu-mode.md) and show the mode menu before acting.

## Universal Command Intake

Resolve the test target, natural-language test goal, and optional Jira key/URL from the full input.

**Block target (ADR-093).** Resolve the block target with the shared contract in
[`../develop/references/block-target-session.md`](../develop/references/block-target-session.md):
ARGUMENTS → persisted session value (`develop/scripts/session_target.sh get`) →
cwd inference → prompt. Validate an inferred directory with
`develop/scripts/block_target_check.sh` before adopting it, and persist a newly
resolved target with `session_target.sh set`.

## Test Driver

For a single-call run of the PHP suite, use the validate driver. It currently
runs the **PHP/PHPUnit** suite only and takes no subcommands:

```bash
bash .claude/plugins/ucsc-wp-block-dev/skills/validate/validate_driver.sh
```

Environment overrides: `WP_CONTAINER`, `PLUGIN_SLUG` (default `ucsc-blocks`),
`PHPUNIT_PHAR_URL`. For Jest, run the plugin's `npm` scripts directly.

> Per ADR-066 (amended 2026-06-23), the driver is intentionally PHP-only. The
> original `php|jest|e2e|all` subcommands, log redirection, and summary parsing
> were never implemented; see ADR-066 for the scoped-down decision.

## Modes

- `validate create` — create automated PHP, Jest, or e2e tests for a target,
  feature, fix, or Jira acceptance criterion.
- `validate run` — run existing automated PHP, Jest, or e2e tests.

## Confirm Type And Mode

Before reading files, creating coverage, or running commands, explicitly confirm both:

1. **Type** — `php`, `jest`, or `e2e`.
2. **Mode** — `create` tests or `run` existing tests.

Always ask one concise question only: confirm the resolved values and request any missing value in the same question. Example: "Should I create or run Jest tests for Class Schedule?" Wait for the answer before using tools, even when one value appears inferable from context.

Use these test types:

| Type | Use for |
|---|---|
| `php` | Render callbacks, sanitization, REST routes, transient behavior |
| `jest` | Block registration, attributes, editor controls, client behavior |
| `e2e` | WordPress editor insertion, frontend rendering, Docker/browser integration |

After confirmation, read exactly one mode reference:

- For `create`, read [`references/create.md`](references/create.md).
- For `run`, read [`references/run.md`](references/run.md).

Jira acceptance criteria may define assertions, but Jira is optional.
