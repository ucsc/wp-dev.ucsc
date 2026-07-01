# Environment Reference — supported development runtimes

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
   - Driver: `skills/run/drivers/wp-env.sh` (stub until implemented)

3. Local (LocalWP)
   - Detected by common Local.app paths or known Local directories
   - Driver: `skills/run/drivers/local.sh` (stub until implemented)

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

Troubleshooting

- If detection chooses the wrong environment, run `skills/run/driver.sh detect` to
  print probe outputs and adjust your working directory or set the explicit
  environment: `driver.sh wp-env build`.
- If BYO reports WordPress unreachable, confirm the site is up and reachable on
  localhost or the provided URL, and that host ports are not blocked by a local
  firewall.

References

- `skills/run/lib/detect-environment.sh` — detection logic and probes
- `skills/run/drivers/*` — environment drivers
- `skills/run/examples/env-invocations.md` — copy-paste commands per environment
