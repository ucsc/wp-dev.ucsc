# Example invocations — per-environment quick commands

These copy-ready examples show how to use the run and validate drivers across
supported environments.

## Auto-detect (recommended)

```bash
# Auto-detect environment and run the whole lifecycle: inspect → build → launch → smoke
bash .claude/plugins/ucsc-wp-block-dev/skills/run/driver.sh auto all

# Auto-detect and drive a URL (headless Chrome captures post-JS DOM + console)
bash .claude/plugins/ucsc-wp-block-dev/skills/run/driver.sh auto drive https://wp-dev.ucsc/
```

## Explicit: wp-dev-ucsc (home-rolled Docker Compose)

```bash
# Use the extracted driver directly
bash .claude/plugins/ucsc-wp-block-dev/skills/run/driver.sh wp-dev-ucsc all

# Inspect the environment (non-destructive)
bash .claude/plugins/ucsc-wp-block-dev/skills/run/driver.sh wp-dev-ucsc inspect
```

## Explicit: wp-env

Requires `.wp-env.json` at the repo root first — copy the example:

```bash
cp .claude/plugins/ucsc-wp-block-dev/skills/run/wp-env-example.json .wp-env.json
```

```bash
# Full lifecycle: inspect -> build -> launch -> smoke
bash .claude/plugins/ucsc-wp-block-dev/skills/run/driver.sh wp-env all

# Inspect the environment (non-destructive)
bash .claude/plugins/ucsc-wp-block-dev/skills/run/driver.sh wp-env inspect

# Drive the frontend (headless Chrome captures post-JS DOM + console)
bash .claude/plugins/ucsc-wp-block-dev/skills/run/driver.sh wp-env drive http://localhost:8888/

# Stop
bash .claude/plugins/ucsc-wp-block-dev/skills/run/driver.sh wp-env down
```

Note: LDAP-dependent blocks (Campus Directory) do not work under wp-env — the
default image has no PHP LDAP extension. Non-LDAP blocks work fine.

## Explicit: local (LocalWP)

Requires the `lwp` CLI (Local has no first-party one) and the Local GUI app
running with the site already created:

```bash
curl -fsSL https://raw.githubusercontent.com/cartpauj/localwp-cli/main/scripts/install.sh | bash
lwp list   # find your site's name or ID
export UCSC_LOCAL_SITE=my-site
```

```bash
# Full lifecycle: inspect -> build -> launch -> smoke
bash .claude/plugins/ucsc-wp-block-dev/skills/run/driver.sh local all

# Inspect the environment (non-destructive)
bash .claude/plugins/ucsc-wp-block-dev/skills/run/driver.sh local inspect

# Drive the frontend (headless Chrome captures post-JS DOM + console); URL
# defaults to the resolved site URL if omitted
bash .claude/plugins/ucsc-wp-block-dev/skills/run/driver.sh local drive

# Stop
bash .claude/plugins/ucsc-wp-block-dev/skills/run/driver.sh local down
```

Note: LDAP-dependent blocks (Campus Directory) do not work under Local — same
constraint as wp-env. If `lwp status` output ever fails to parse a URL, set
`UCSC_LOCAL_URL=<url>` to bypass resolution.

## BYO (Bring Your Own) — generic guidance

```bash
# Validate a running WordPress site and then drive it
bash .claude/plugins/ucsc-wp-block-dev/skills/run/driver.sh byo drive https://your-site.test/

# If you manage WP via wp-env or Local, bring them up per their docs, then run
bash .claude/plugins/ucsc-wp-block-dev/skills/validate/validate-php.sh
bash .claude/plugins/ucsc-wp-block-dev/skills/validate/validate-jest.sh
bash .claude/plugins/ucsc-wp-block-dev/skills/validate/validate-e2e.sh
```

## Validate examples (repo-local)

If the repo ships `bin/validate*.sh`, prefer these:

```bash
cd public/wp-content/plugins/ucsc-gutenberg-blocks
bash bin/validate-php.sh
bash bin/validate-jest.sh
bash bin/validate-e2e.sh
```

If not, use the plugin-level validators which detect the environment and provide guidance:

```bash
bash .claude/plugins/ucsc-wp-block-dev/skills/validate/validate-php.sh
bash .claude/plugins/ucsc-wp-block-dev/skills/validate/validate-jest.sh
bash .claude/plugins/ucsc-wp-block-dev/skills/validate/validate-e2e.sh
```
