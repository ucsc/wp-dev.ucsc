# Run: recovery

implements: ADR-002-RUN-WP-DEV

Failure-path remedies used only when the stack misbehaves — not on every run. The
`run/SKILL.md` "Recovery" section is the compact pointer; this file is the detail.

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
- **"Error establishing a database connection" right after `up -d`** — the `db`
  container needs a few seconds before wp-cli can connect. Wait and retry;
  `driver.sh launch` polls `wp option get siteurl` for up to 60s before
  activating the plugin.
- **`wp db <cmd>` fails with `caching_sha2_password could not be loaded`** — that
  is the bundled mysql CLI client, not a real database fault. Use PHP/mysqli-path
  commands instead (`wp option get`, `wp eval`, `wp plugin …`). The driver's
  readiness probe relies on this.
- If API output is stale, run `docker compose exec wpcli wp transient delete --all`.
- If Campus Directory fails locally, confirm VPN access and `DOCKER_DEV=docker_dev`.
- Do not delete containers, volumes, repositories, or user data without explicit
  approval.
