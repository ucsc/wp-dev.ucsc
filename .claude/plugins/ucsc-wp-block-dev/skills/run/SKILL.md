---
name: run
description: This skill should be used when the user asks to "run the WordPress app", "start wp-dev.ucsc", "launch and drive the plugin", "open the editor", "interact with the block", or "demonstrate this change" in the ucsc-gutenberg-blocks Docker environment. Use verify for a specific acceptance criterion and validate for PHP, Jest, or e2e tests.
argument-hint: "[block] [change to demonstrate or URL]"
allowed-tools:
  - bash
  - docker
  - docker-compose
  - wp
  - curl
  - jq
---

# Run wp-dev.ucsc

## Implements

implements: ADR-002-RUN-WP-DEV, ADR-030-RUN-SEPARATION, ADR-073-RUN-CLAUDE-ONLY, ADR-091-RUN-TARGET, ADR-092-RUN-SHELL, ADR-093-RUN-BLOCK-TARGET, ADR-095-RUN-WP-EVAL, ADR-097-RUN-CONSOLE-CAPTURE

Follow this recorded project recipe instead of rediscovering the launch process. Work from the `wp-dev.ucsc` root.

## What `run` proves — the app can be launched and driven

Build and launch the app, then use the recorded driver/browser path to interact
with the requested surface and observe it working. `run` demonstrates the app;
`verify` applies a specific acceptance criterion without falling back to tests.

## Launcher

- [`launcher.md`](launcher.md) — slash-command launcher (ADR-086). `run` has no
  public submodes; resolve the requested app interaction from the arguments.

## Universal Command Intake

Resolve the target app or block surface, natural-language run request, and optional Jira key/URL from the full input and session context. Ask one concise question only when the target or requested operation cannot be inferred safely.

**Identify the plugin target before invoking the driver (ADR-091).** Two plugins
(`ucsc-blocks`, `ucsc-gutenberg-blocks`) share the one wp-dev.ucsc runtime, so do
not let `driver.sh` autodetect it. Resolve the target from explicit input, Jira
context, or the current directory; if it is ambiguous, ask one concise question
offering `ucsc-blocks` / `ucsc-gutenberg-blocks` / other. Then pass it explicitly
as `UCSC_PLUGIN=<slug>` and echo the chosen target before the first build/launch.

The *block* target (which block to build/drive) follows the shared session
contract in
[`../develop/references/block-target-session.md`](../develop/references/block-target-session.md)
(ADR-093): ARGUMENTS → persisted value (`develop/scripts/session-target.sh get`)
→ cwd inference → prompt; validate with `develop/scripts/block-target-check.sh`.
It scopes the `drive` step's block surface (ADR-091 amendment).

## Fast Path — `driver.sh`

For the routine lifecycle, prefer the bundled [`driver.sh`](driver.sh) over issuing the Docker/npm/wp commands one at a time. It runs a whole phase in a single call and prints a compact PASS/FAIL summary, sending verbose output to a logfile it names on exit — read that log only when a step reports FAIL. This keeps a full build-and-launch to ~14 lines of output instead of a dozen noisy command dumps.

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/run/driver.sh" all      # inspect → build → launch → smoke
bash "${CLAUDE_PLUGIN_ROOT}/skills/run/driver.sh" inspect  # non-destructive state check
bash "${CLAUDE_PLUGIN_ROOT}/skills/run/driver.sh" build    # Dockerized `npm run build`
bash "${CLAUDE_PLUGIN_ROOT}/skills/run/driver.sh" launch   # up -d, wait for DB, activate plugin
bash "${CLAUDE_PLUGIN_ROOT}/skills/run/driver.sh" smoke    # containers, wp-admin, plugin, blocks
bash "${CLAUDE_PLUGIN_ROOT}/skills/run/driver.sh" drive URL # headless Chrome: post-JS DOM + console errors (UCSC_SHOT=path for an optional screenshot)
bash "${CLAUDE_PLUGIN_ROOT}/skills/run/driver.sh" down     # stop the stack
```

If `${CLAUDE_PLUGIN_ROOT}` is unset, call the script by its in-plugin path (`skills/run/driver.sh`). The driver autodetects the `wp-dev.ucsc` root; override with `WP_DEV_ROOT=/path`.

**Shell safety — macOS zsh (ADR-092).** The developer shell is zsh (system bash
is 3.2), so always invoke scripts through `bash <script>` (as above) rather than
relying on the interactive shell. Never put inline `#` comments in commands
provided to the user, and avoid bash-4-only constructs (`${var,,}`, `declare -A`,
`&>>`, `|&`). Detect with `echo "$SHELL"` only when behavior depends on it.

