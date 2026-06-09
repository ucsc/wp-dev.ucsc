---
name: run
description: Build, launch, and smoke-test the ucsc-gutenberg-blocks plugin via the wp-dev.ucsc Docker environment. Use when asked to run, start, build, watch, or test the WordPress plugin, or when verifying the Docker environment is healthy.
argument-hint: "[target | run/verify request | Jira key/URL]"
arguments: [input]
---

# Run — ucsc-wp-block-dev

Lifecycle commands for `ucsc-gutenberg-blocks` in the `wp-dev.ucsc` local Docker environment.

**Usage:** `/ucsc-wp-block-dev:run [build | start | test | smoke-check]`.

All paths relative to `wp-dev.ucsc/` unless noted.

## Universal Command Intake

Apply ADR-011: resolve the target app or block surface, natural-language build/run/verification request, and optional Jira key/URL from the full input and session context. Merge Jira acceptance criteria when they define what must be verified, and ask one concise question only when the target or requested operation cannot be inferred safely.

## Prerequisites

- Docker Desktop running
- `public/wp-content/plugins/ucsc-gutenberg-blocks/` present and checked out

## Build

```bash
cd public/wp-content/plugins/ucsc-gutenberg-blocks
npm install
npm run build
```

`npm run build` compiles `src/` → `build/index.js` + `build/index.asset.php` via `@wordpress/scripts`.

For watch mode during active development:

```bash
npm start
```

## Start Docker Environment

```bash
docker compose up -d
```

WordPress available at `http://localhost:8080/wp-admin/`.

## Activate Plugin

```bash
docker compose exec wpcli wp plugin activate ucsc-gutenberg-blocks
```

Or verify it is already active:

```bash
docker compose exec wpcli wp plugin list --name=ucsc-gutenberg-blocks
```

## Run Tests

Note: the plugin does not currently have a `test` script in `package.json`. If Jest tests are added, run them via Docker:

```bash
docker compose -f docker-compose.yml -f docker-compose-start.yml run --rm \
  -w /var/www/html/wp-content/plugins/ucsc-gutenberg-blocks \
  plugin_npm_start npm test
```

Or locally from inside the plugin directory (requires local Node matching the Docker version):

```bash
npm test
```

## Smoke Checks

After starting, verify:

1. `docker compose ps` — all containers healthy
2. `http://localhost:8080/wp-admin/` loads login page
3. `docker compose exec wpcli wp plugin list` — `ucsc-gutenberg-blocks` shows as active
4. Open the block editor on any post — UCSC blocks appear in the inserter

## Gotchas

- **Build before activate.** `build/index.js` must exist or the block editor throws an asset error.
- **`npm start` vs `npm run build`** — `start` watches and rebuilds on save; `build` is one-shot for production/test.
- **Transient cache** — if API data looks stale locally, flush transients: `docker compose exec wpcli wp transient delete --all`.
- **LDAP in Docker** — Campus Directory binds anonymously when `DOCKER_DEV=docker_dev` is set in the container env.
