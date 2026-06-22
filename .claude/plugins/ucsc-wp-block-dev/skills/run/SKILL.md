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

Apply ADR-011: resolve the target app or block surface, natural-language run request, and optional Jira key/URL from the full input and session context. Ask one concise question only when the target or requested operation cannot be inferred safely.

## Fast Path — `driver.sh`

For the routine lifecycle, prefer the bundled [`driver.sh`](driver.sh) over issuing the Docker/npm/wp commands one at a time. It runs a whole phase in a single call and prints a compact PASS/FAIL summary, sending verbose output to a logfile it names on exit — read that log only when a step reports FAIL. This keeps a full build-and-launch to ~14 lines of output instead of a dozen noisy command dumps.

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/run/driver.sh" all      # inspect → build → launch → smoke
bash "${CLAUDE_PLUGIN_ROOT}/skills/run/driver.sh" inspect  # non-destructive state check
bash "${CLAUDE_PLUGIN_ROOT}/skills/run/driver.sh" build    # Dockerized `npm run build`
bash "${CLAUDE_PLUGIN_ROOT}/skills/run/driver.sh" launch   # up -d, wait for DB, activate plugin
bash "${CLAUDE_PLUGIN_ROOT}/skills/run/driver.sh" smoke    # containers, wp-admin, plugin, blocks
bash "${CLAUDE_PLUGIN_ROOT}/skills/run/driver.sh" down     # stop the stack
```

If `${CLAUDE_PLUGIN_ROOT}` is unset, call the script by its in-plugin path (`skills/run/driver.sh`). The driver autodetects the `wp-dev.ucsc` root; override with `WP_DEV_ROOT=/path`.

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

Do not stop at container health when the user asks to see the application working.

1. Use the available browser tool to open `https://wp-dev.ucsc/wp-admin/`. If no visual browser tool is available and you need to verify frontend routing or block output (like FSE template fallbacks), use headless requests like `curl -ks https://wp-dev.ucsc/path/`.
2. Log in when needed.
3. Navigate to the relevant editor, page, or frontend route.
4. Exercise the requested block interaction.
5. Report what was observed in the running app (or the HTML output if fetching headlessly).

Use the `verify` skill when the goal is to prove a code change or acceptance
criterion. Use the `validate` skill for Jest, PHP, or other automated tests.

## Recovery

- If Compose reports orphan containers, add `--remove-orphans`.
- **"Error establishing a database connection" right after `up -d`** — the `db` container needs a few seconds before wp-cli can connect. Wait and retry; `driver.sh launch` polls `wp option get siteurl` for up to 60s before activating the plugin.
- **`wp db <cmd>` fails with `caching_sha2_password could not be loaded`** — that is the bundled mysql CLI client, not a real database fault. Use PHP/mysqli-path commands instead (`wp option get`, `wp eval`, `wp plugin …`). The driver's readiness probe relies on this.
- If API output is stale, run `docker compose exec wpcli wp transient delete --all`.
- If Campus Directory fails locally, confirm VPN access and `DOCKER_DEV=docker_dev`.
- Do not delete containers, volumes, repositories, or user data without explicit approval.
