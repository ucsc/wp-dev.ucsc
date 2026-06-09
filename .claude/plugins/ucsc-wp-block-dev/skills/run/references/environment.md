# wp-dev.ucsc environment — how the server actually runs

implements: ADR-002-RUN-WP-DEV

`wp-dev.ucsc` is a **home-rolled Docker Compose** environment. It is **not**
`@wordpress/env` (wp-env), **not** Local (LocalWP), **not** ddev, and **not** WP
Engine. There is no framework CLI — the lifecycle is plain `docker compose`
against bespoke compose files, with WP-CLI run inside a container. This is why
the `run` skill wraps everything in [`../driver.sh`](../driver.sh) (which shells
out to `docker compose ...` and `docker compose exec wpcli wp ...`) rather than
calling any environment manager.

Do not assume wp-env/Local/ddev/WP Engine conventions (no `wp-env start`, no
`.wp-env.json`, no `ddev` commands, no Local site UI). Drive the stack only
through `docker compose` / the `run` driver.

## What's at the repo root

- **`Dockerfile`** — builds the `wp` service from the official
  `wordpress:6.5.5-php8.1-apache` image, then adds the **PHP LDAP** extension
  (required by the Campus Directory block) and **Xdebug**. This custom image is
  the reason other off-the-shelf runtimes were not used (see below).
- **`docker-compose.yml`** — the base stack: `server` (nginx 1.19), `db`
  (mysql 8.0), `wp` (built from the `Dockerfile`), and `wpcli`
  (`wordpress:cli-php8.1`).
- **`docker-compose-start.yml`** — dev/watch overlay layered on the base. It
  adds the Node build/watch services (theme + plugin), including the
  `plugin_npm_start` service the driver uses for `npm run build`/watch.
- **`docker-compose-install.yml`** — one-shot bootstrap jobs:
  `theme_composer_install`, `theme_npm_install`, `plugin_npm_install`,
  `wordpress_install`.
- **`setup.sh`** — clones the theme and product plugins into `public/wp-content/`.
- **`.env.example.txt`** → copied to `.env` for first-time bootstrap.

## Lifecycle (what the driver automates)

```bash
# base stack only
docker compose up -d
# base stack + Node dev/watch environments
docker compose -f docker-compose.yml -f docker-compose-start.yml up -d
```

WordPress lives at `https://wp-dev.ucsc/` (self-signed cert; the vanity host is
mapped via `/etc/hosts` → `127.0.0.1 wp-dev.ucsc`). Dev credentials:
`admin` / `password`. WP-CLI is `docker compose exec wpcli wp <command>`.

## Why home-rolled (LDAP)

The Campus Directory block needs the **PHP LDAP** extension and a **UCSC VPN**
connection to reach the LDAP server. Off-the-shelf runtimes (wp-env / Local /
WP Engine local) did not cleanly support the custom LDAP-enabled PHP image at
the time, so a developer built this bespoke Docker image and compose set
instead. Standardizing onto a portable runtime would first need to solve LDAP
support in that runtime — tracked as a future direction in
[ADR-105](../../../docs/adr/ADR-105-run-runtime-mode-support-multiple-wp-local-runtimes-wp-env-local-wp-engine-beyond-home-rolled-wp-dev-ucsc.md)
(status: Proposed).

## Dev-only — not production

This Docker stack is the **local development** environment only. The real
WordPress site is production and is **not** this Docker stack. All build, test,
and PHP execution must go through the containers — never host Node/PHP/Composer
(ADR-002, and the `develop` skill's dev-only guardrail). The repo `README.md` is
the source of truth for setup and run steps.
