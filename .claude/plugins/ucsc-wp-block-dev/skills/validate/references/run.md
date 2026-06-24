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

## Running Tests via Driver (Preferred)

Always prefer running tests using the driver in a single token-frugal call. The
script is `validate_driver.sh` (not `driver.sh`) and currently runs the
**PHP/PHPUnit** suite only — it takes no subcommands:

```bash
# Run the ucsc-blocks PHPUnit suite inside the wp-dev.ucsc container
bash .claude/plugins/ucsc-wp-block-dev/skills/validate/validate_driver.sh
```

Environment overrides: `WP_CONTAINER` (target container), `PLUGIN_SLUG` (plugin
folder, default `ucsc-blocks`), `PHPUNIT_PHAR_URL`.

> The `php|jest|e2e|all` subcommands, log redirection, and pass/fail summary
> described in ADR-066 are **not yet implemented** in `validate_driver.sh`. For
> Jest, run the plugin's `npm` scripts directly until the driver is completed.

## Running PHP Tests (Manual/Fallback)

If you need to run specific PHP tests manually:

```bash
# Run a single test file
docker run --rm -v "$PWD:/plugin" -w /plugin php:8.1-cli php tests/php/ClassNameTest.php
```

Test files exit non-zero on failure.

## Reporting

Report pass/fail, the exact command, and the smallest actionable detail. For
failures, identify whether the result points to test setup, stale build/runtime
state, or application behavior.

## Gotchas

Hard-won facts about running the `ucsc-blocks` PHP suite in the wp-dev.ucsc
Docker stack (verified 2026-06-23):

- **Container name is `ucsc-wordpress-wp`** (image `wp-devucsc-wp`), not
  `wp-dev.ucsc`. A `docker ps --filter name=wp-dev.ucsc` matches nothing.
  `validate_driver.sh` auto-detects the container; override with `WP_CONTAINER`.
- **The plugin slug is `ucsc-blocks`.** A separate legacy plugin,
  `ucsc-gutenberg-blocks`, coexists in the same WordPress install — do not
  conflate the skill's nominal name with the plugin folder. The driver defaults
  to `ucsc-blocks`; override with `PLUGIN_SLUG`.
- **No PHPUnit ships in the container** — there is no Composer, `vendor/`, or
  global `phpunit` in `ucsc-wordpress-wp`, only PHP 8.1. The plugin's
  `tests/bootstrap.php` runs in standalone mode (stubs WordPress and loads the
  block PHP directly), so the suite needs only PHP + a PHPUnit 10 phar — no
  WordPress test library. `validate_driver.sh` fetches the phar to `/tmp` on
  demand; alternatively run `composer install` inside the plugin.

