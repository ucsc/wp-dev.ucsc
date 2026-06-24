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

## Run Every Mode in Docker — No Host Runtimes (ADR-050)

All three test modes run inside Docker; **never require a local `php`, `python`,
or `node` on the host** (ADR-050, extended 2026-06-24 to cover Node and the
jest/e2e modes). The canonical per-mode commands:

| Mode | Command | Container |
|---|---|---|
| `php` | `docker run --rm -v "$PWD:/plugin" -w /plugin php:8.1-cli php tests/php/<X>Test.php` | throwaway `php:8.1-cli` (tests stub WP, so no real runtime needed) |
| `jest` | `docker compose -f docker-compose.yml -f docker-compose-start.yml run --rm -w <plugin-path> plugin_npm_start npm test -- <file>` | the stack's `plugin_npm_start` node service |
| `e2e` | `bash tests/e2e/run-e2e.sh` | a node+chromium image built by the harness (see below) |

Pass `CI=true` to the jest service for non-watch output. None of these assume a
host toolchain — only the Docker daemon.

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
> described in ADR-066 are **not yet implemented** in `validate_driver.sh`. Run
> Jest and e2e via their Docker commands above (the `plugin_npm_start` service
> and `tests/e2e/run-e2e.sh`) — never host `npm` — until the driver is completed.

## Running PHP Tests (Manual/Fallback)

If you need to run specific PHP tests manually:

```bash
# Run a single test file
docker run --rm -v "$PWD:/plugin" -w /plugin php:8.1-cli php tests/php/ClassNameTest.php
```

Test files exit non-zero on failure.

## Running e2e Tests (Containerized, no host browser)

`@wordpress/scripts` ships only `puppeteer-core` (no bundled Chromium), so the
e2e harness runs in a Node+Chromium container and drives the **live**
`https://wp-dev.ucsc` frontend. Built and run by a single script in the product
repo (first verified 2026-06-24 for `ucsc-gutenberg-blocks`):

```bash
bash tests/e2e/run-e2e.sh
# target a specific page:
CLASS_SCHEDULE_E2E_URL=https://wp-dev.ucsc/some-page/ bash tests/e2e/run-e2e.sh
```

Key patterns the harness encodes (reuse these for any block's e2e):

- **Reach the vanity host from inside a container** with
  `--add-host=wp-dev.ucsc:host-gateway` — the container hits the host's published
  443 (the `server` service). No `--host-resolver-rules`, no `/etc/hosts` edit.
  Verify reachability cheaply: `docker run --rm --add-host=wp-dev.ucsc:host-gateway curlimages/curl -ks -o /dev/null -w '%{http_code}\n' https://wp-dev.ucsc/<page>/` → `200`.
- **Self-signed cert:** launch Chromium with `--ignore-certificate-errors`
  (`jest-puppeteer.config.js` `launch.args`), plus `--no-sandbox` and
  `--disable-dev-shm-usage` in-container.
- **Never use the host's `node_modules`** (it is darwin): the runner installs the
  container's own linux deps into a **named volume** (`npm ci` on first run,
  skipped when cached), mounted over `/app/node_modules`.
- **Container-aware config:** `UCSC_E2E_IN_CONTAINER=1` switches
  `jest-puppeteer.config.js` from the host fallback (dev Chrome + a
  `MAP wp-dev.ucsc 127.0.0.1` resolver rule, like `run/driver.sh drive`) to the
  in-container path (`/usr/bin/chromium`, `--add-host` DNS).
- **Specs** live at `tests/e2e/*.spec.js` and run via
  `npm run test:e2e` (= `wp-scripts test-e2e --rootDir=tests/e2e`) *inside* that
  container.

**Fixture caveat:** the block server-renders its real markup only when its
configured criterion returns data, and `run/seed_demo_page.sh` seeds only
`ucsc/*` blocks — it skips `ucscblocks/*` blocks like `classschedule`. Drive a
dedicated published page whose criterion currently returns rows (e.g.
`class-schedule-demo`), not the generic demo page.

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