**Plugin target.** `ucsc-blocks` and `ucsc-gutenberg-blocks` share the one
wp-dev.ucsc Docker runtime. Per ADR-091, pass the target identified during
intake explicitly — `UCSC_PLUGIN=<slug> bash .../run/driver.sh all` — rather than
relying on the driver's cwd autodetection (which can pick the wrong plugin when
the working directory is ambiguous). The driver builds it via a per-invocation
`-w` working-dir override against the shared `plugin_npm_start` service — no
second service is needed. If `UCSC_PLUGIN` is unset, the driver falls back to
detecting the slug from the current directory's `.../wp-content/plugins/<slug>`
segment. Each plugin has its own `node_modules`, so the first `build` for a
plugin runs `npm ci` in-container before compiling.

Drop to the manual steps below only to drive a single phase by hand or to diagnose a driver FAIL.

## Inspect Before Starting

Check the minimum state needed for the requested operation:

```bash
test -f .env
test -d public/wp-content/plugins/ucsc-gutenberg-blocks
docker compose ps
```

Do not repeat clean setup when the checkout, dependencies, WordPress installation, and containers already exist.

## Clean Setup

Use this only for missing prerequisites. Explain and obtain approval before privileged host changes, network clones, or destructive replacement.

1. Ensure Docker Desktop is running.
2. If `.env` is missing, copy `.env.example.txt` to `.env`.
3. Ensure `/etc/hosts` maps `127.0.0.1 wp-dev.ucsc`. This host edit requires user approval.
4. Start the base services:

```bash
docker compose up -d
```

5. Confirm `public/wp-config.php` exists.
6. If the theme or product plugins are missing, run `./setup.sh`.
7. Install dependencies and initialize WordPress:

```bash
docker compose -f docker-compose-install.yml run --rm theme_composer_install
docker compose -f docker-compose-install.yml run --rm theme_npm_install
docker compose -f docker-compose-install.yml run --rm plugin_npm_install
docker compose -f docker-compose-install.yml run --rm wordpress_install
```

Campus Directory LDAP requires the UCSC VPN. Local HTTPS uses the repository certificate and may require trusting the browser warning.

## Build Or Watch

Run Node commands in Docker so local Node is not required:

```bash
docker compose -f docker-compose.yml -f docker-compose-start.yml run --rm \
  -w /var/www/html/wp-content/plugins/ucsc-gutenberg-blocks \
  plugin_npm_start npm run build
```

For watch mode:

```bash
docker compose -f docker-compose.yml -f docker-compose-start.yml up -d
```

## Launch

```bash
docker compose up -d
docker compose exec wpcli wp plugin activate ucsc-gutenberg-blocks
docker compose ps
```

Use `https://wp-dev.ucsc/wp-admin/` as the canonical browser URL. The development credentials documented by the environment are `admin` / `password`.

## Drive The App

Do not stop at container health. Use the available browser tool or the driver's
headless Chrome path to open the requested editor/frontend surface, interact
with it, and observe the change working.

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/run/driver.sh" drive "https://wp-dev.ucsc/<page-slug>/"
```

The driver records post-JS DOM and console output. Use `UCSC_SHOT=<path>` only
when a screenshot materially helps. Use `verify` when the request provides a
specific change or acceptance criterion to confirm. Use `validate` for PHP,
Jest, or e2e suites.

## Runtime Introspection — `wp-eval.sh`

To inspect WordPress runtime state (registered blocks, options, transients) with
PHP, **do not** pipe an inline heredoc into `wp eval-file` — a command like
`printf '... $n[] = $name; ...' | docker compose exec -T wpcli wp eval-file -`
embeds PHP on the command line and trips zsh array/arith expansion permission
prompts. Instead run a bundled PHP file through a wrapper that pipes it over
STDIN (ADR-095):

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/run/list-blocks.sh"
```

[`list-blocks.sh`](list-blocks.sh) resolves the repo root via `source-base.sh`
and pipes [`helpers/list-blocks.php`](helpers/list-blocks.php) into
`wp eval-file -` over STDIN — listing every UCSC block (both `ucsc/*` and
`ucscblocks/*`) in the live registry across all activated plugins, with no PHP
embedded in a shell string. For other runtime queries, prefer the generic
substrate [`wp-eval.sh`](wp-eval.sh) — it locates the root and pipes any
`helpers/<name>.php` to `wp eval-file -`, forwarding `KEY=VAL` args as container
env (`getenv()`), so a new query is just a reviewed PHP file plus a thin `*.sh`
wrapper, never an inline eval.

