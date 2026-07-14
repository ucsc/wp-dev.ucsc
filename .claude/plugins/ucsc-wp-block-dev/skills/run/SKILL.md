---
name: run
description: This skill should be used when the user asks to "run the WordPress app", "start wp-dev.ucsc", "launch and drive the plugin", "open the editor", "interact with the block", or "demonstrate this change" in the UCSC block plugins (ucsc-blocks, ucsc-gutenberg-blocks) Docker environment. Use verify for a specific acceptance criterion and validate for PHP, Jest, or e2e tests.
version: 0.1.0
argument-hint: "[block] [change to demonstrate or URL]"
allowed-tools:
  - Read
  - Grep
  - Bash(bash:*)
  - Bash(docker:*)
  - Bash(curl:*)
  - Bash(jq:*)
---

# Run wp-dev.ucsc

<!-- doc-slide: Launches and drives the wp-dev.ucsc Docker stack through one token-frugal driver to see a change working. -->

## Implements

implements: ADR-002-RUN-WP-DEV, ADR-030-RUN-SEPARATION, ADR-073-RUN-CLAUDE-ONLY, ADR-091-RUN-TARGET, ADR-092-RUN-SHELL, ADR-093-RUN-BLOCK-TARGET, ADR-095-RUN-WP-EVAL, ADR-097-RUN-CONSOLE-CAPTURE

Follow this recorded project recipe instead of rediscovering the launch process. Work from the `wp-dev.ucsc` root.

## What `run` proves — the app can be launched and driven

Build and launch the app, then use the recorded driver/browser path to interact
with the requested surface and observe it working. `run` demonstrates the app;
`verify` applies a specific acceptance criterion without falling back to tests.

## Environment — multi-environment support

This skill supports multiple development environments: the original `wp-dev.ucsc`
home-rolled Docker Compose stack, `wp-env`, Local (LocalWP), WP Engine, and
"Bring Your Own" (BYO) environments. The run skill includes an environment
router that auto-detects the runtime using
[`lib/detect-environment.sh`](lib/detect-environment.sh) and dispatches to an
environment-specific driver:

- [`drivers/wp-dev-ucsc.sh`](drivers/wp-dev-ucsc.sh) — full driver for the
  home-rolled Docker stack
- [`drivers/wp-env.sh`](drivers/wp-env.sh) — full driver for `@wordpress/env`
  (Phase 4a). Requires `.wp-env.json` at the repo root; copy
  [`wp-env-example.json`](wp-env-example.json) to scaffold one. LDAP-dependent
  blocks (Campus Directory) are not supported under wp-env — see
  [`references/environments.md`](references/environments.md).
- [`drivers/generic-byo.sh`](drivers/generic-byo.sh) — BYO: validates a
  reachable site and drives it
- [`drivers/local.sh`](drivers/local.sh) — full driver for LocalWP (Phase 4b)
  via the third-party `lwp` CLI (cartpauj/localwp-cli); Local has no
  first-party scriptable CLI. Requires `UCSC_LOCAL_SITE=<name-or-id>` (see
  `lwp list`) and the Local GUI app running. LDAP-dependent blocks (Campus
  Directory) are not supported — see
  [`references/environments.md`](references/environments.md).
- [`lib/drive.sh`](lib/drive.sh) — shared headless-Chrome `drive` logic
  (post-JS DOM + console capture); every driver above sources this instead of
  duplicating it

When a full driver is not present the BYO driver provides clear guidance to
bring up your site and run the requested commands.

See [`references/environments.md`](references/environments.md) for detection
rules, supported probes, troubleshooting, and how to add a new driver. The
router and driver behavior are covered by
[`lib/test-detect-environment.sh`](lib/test-detect-environment.sh), the
[`test-regression-wp-dev-ucsc.sh`](test-regression-wp-dev-ucsc.sh),
[`test-regression-wp-env.sh`](test-regression-wp-env.sh), and
[`test-regression-local.sh`](test-regression-local.sh) regression suites
(maintainer-run; not part of a normal launch).

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

Use `https://wp-dev.ucsc/wp-admin/` as the canonical local-only browser URL.
Obtain the throwaway local administrator credentials from the environment's
private setup rather than recording them in this public plugin.

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

## Runtime introspection & diagnostics

Used only when inspecting live state or diagnosing a block — not every run. All
runtime queries run a reviewed `helpers/<name>.php` piped to `wp eval-file -`
over STDIN, never an inline heredoc (ADR-095). Bundled wrappers:

- [`list-blocks.sh`](list-blocks.sh) (PHP [`helpers/list-blocks.php`](helpers/list-blocks.php))
  — list every live UCSC block (`ucsc/*` and `ucscblocks/*`).
- [`wp-eval.sh`](wp-eval.sh) — generic substrate: pipe any `helpers/<name>.php`,
  forwarding `KEY=VAL` args as container env, so a new query is a reviewed PHP
  file plus a thin wrapper.
- [`block-doctor.sh`](block-doctor.sh) (PHP [`helpers/block-doctor.php`](helpers/block-doctor.php))
  — diagnose a fallback render by rendering the block logged-out and auditing
  anonymous REST access across a namespace.

Full usage and rationale: [`references/diagnostics.md`](references/diagnostics.md).

## Gotchas

Situational traps hit only in specific scenarios — not every run:

- **Never `composer install` a plugin** — plugins come up via `plugin_npm_install`
  and `wordpress_install`; guard any Composer-vendored `require` with
  `file_exists()` (a hard-require fatal is a plugin bug, not a reason to install).
- **Seed the `ucsc/events` transient cache** to render cards offline with
  [`seed-events-cache.sh`](seed-events-cache.sh) (PHP
  [`helpers/seed-events-cache.php`](helpers/seed-events-cache.php)).
- **Seed an all-blocks demo page** for one drive/verify URL with
  [`seed-demo-page.sh`](seed-demo-page.sh) (PHP
  [`helpers/seed-demo-page.php`](helpers/seed-demo-page.php)).
- **Chrome headless** against the self-signed vanity host — `driver.sh drive`
  supplies the host-resolver/cert flags, so no `/etc/hosts` edit is needed.

Details: [`references/gotchas.md`](references/gotchas.md).

## Recovery

When the stack misbehaves — Docker daemon down, orphan containers, DB-connection
races right after `up -d`, the `caching_sha2_password` mysql-client red herring,
stale API caches, or Campus Directory VPN — see
[`references/recovery.md`](references/recovery.md). Never delete containers,
volumes, repositories, or user data without explicit approval.

## Examples

- [`examples/driver-invocations.md`](examples/driver-invocations.md) — copy-ready `driver.sh` commands for every phase and common scenarios
- [`examples/env-invocations.md`](examples/env-invocations.md) — environment detection/router invocations across wp-dev.ucsc, wp-env, LocalWP, and BYO
