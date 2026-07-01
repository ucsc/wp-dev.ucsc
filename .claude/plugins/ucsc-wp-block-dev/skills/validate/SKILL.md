---
name: validate
description: This skill should be used when the user asks to "create a PHP test", "run the PHP tests", "create a Jest test", "run the Jest tests", "create an e2e test", "run the e2e tests", or validate a ucsc-gutenberg-blocks feature, fix, or Jira acceptance criterion with an automated test suite. Use verify instead for live editor or frontend behavior.
version: 0.1.0
argument-hint: "[php|jest|e2e|all] [create|run] [block|feature|Jira]"
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

<!-- doc-slide: Creates or runs the PHP, Jest, and e2e suites — `all` runs them sequentially in a single agent. -->

## Implements

implements: ADR-019-VALIDATE-CHECKIN-TEXT, ADR-030-VALIDATE-SEPARATION, ADR-042-VALIDATE-REFERENCES, ADR-050-VALIDATE-NO-LOCAL-DEPS, ADR-066-VALIDATE-DRIVER, ADR-087-VALIDATE-RENAME, ADR-088-VALIDATE-MODES, ADR-093-VALIDATE-BLOCK-TARGET, ADR-101-VALIDATE-ALL-SEQUENTIAL, ADR-102-VALIDATE-OUTPUT-ISOLATION, ADR-103-VALIDATE-VERIFY-STACK-DEPENDENCY

## Launcher

- [`launcher.md`](launcher.md) — slash-command launcher (ADR-086): if a mode
  (`create`/`run`) is given, run it; otherwise load
  [`skill-menu-mode.md`](skill-menu-mode.md) and show the mode menu before acting.

## Universal Command Intake

Resolve the test target, natural-language test goal, and optional Jira key/URL from the full input.

**Block target (ADR-093).** Resolve the block target with the shared contract in
[`../develop/references/block-target-session.md`](../develop/references/block-target-session.md):
ARGUMENTS → persisted session value (`develop/scripts/session-target.sh" get`) →
cwd inference → prompt. Validate an inferred directory with
`develop/scripts/block-target-check.sh` before adopting it, and persist a newly
resolved target with `session-target.sh" set`.

## Test Driver

Prefer a single-call driver over ad-hoc Docker commands. The validate skill is
now multi-environment aware: when invoked it uses the environment detection
router (via `skills/run/lib/detect-environment.sh`) and routes to the
appropriate validation flow for the detected environment (dockerized
`wp-dev.ucsc`, `wp-env`, LocalWP, WP Engine, or BYO). When a repo-local
`bin/validate*.sh` exists prefer it; otherwise the plugin-level validators
(`skills/validate/validate-*.sh`) handle routing and provide BYO guidance.

**Repo-local battery (`ucsc-gutenberg-blocks`).** When the target repo ships
`bin/validate*.sh`, use them — they realize the full per-type + battery design
ADR-066 envisioned, with distinct per-suite logs. All run in Docker when the
environment supports it; non-docker environments will be given BYO instructions.

Logs land in `$UCSC_LOG_DIR` (default `/tmp`). The e2e suite requires the site
be up; if the environment is not running the validator will prompt to bring it
up (or use the `run` skill's driver to launch it when supported). PHP and Jest
can run offline when the environment provides the necessary runtimes.

**Output isolation (ADR-102).** Test logs and artifacts must be session- and
block-target-specific — never static global paths — to avoid concurrent runs
stomping each other, stale-log false results, or cross-target contamination.

**Plugin driver (`ucsc-blocks`).** For the `ucsc-blocks` plugin, which ships no
`bin/` runners, use the plugin-side driver; it detects and routes automatically:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/validate/validate-php.sh"
```

See [`references/environments.md`](references/environments.md) for detection
rules and per-environment guidance, and [`references/run.md`](references/run.md)
for per-type Docker commands and stack gotchas.

## Modes

- `validate php [create|run]` — PHP test coverage.
- `validate jest [create|run]` — JavaScript editor/unit test coverage.
- `validate e2e [create|run]` — browser-driven end-to-end coverage.
- `validate all` — run every suite in one battery (run-only; does not create).

**`all` mode (ADR-101).** Run the suites **sequentially** — PHP → Jest → E2E —
confirming each result before the next; never dispatch them as parallel commands
and never spawn a subagent per suite (single-agent, ADR-003). When the target
repo ships the battery, that is the single call: `bash bin/validate.sh` (or a
named subset like `bash bin/validate.sh php jest`); otherwise run the per-suite
commands from [`references/run.md`](references/run.md) one at a time.

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

## Examples

Copy-adapt working test stubs for new blocks:

- [`examples/jest-test.js`](examples/jest-test.js) — Jest test template with `@wordpress/*` virtual mocks and `@testing-library/react`
- [`examples/php-test.php`](examples/php-test.php) — Standalone PHP test template with WP stubs; runs via `php:8.1-cli`, no PHPUnit

Jira acceptance criteria may define assertions, but Jira is optional.