### Diagnose a block that renders a fallback — `block-doctor.sh`

When a dynamic block shows a placeholder or "No X available" and the cause is
unclear, [`block-doctor.sh`](block-doctor.sh) (PHP in
[`helpers/block-doctor.php`](helpers/block-doctor.php)) explains it in one call:
it renders the block server-side as the anonymous user and flags whether the
output looks like a fallback, then audits the anonymous permission posture of
every REST route in a namespace. A dynamic block that fetches via its own
`rest_do_request()` endpoints falls back silently when those routes deny
anonymous access during a logged-out frontend render, and this surfaces exactly
which route is the culprit:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/run/block-doctor.sh" ucscblocks/classschedule
```

## Gotchas

- **Never `composer install` a plugin — the README install flow is the contract.**
  The wp-dev.ucsc README installs Composer deps for the *theme* only; plugins are
  brought up with `plugin_npm_install` (npm) and activated by `wordpress_install`.
  Any plugin that hard-`require`s a Composer-vendored library at load (as an early
  `ucsc-blocks` did with `plugin-update-checker`) will fatal on a clean checkout —
  that is a **plugin bug to fix**, not a reason to run `composer install`. Guard
  such requires with `file_exists()` so the dev environment activates without
  Composer (`ucsc-blocks.php` does this; production still ships the vendored lib).

- **Seed the events cache to render cards without the live API.** `ucsc/events`
  renders a placeholder until `ucsc_events_fetch_data()` has data; that data is a
  transient keyed `ucsc_events_<md5(apiUrl)>`. Seed it so the block renders real
  `.ucsc-event-item` cards offline by running the bundled seeder (the PHP lives in
  [`helpers/seed-events-cache.php`](helpers/seed-events-cache.php) and is piped to
  wp-cli over STDIN — no inline eval heredoc, ADR-095):

  ```bash
  bash "${CLAUDE_PLUGIN_ROOT}/skills/run/seed-events-cache.sh"
  ```

  [`seed-events-cache.sh`](seed-events-cache.sh) seeds the transient; clear it
  again with `wp transient delete --all`.

- **Seed a demo page that contains every registered `ucsc/*` block** for a single
  frontend URL to drive/verify against, via
  [`seed-demo-page.sh`](seed-demo-page.sh) (PHP in
  [`helpers/seed-demo-page.php`](helpers/seed-demo-page.php)). It upserts the page
  and prints its URL:

  ```bash
  bash "${CLAUDE_PLUGIN_ROOT}/skills/run/seed-demo-page.sh"
  ```

- **Chrome headless against the vanity host.** The page lives at the self-signed
  `https://wp-dev.ucsc/` vhost. `driver.sh drive` passes
  `--host-resolver-rules="MAP wp-dev.ucsc 127.0.0.1"`, `--ignore-certificate-errors`,
  and `--virtual-time-budget=6000` (so `DOMContentLoaded` JS runs); the headless
  path does not require an `/etc/hosts` edit.

## Recovery

- **`driver.sh` exits with "Docker daemon not running — start Docker Desktop"**
  — the driver pre-flights `docker info` and fails fast with this single line
  when the daemon is stopped (rather than flooding the log with repeated "Cannot
  connect to the Docker daemon" socket errors). It is not a stack fault. Start
  Docker Desktop and wait for the daemon before re-running:

  ```bash
  open -a Docker
  for i in $(seq 1 40); do docker info >/dev/null 2>&1 && break; sleep 3; done
  ```

  Then re-run the same `UCSC_PLUGIN=<slug> bash .../driver.sh all`. The daemon is
  typically ready within a few seconds of the app window appearing.
- If Compose reports orphan containers, add `--remove-orphans`.
- **"Error establishing a database connection" right after `up -d`** — the `db` container needs a few seconds before wp-cli can connect. Wait and retry; `driver.sh launch` polls `wp option get siteurl` for up to 60s before activating the plugin.
- **`wp db <cmd>` fails with `caching_sha2_password could not be loaded`** — that is the bundled mysql CLI client, not a real database fault. Use PHP/mysqli-path commands instead (`wp option get`, `wp eval`, `wp plugin …`). The driver's readiness probe relies on this.
- If API output is stale, run `docker compose exec wpcli wp transient delete --all`.
- If Campus Directory fails locally, confirm VPN access and `DOCKER_DEV=docker_dev`.
- Do not delete containers, volumes, repositories, or user data without explicit approval.
