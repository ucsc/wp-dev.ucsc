# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

`wp-dev.ucsc` is a **home-rolled Docker Compose** local WordPress environment for
developing the UCSC theme and block plugins. It is **not** `@wordpress/env`
(wp-env), Local (LocalWP), ddev, or WP Engine — there is no framework CLI. The
whole lifecycle is plain `docker compose` against the repo's own compose files,
with a custom WordPress image and WP-CLI run inside a container.

- **Dev-only.** This Docker stack is the *local development* environment. The
  real WordPress site is production and is **not** this stack.
- **Never run host Node / PHP / Composer.** All build, test, and PHP execution
  must go through the containers (or the plugin driver below). Local Node/PHP is
  not the toolchain and will mislead.
- **Why home-rolled:** the *Campus Directory* block needs the PHP **LDAP**
  extension plus a UCSC **VPN** connection to reach the LDAP server, which
  off-the-shelf runtimes did not cleanly support — hence the custom image.

## Environment layout (root)

- `Dockerfile` — builds the `wp` service from `wordpress:6.5.5-php8.1-apache`,
  adding the PHP **LDAP** extension and **Xdebug** (port 9003).
- `docker-compose.yml` — base stack: `server` (nginx), `db` (mysql 8.0), `wp`
  (built from `Dockerfile`), `wpcli` (`wordpress:cli-php8.1`).
- `docker-compose-start.yml` — dev/watch **overlay**: Node build/watch services
  for the theme and the blocks plugin (`plugin_npm_start`).
- `docker-compose-install.yml` — one-shot **bootstrap** jobs
  (`theme_composer_install`, `theme_npm_install`, `plugin_npm_install`,
  `wordpress_install`).
- `setup.sh` — clones the product theme/plugins from `github.com/ucsc/*` into
  `public/wp-content/` (currently theme `ucsc-2022`, plugins
  `ucsc-gutenberg-blocks` and `ucsc-custom-functionality`).
- `.env.example.txt` → copy to `.env` before first run.

App URL: `https://wp-dev.ucsc/wp-admin/` (vanity host via `/etc/hosts` →
`127.0.0.1 wp-dev.ucsc`; self-signed cert — accept the browser warning). Dev
credentials: `admin` / `password`.

## Common commands

```bash
# Start base WordPress stack
docker compose up -d
# Start base stack + Node dev/watch (theme + blocks plugin); swap up->down to stop
docker compose -f docker-compose.yml -f docker-compose-start.yml up -d

# First-time bootstrap (after setup.sh and copying .env)
docker compose -f docker-compose-install.yml run --rm theme_composer_install
docker compose -f docker-compose-install.yml run --rm theme_npm_install
docker compose -f docker-compose-install.yml run --rm plugin_npm_install
docker compose -f docker-compose-install.yml run --rm wordpress_install

# WP-CLI (always through the wpcli container)
docker compose exec wpcli wp <command>
```

The block plugins use `@wordpress/scripts`; run their npm scripts **in-container**
against the shared `plugin_npm_start` service with a `-w` working-dir override,
e.g.:

```bash
docker compose -f docker-compose.yml -f docker-compose-start.yml run --rm \
  -w /var/www/html/wp-content/plugins/<plugin> plugin_npm_start npm run build
```

Available scripts per block plugin: `build`, `start` (watch), `test`
(`wp-scripts test-unit-js` — Jest), `test:e2e` (`wp-scripts test-e2e
--rootDir=tests/e2e` — Playwright), `lint:js`, `lint:css`, `format`. Run a single
Jest test by passing a path/`-t` after `npm test -- ...` in the same in-container
form.

## Block plugins — two plugins share one runtime

Two UCSC block plugins live under `public/wp-content/plugins/` and run in the
**same** Docker stack, with **different namespaces** — this distinction matters
for detection, builds, and rendered-HTML fingerprints:

- **`ucsc-blocks`** — namespace `ucsc/*`. Multi-block, single-plugin with
  `@wordpress/scripts`; each block is a directory `src/blocks/<slug>/`. Blocks:
  `calendar-feed`, `ucsc-events`.
- **`ucsc-gutenberg-blocks`** — dev namespace `ucscblocks/*`, **rendered**
  namespace `ucsc/*`. Mostly **dynamic** blocks (PHP render callbacks): PHP
  controller in `classes/<Name>.php`, markup in `templates/<Name>Template.php`,
  editor registration in `src/blocks/<Name>.js`, browser logic/styles in
  `src/components/<Name>/`. Some blocks are fully self-rendered (e.g.
  `class-schedule` renders its own table + filter modal in PHP/CSS/JS rather than
  embedding an external app).
- **`ucsc-custom-functionality`** — separate UCSC team; provides the
  `news-block`.

Because two plugins share the runtime, **identify which plugin** before
building/driving — do not rely on cwd autodetection.

## The ucsc-wp-block-dev Claude Code plugin

`.claude/plugins/ucsc-wp-block-dev/` is a Claude Code plugin (skills only) that
encodes the workflows for block development in this repo. Prefer it over
rediscovering commands:

- Skills: `hub` (inventory), `develop` (`feature`/`fix`), `run` (launch & drive),
  `validate` (`php`/`jest`/`e2e`/`all`), `verify` (live behavior), `review`,
  `feedback`, and `maintainer` (maintains the plugin itself).
- **`skills/run/driver.sh`** is the canonical wrapper for the Docker lifecycle —
  `driver.sh all|inspect|build|launch|smoke|drive <URL>|down`. Pass
  `UCSC_PLUGIN=ucsc-blocks|ucsc-gutenberg-blocks` to pick the plugin; the `drive`
  phase runs headless Chrome and captures post-JS DOM + console errors
  (`UCSC_SHOT=<path>` for a screenshot).
- The **block target** (which block to work on) is a persistent session value
  reused across skills; resolution and scripts live under
  `skills/develop/scripts/` and `skills/develop/references/`.
- Governance is ADR-driven in `.claude/plugins/ucsc-wp-block-dev/docs/adr/`
  (`index.md`), with `implements:` markers tying skills/scripts to ADRs and a
  pytest suite that tests the plugin itself. Run it via
  `skills/maintainer/scripts/run-self-test.sh`.

## Shell

Developer shell is macOS **zsh** with system **bash 3.2** — invoke scripts via
`bash <script>`, avoid bash-4-only syntax (`${var,,}`, `declare -A`, `&>>`,
`|&`), and don't put inline `#` comments in commands handed to the user.
