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

implements: ADR-002-RUN-WP-DEV, ADR-030-RUN-SEPARATION, ADR-073-RUN-CLAUDE-ONLY

Follow this recorded project recipe instead of rediscovering the launch process. Work from the `wp-dev.ucsc` root.

## Universal Command Intake

Resolve the target app or block surface, natural-language run request, and optional Jira key/URL from the full input and session context. Ask one concise question only when the target or requested operation cannot be inferred safely.

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

**Plugin target.** `ucsc-blocks` and `ucsc-gutenberg-blocks` share the one
wp-dev.ucsc Docker runtime. The driver autodetects which plugin to build from the
current directory (any `.../wp-content/plugins/<slug>` segment) and builds it via a
per-invocation `-w` working-dir override against the shared `plugin_npm_start`
service — no second service is needed. Override detection with `UCSC_PLUGIN=<slug>`
(e.g. `UCSC_PLUGIN=ucsc-blocks`). Each plugin has its own `node_modules`, so the
first `build` for a plugin runs `npm ci` in-container before compiling.

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

1. Use a visual browser tool to open `https://wp-dev.ucsc/wp-admin/` and log in
   (`admin` / `password`) for editor-side checks a headless screenshot can't reach.
2. For frontend routing or block output, `curl -ks https://wp-dev.ucsc/path/`
   confirms server-rendered HTML (but not client JS — use `drive` for that).
3. Report what was observed in the running app.

Use the `verify` skill when the goal is to prove a code change or acceptance
criterion. Use the `validate` skill for Jest, PHP, or other automated tests.

## Gotchas

- **`ucsc-blocks` fatals on activation without `composer install`.** Its main
  file `require`s `vendor/yahnis-elsts/plugin-update-checker/...` at load with no
  `file_exists` guard, so activating it before the vendor dir exists throws a
  fatal (`Failed opening required ...plugin-update-checker.php`). Install runtime
  deps in-container by reusing the theme's composer service with a `-w` override
  (same pattern as the npm build — no per-plugin service needed):

  ```bash
  docker compose -f docker-compose-install.yml run --rm \
    -w /var/www/html/wp-content/plugins/ucsc-blocks \
    theme_composer_install install --no-dev --no-interaction
  ```

- **Seed the events cache to render cards without the live API.** `ucsc/events`
  renders a placeholder until `ucsc_events_fetch_data()` has data; that data is a
  transient keyed `ucsc_events_<md5(apiUrl)>`. Seed it so the block renders real
  `.ucsc-event-item` cards offline:

  ```bash
  docker compose exec -T wpcli wp eval '
    $api = "https://events.ucsc.edu/wp-json/tribe/v1/events";
    $key = "ucsc_events_" . md5($api);
    set_transient($key, array(
      array("title"=>"Sample Event","link"=>"https://events.ucsc.edu/e/1","date"=>"July 10, 2026","venue"=>"Quarry Plaza","slug"=>"e1","featured_image"=>""),
    ), HOUR_IN_SECONDS);
    echo "seeded\n";'
  ```

  Clear it again with `wp transient delete --all`.

- **Chrome headless against the vanity host.** The page lives at the self-signed
  `https://wp-dev.ucsc/` vhost. `driver.sh drive` passes
  `--host-resolver-rules="MAP wp-dev.ucsc 127.0.0.1"`, `--ignore-certificate-errors`,
  and `--virtual-time-budget=6000` (so `DOMContentLoaded` JS runs) — you do not
  need `/etc/hosts` edited for the headless path.

## Recovery

- If Compose reports orphan containers, add `--remove-orphans`.
- **"Error establishing a database connection" right after `up -d`** — the `db` container needs a few seconds before wp-cli can connect. Wait and retry; `driver.sh launch` polls `wp option get siteurl` for up to 60s before activating the plugin.
- **`wp db <cmd>` fails with `caching_sha2_password could not be loaded`** — that is the bundled mysql CLI client, not a real database fault. Use PHP/mysqli-path commands instead (`wp option get`, `wp eval`, `wp plugin …`). The driver's readiness probe relies on this.
- If API output is stale, run `docker compose exec wpcli wp transient delete --all`.
- If Campus Directory fails locally, confirm VPN access and `DOCKER_DEV=docker_dev`.
- Do not delete containers, volumes, repositories, or user data without explicit approval.
