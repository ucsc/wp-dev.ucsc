---
name: run
description: Build, launch, and drive the ucsc-gutenberg-blocks plugin in the wp-dev.ucsc Docker environment. Use when asked to run, start, build, watch, open, or interact with the WordPress app; use verify for acceptance checking and validate for automated tests.
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

implements: ADR-002-RUN-WP-DEV, ADR-030-RUN-SEPARATION, ADR-073-RUN-CLAUDE-ONLY, ADR-091-RUN-TARGET, ADR-092-RUN-SHELL, ADR-093-RUN-BLOCK-TARGET, ADR-095-RUN-WP-EVAL

Follow this recorded project recipe instead of rediscovering the launch process. Work from the `wp-dev.ucsc` root.

## Launcher

- [`launcher.md`](launcher.md) — slash-command launcher (ADR-086): if a run mode
  is given, run it; otherwise resolve the plugin target and proceed with the
  default build-and-launch recipe.

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
(ADR-093): ARGUMENTS → persisted value (`develop/scripts/session_target.sh get`)
→ cwd inference → prompt; validate with `develop/scripts/block_target_check.sh`.
It scopes the `drive` step's block surface (ADR-091 amendment).

## Fast Path — `driver.sh`

For the routine lifecycle, prefer the bundled [`driver.sh`](driver.sh) over issuing the Docker/npm/wp commands one at a time. It runs a whole phase in a single call and prints a compact PASS/FAIL summary, sending verbose output to a logfile it names on exit — read that log only when a step reports FAIL. This keeps a full build-and-launch to ~14 lines of output instead of a dozen noisy command dumps.

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/run/driver.sh" all      # inspect → build → launch → smoke
bash "${CLAUDE_PLUGIN_ROOT}/skills/run/driver.sh" inspect  # non-destructive state check
bash "${CLAUDE_PLUGIN_ROOT}/skills/run/driver.sh" build    # Dockerized `npm run build`
bash "${CLAUDE_PLUGIN_ROOT}/skills/run/driver.sh" launch   # up -d, wait for DB, activate plugin
bash "${CLAUDE_PLUGIN_ROOT}/skills/run/driver.sh" smoke    # containers, wp-admin, plugin, blocks
bash "${CLAUDE_PLUGIN_ROOT}/skills/run/driver.sh" drive URL # headless Chrome: screenshot + post-JS DOM
bash "${CLAUDE_PLUGIN_ROOT}/skills/run/driver.sh" down     # stop the stack
```

If `${CLAUDE_PLUGIN_ROOT}` is unset, call the script by its in-plugin path (`skills/run/driver.sh`). The driver autodetects the `wp-dev.ucsc` root; override with `WP_DEV_ROOT=/path`.

**Shell safety — macOS zsh (ADR-092).** The developer shell is zsh (system bash
is 3.2), so always invoke scripts through `bash <script>` (as above) rather than
relying on the interactive shell, never put inline `#` comments in commands you
hand the user, and avoid bash-4-only constructs (`${var,,}`, `declare -A`, `&>>`,
`|&`). Detect with `echo "$SHELL"` only when behavior depends on it.

**Plugin target.** `ucsc-blocks` and `ucsc-gutenberg-blocks` share the one
wp-dev.ucsc Docker runtime. Per ADR-091, pass the target you identified during
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

Do not stop at container health when the user asks to see the application
working. **A frontend block's `view.js` only proves out when a real browser
executes it** — `curl` returns the server HTML but never runs the script, so a
broken wrapper-class selector (the kind of bug that makes `view.js` inert) looks
fine in `curl` and is only caught by driving the page.

### Agent path — `driver.sh drive` (headless Chrome)

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/run/driver.sh" drive "https://wp-dev.ucsc/<page-slug>/"
```

This renders the URL in headless Google Chrome (auto-detected at
`/Applications/Google Chrome.app/...` on the dev Mac; `chromium`/`chromium-browser`
on Linux), **writes a PNG screenshot** (path printed; override with `UCSC_SHOT=`),
and **dumps the post-JS DOM** to `<log>.dom`. Read the screenshot to confirm the
block rendered; grep the DOM dump to assert on hydrated markup that `view.js`
added (e.g. the `clickable-item` class `ucsc-events` adds to each card):

```bash
grep -c 'ucsc-event-item clickable-item' /tmp/ucsc-run-*.log.dom
```

A nonzero count proves `view.js` ran *and* its `.wp-block-ucsc-events` selector
matched the server-rendered wrapper — the end-to-end signal the block is wired up.

Headless screenshots have **no login session**, so drive **public frontend
pages**, not `wp-admin`. To exercise a block that needs data, publish a page
containing it and seed its cache first (see Gotchas).

### Manual fallback

1. Use the available browser tool to open `https://wp-dev.ucsc/wp-admin/` and log in
   (`admin` / `password`) for editor-side checks a headless screenshot can't reach.
2. For frontend routing or block output, `curl -ks https://wp-dev.ucsc/path/`
   confirms server-rendered HTML (but not client JS — use `drive` for that).
3. Report what was observed in the running app.

Use the `verify` skill when the goal is to prove a code change or acceptance
criterion. Use the `validate` skill for Jest, PHP, or other automated tests.

## Runtime Introspection — `wp_eval.sh`

To inspect WordPress runtime state (registered blocks, options, transients) with
PHP, **do not** pipe an inline heredoc into `wp eval-file` — a command like
`printf '... $n[] = $name; ...' | docker compose exec -T wpcli wp eval-file -`
embeds PHP on the command line and trips zsh array/arith expansion permission
prompts. Instead run a bundled PHP file through a wrapper that pipes it over
STDIN (ADR-095):

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/run/list_blocks.sh"
```

[`list_blocks.sh`](list_blocks.sh) resolves the repo root via `source_base.sh`
and pipes [`helpers/list_blocks.php`](helpers/list_blocks.php) into
`wp eval-file -` over STDIN — listing every `ucsc/*` block in the live registry
across all activated plugins, with no PHP embedded in a shell string. For other
runtime queries, add a sibling `helpers/<name>.php` and a thin `*.sh` wrapper on
the same pattern rather than crafting an inline eval.

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
  [`helpers/seed_events_cache.php`](helpers/seed_events_cache.php) and is piped to
  wp-cli over STDIN — no inline eval heredoc, ADR-095):

  ```bash
  bash "${CLAUDE_PLUGIN_ROOT}/skills/run/seed_events_cache.sh"
  ```

  [`seed_events_cache.sh`](seed_events_cache.sh) seeds the transient; clear it
  again with `wp transient delete --all`.

- **Seed a demo page that contains every registered `ucsc/*` block** for a single
  frontend URL to drive/verify against, via
  [`seed_demo_page.sh`](seed_demo_page.sh) (PHP in
  [`helpers/seed_demo_page.php`](helpers/seed_demo_page.php)). It upserts the page
  and prints its URL:

  ```bash
  bash "${CLAUDE_PLUGIN_ROOT}/skills/run/seed_demo_page.sh"
  ```

- **Chrome headless against the vanity host.** The page lives at the self-signed
  `https://wp-dev.ucsc/` vhost. `driver.sh drive` passes
  `--host-resolver-rules="MAP wp-dev.ucsc 127.0.0.1"`, `--ignore-certificate-errors`,
  and `--virtual-time-budget=6000` (so `DOMContentLoaded` JS runs) — you do not
  need `/etc/hosts` edited for the headless path.

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
