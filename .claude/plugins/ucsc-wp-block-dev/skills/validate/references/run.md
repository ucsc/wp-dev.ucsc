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

Always prefer running tests via a single token-frugal driver call. Pick the
driver family by the resolved target repo.

### Repo-local battery — `bin/validate*.sh` (`ucsc-gutenberg-blocks`)

When the target repo ships `bin/validate*.sh`, prefer them. They implement the
per-type + battery design from ADR-066 with **distinct per-suite logs**, all in
Docker (no host PHP/Node):

| Command | Runs | Log (`$UCSC_LOG_DIR`, default `/tmp`) |
|---|---|---|
| `bash bin/validate-php.sh` | standalone `tests/php/*.php` **+** `tests/phpunit` (PHPUnit) in `php:8.1-cli` | `ucsc-validate-php.log` |
| `bash bin/validate-jest.sh` | `npm test` (wp-scripts) in a Node container with a named `node_modules` volume | `ucsc-validate-jest.log` |
| `bash bin/validate-e2e.sh` | wraps `tests/e2e/run-e2e.sh` | `ucsc-validate-e2e.log` |
| `bash bin/validate.sh [php] [jest] [e2e]` | battery — runs all, or only the named suites; prints a per-suite PASS/FAIL summary with each log path; exits non-zero if any fail | per-suite logs above |

The `php` driver runs **both** PHP styles: the dependency-free standalone files
(each its own process, `php tests/php/<X>.php`) and the PHPUnit suite under
`tests/phpunit/` via the bundled `phpunit.phar`. The e2e suite needs the stack
up (`run` first); php and jest run fully offline. Each script supports `--help`.

### Plugin driver — `validate-php.sh` (`ucsc-blocks`)

For the `ucsc-blocks` plugin, which ships no `bin/` runners, use the plugin-side
driver. It runs the **PHP/PHPUnit** suite only and takes no subcommands:

```bash
# Run the ucsc-blocks PHPUnit suite inside the wp-dev.ucsc container
bash "${CLAUDE_PLUGIN_ROOT}/skills/validate/validate-php.sh"
```

Environment overrides: `WP_CONTAINER` (target container), `PLUGIN_SLUG` (plugin
folder, default `ucsc-blocks`), `PHPUNIT_PHAR_URL`.

> The plugin `validate-php.sh` is intentionally PHP-only (ADR-066, amended
> 2026-06-23). The `php|jest|e2e|all` battery and per-suite logging that ADR-066
> originally described are realized at the product-repo level by the
> `bin/validate*.sh` runners above, not by this plugin script. For `ucsc-blocks`,
> run Jest and e2e via their Docker commands above (the `plugin_npm_start`
> service and `tests/e2e/run-e2e.sh`) — never host `npm`.

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
bash tests/e2e/run-e2e.sh"
# target a specific page:
CLASS_SCHEDULE_E2E_URL=https://wp-dev.ucsc/some-page/ bash tests/e2e/run-e2e.sh"
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
  `MAP wp-dev.ucsc 127.0.0.1` resolver rule, like `run/driver.sh" drive`) to the
  in-container path (`/usr/bin/chromium`, `--add-host` DNS).
- **Specs** live at `tests/e2e/*.spec.js` and run via
  `npm run test:e2e` (= `wp-scripts test-e2e --rootDir=tests/e2e`) *inside* that
  container.

**Fixture caveat:** 
- **For `ucsc-blocks` (`ucsc/*`):** Use the unified `https://wp-dev.ucsc/ucsc-block-demo/` page seeded by `run/seed-demo-page.sh`. It contains all `ucsc/*` blocks and is the canonical E2E target for the newer plugin.
- **For `ucsc-gutenberg-blocks` (`ucscblocks/*`):** The seeder skips these older blocks. You must drive a dedicated published page whose criterion returns rows (e.g., `https://wp-dev.ucsc/class-schedule-demo/`), not the generic demo page.

## Reporting

Report pass/fail, the exact command, and the smallest actionable detail. For
failures, identify whether the result points to test setup, stale build/runtime
state, or application behavior.

## Gotchas

Hard-won facts about running the `ucsc-blocks` PHP suite in the wp-dev.ucsc
Docker stack (verified 2026-06-23):

- **Container name is `ucsc-wordpress-wp`** (image `wp-devucsc-wp`), not
  `wp-dev.ucsc`. A `docker ps --filter name=wp-dev.ucsc` matches nothing.
  `validate-php.sh` auto-detects the container; override with `WP_CONTAINER`.
- **The plugin slug is `ucsc-blocks`.** A separate legacy plugin,
  `ucsc-gutenberg-blocks`, coexists in the same WordPress install — do not
  conflate the skill's nominal name with the plugin folder. The driver defaults
  to `ucsc-blocks`; override with `PLUGIN_SLUG`.
- **No PHPUnit ships in the container** — there is no Composer, `vendor/`, or
  global `phpunit` in `ucsc-wordpress-wp`, only PHP 8.1. The plugin's
  `tests/bootstrap.php` runs in standalone mode (stubs WordPress and loads the
  block PHP directly), so the suite needs only PHP + a PHPUnit 10 phar — no
  WordPress test library. `validate-php.sh` fetches the phar to `/tmp` on
  demand; alternatively run `composer install` inside the plugin.
- **E2E Puppeteer 23/24 Compatibility**: Newer versions of `@wordpress/scripts`
  (e.g., version 30+) use newer `puppeteer-core` versions where:
  - `puppeteer-core/install` is completely removed, causing E2E startup errors in the
    harness. Bypass by touching dummy extensionless `install` and `install.js` files
    in `node_modules/puppeteer-core/` within the E2E container prior to testing.
  - The Puppeteer `Page` object does not inherit from `EventEmitter` and lacks
    `removeListener` and `addListener`. This causes `jest-environment-puppeteer` to
    crash during setup/teardown. Patch the environment script in-container via `sed`
    to replace `.removeListener(` with `.off(` and `.addListener(` with `.on(`.
- **Seed Page Block Attributes**: For E2E tests targeting dynamic/data-backed blocks
  (like `ucsc/events`), the seeded block block-comment on the demo page must include
  configured attributes (e.g. `apiUrl`). If left empty, the block will fall back to
  rendering its empty placeholder, causing E2E tests waiting for item selectors to
  time out.

