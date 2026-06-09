# Run: gotchas

implements: ADR-095-RUN-WP-EVAL, ADR-097-RUN-CONSOLE-CAPTURE

Situational traps hit only in specific scenarios — not on every run. The
`run/SKILL.md` "Gotchas" section is the compact index; this file is the detail.

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
  [`helpers/seed-events-cache.php`](../helpers/seed-events-cache.php) and is piped
  to wp-cli over STDIN — no inline eval heredoc, ADR-095):

  ```bash
  bash "${CLAUDE_PLUGIN_ROOT}/skills/run/seed-events-cache.sh"
  ```

  [`seed-events-cache.sh`](../seed-events-cache.sh) seeds the transient; clear it
  again with `wp transient delete --all`.

- **Seed a demo page that contains every registered `ucsc/*` block** for a single
  frontend URL to drive/verify against, via
  [`seed-demo-page.sh`](../seed-demo-page.sh) (PHP in
  [`helpers/seed-demo-page.php`](../helpers/seed-demo-page.php)). It upserts the
  page and prints its URL:

  ```bash
  bash "${CLAUDE_PLUGIN_ROOT}/skills/run/seed-demo-page.sh"
  ```

- **Chrome headless against the vanity host.** The page lives at the self-signed
  `https://wp-dev.ucsc/` vhost. `driver.sh drive` passes
  `--host-resolver-rules="MAP wp-dev.ucsc 127.0.0.1"`, `--ignore-certificate-errors`,
  and `--virtual-time-budget=6000` (so `DOMContentLoaded` JS runs); the headless
  path does not require an `/etc/hosts` edit.
