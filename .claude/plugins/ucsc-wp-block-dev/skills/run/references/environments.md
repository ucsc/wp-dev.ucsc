# Environment Reference — supported development runtimes

implements: ADR-002-RUN-WP-DEV

This document summarizes the environments the ucsc-wp-block-dev skills support,
detection rules, and guidance for BYO setups. The run and validate skills use
`skills/run/lib/detect-environment.sh` to auto-detect the active environment and
route to drivers in `skills/run/drivers/`.

Supported environments (detection precedence):

1. wp-dev-ucsc (home-rolled Docker Compose)
   - Detected by presence of `docker-compose.yml` + repository Dockerfile markers
   - Full driver: `skills/run/drivers/wp-dev-ucsc.sh`

2. wp-env
   - Detected by `wp-env` markers in `package.json` or `wp-env.json`
   - Full driver: `skills/run/drivers/wp-env.sh` (inspect/build/launch/smoke/drive/down)
   - Requires `.wp-env.json` at the repo root — copy `skills/run/wp-env-example.json`
     (same pattern as `.env.example.txt`). Not auto-created, so opting in is explicit
     and the default wp-dev-ucsc detection is unaffected (this repo's
     `docker-compose.yml` + `Dockerfile` markers still win auto-detection — see
     "Auto-detect and wp-env" below).
   - LDAP-dependent blocks (Campus Directory) are **not supported**: the default
     wp-env WordPress image has no PHP LDAP extension or UCSC VPN reachability.
     Non-LDAP blocks work fine.
   - Unlike wp-dev-ucsc.sh, the `build` phase runs `npm` on the host — wp-env has
     no equivalent in-repo build container, and the "never run host Node" guardrail
     targets the wp-dev-ucsc stack specifically, not a developer who has opted into
     wp-env.

3. Local (LocalWP)
   - Detected by common Local.app paths or known Local directories
   - Full driver: `skills/run/drivers/local.sh` (Phase 4b:
     inspect/build/launch/smoke/drive/down)
   - Local has no first-party scriptable CLI (the official `getflywheel/local-cli`
     is archived), so this driver shells out to the third-party `lwp`
     (cartpauj/localwp-cli), which talks to Local's own local GraphQL API. The
     Local GUI app must be installed and running at least once. Install `lwp`:
     `curl -fsSL https://raw.githubusercontent.com/cartpauj/localwp-cli/main/scripts/install.sh | bash`
   - Requires `UCSC_LOCAL_SITE=<name-or-id>` (see `lwp list` for the site's
     name/ID) — Local site names are per-developer, not part of this repo, so
     there is no default. The site's public URL is resolved from `lwp status
     <site>`; override with `UCSC_LOCAL_URL=<url>` if that parsing ever drifts
     from lwp's output format.
   - LDAP-dependent blocks (Campus Directory) are **not supported**: stock
     Local sites have no PHP LDAP extension or UCSC VPN reachability — same
     gating constraint as wp-env.
   - Like wp-env.sh, the `build` phase runs `npm` on the host — Local has no
     in-repo build container either. This assumes the standard Local workflow
     of symlinking the Local site's plugin directory to this repo's own
     checkout (`public/wp-content/plugins/<plugin>`) rather than maintaining a
     second, disconnected copy of the plugin inside the Local site.

4. WP Engine (wpe)
   - Detected by `WPE_*` environment variables or `.wpe` marker
   - Treated as a remote-targeted environment; BYO guidance applies unless a driver exists

5. bare-wp-cli / running-generic
   - Detected by `wp` CLI availability or an HTTP probe that looks WordPress-specific
   - Falls back to `generic-byo` driver which validates the site and instructs the user

BYO (Bring Your Own) guidance

- The BYO driver (`skills/run/drivers/generic-byo.sh`) validates a reachable WordPress
  URL (HTTP probe checks for `wp-login`, `wp-admin`, or `WordPress` strings),
  then prints recommended commands for driving, building, and validating tests in
  that environment.
- Use BYO when the repository's environment is not one of the supported types or
  when the developer prefers to manage services locally (wp-env, Local, remote hosts).

Adding a new driver

1. Create `skills/run/drivers/<env>.sh` exposing the same interface as the
   existing drivers (inspect, build, launch, smoke, drive, down).
2. Add a detection probe to `skills/run/lib/detect-environment.sh` with tests.
3. Add documentation to this file and examples in `skills/run/examples/env-invocations.md`.

Auto-detect and wp-env

This repository ships `docker-compose.yml` + the LDAP-marked `Dockerfile`
unconditionally, and `detect-environment.sh` checks for those wp-dev-ucsc
markers first. That means `driver.sh auto <phase>` always resolves to
`wp-dev-ucsc` in this repo, even after adding `.wp-env.json` — auto-detection
picks the packaged default, not per-developer intent. A developer who wants
wp-env instead must say so explicitly: `driver.sh wp-env <phase>`. This is
deliberate (ADR-105 decision 4: additive, default-unchanged), not a bug.

Troubleshooting

- If detection chooses the wrong environment, run
  `bash skills/run/lib/detect-environment.sh` to print the detected environment
  and adjust your working directory, or bypass detection with the explicit
  environment: `driver.sh wp-env build`.
- If BYO reports WordPress unreachable, confirm the site is up and reachable on
  localhost or the provided URL, and that host ports are not blocked by a local
  firewall.

References

- `skills/run/lib/detect-environment.sh` — detection logic and probes
- `skills/run/drivers/*` — environment drivers
- `skills/run/examples/env-invocations.md` — copy-paste commands per environment

## wp-dev.ucsc in depth — how the home-rolled stack actually runs

`wp-dev.ucsc` is a **home-rolled Docker Compose** environment. There is no
framework CLI — the lifecycle is plain `docker compose` against bespoke compose
files, with WP-CLI run inside a container. This is why the wp-dev-ucsc driver
shells out to `docker compose ...` and `docker compose exec wpcli wp ...`
rather than calling any environment manager. When this environment is detected,
do not assume wp-env/Local/ddev/WP Engine conventions (no `wp-env start`, no
`.wp-env.json`, no `ddev` commands, no Local site UI).

### What's at the repo root

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

### Lifecycle (what the driver automates)

```bash
# base stack only
docker compose up -d
# base stack + Node dev/watch environments
docker compose -f docker-compose.yml -f docker-compose-start.yml up -d
```

WordPress lives at `https://wp-dev.ucsc/` (self-signed cert; the vanity host is
mapped via `/etc/hosts` → `127.0.0.1 wp-dev.ucsc`). Administrator credentials
are private local-environment configuration and are not recorded in this public
plugin. WP-CLI is `docker compose exec wpcli wp <command>`.

### Why home-rolled (LDAP)

The Campus Directory block needs the **PHP LDAP** extension and a **UCSC VPN**
connection to reach the LDAP server. Off-the-shelf runtimes (wp-env / Local /
WP Engine local) did not cleanly support the custom LDAP-enabled PHP image at
the time, so a developer built this bespoke Docker image and compose set
instead. Standardizing onto a portable runtime would first need to solve LDAP
support in that runtime — tracked in
[ADR-105](../../../docs/adr/ADR-105-run-runtime-mode-support-multiple-wp-local-runtimes-wp-env-local-wp-engine-beyond-home-rolled-wp-dev-ucsc.md).

### Dev-only — not production

This Docker stack is the **local development** environment only. The real
WordPress site is production and is **not** this Docker stack. All build, test,
and PHP execution must go through the containers — never host Node/PHP/Composer
(ADR-002, and the `develop` skill's dev-only guardrail). The repo `README.md`
is the source of truth for setup and run steps.
