---
title: "ADR-101: validate 'all' mode runs suites sequentially in a single agent — no subagents, no parallel dispatch"
status: Accepted
date: 2026-06-24
supersedes: []
related: ["ADR-050", "ADR-066", "ADR-075", "ADR-078"]
---

# ADR-101: validate 'all' mode runs suites sequentially in a single agent

## Status

Accepted

## Context

ADR-075 established single-agent mode as the plugin-wide default. ADR-066
describes the PHP-only `validate-php.sh`. ADR-078 designates `validate-php.sh`
as the primary PHP check.

During a 2026-06-24 validation session covering `ucsc-events`, the agent
attempted to run PHP, Jest, and E2E suites in parallel using three concurrent
`run_command` calls. Two of those calls failed immediately:

- `docker compose run --rm plugin_npm_start` — **service does not exist** in
  the `wp-dev.ucsc` stack. The service name `plugin_npm_start` originated in
  ADR-050's amendment (2026-06-24) but was never provisioned in the compose
  file.
- `docker exec ucsc-wordpress-wp vendor/bin/phpunit` — **no `vendor/` tree**
  in the container; the driver phar-provisioning path is required.

The PHP suite succeeded only because the third parallel command correctly
invoked `validate-php.sh`. The failed parallel calls burned extra tool
invocations and confused the recovery path.

A separate observation: the Jest unit tests were ultimately run via
**host `npm test`** (calling `wp-scripts test-unit-js`), not via Docker.
This contradicts ADR-050's no-host-runtime rule, but is currently the only
reliable path because no containerised Node service for `ucsc-blocks` Jest
exists in the stack.

## Decision

1. **Sequential, not parallel.** The `validate all` battery runs suites one
   at a time: PHP → Jest → E2E. Do not dispatch them as parallel
   `run_command` calls. Each suite's result must be confirmed before the next
   starts; a failure in any suite should surface immediately.

2. **Single agent, no subagents.** ADR-075 applies here without exception.
   Do not spawn a subagent per suite or use `invoke_subagent` for validation.

3. **Canonical commands for each suite (ucsc-blocks plugin):**

   | Suite | Canonical command |
   |---|---|
   | PHP | `bash .claude/plugins/ucsc-wp-block-dev/skills/validate/validate-php.sh` |
   | Jest | `npm test --ci` run in `plugins/ucsc-blocks/` on the host |
   | E2E | `bash plugins/ucsc-blocks/tests/e2e/run-e2e.sh` |

4. **Do not attempt these before checking the canonical list:**
   - `docker compose run --rm plugin_npm_start` — service does not exist.
   - `docker exec ... vendor/bin/phpunit` — no vendor tree in container.
   - `docker exec ... phpunit` — not globally installed; use the driver.

5. **Host `npm test` exception.** Until a containerised Node service for
   `ucsc-blocks` is provisioned, Jest unit tests run via host Node. This is
   a **known temporary exception** to ADR-050. The exception is narrowly
   scoped: Jest only, `ucsc-blocks` only, via `npm test --ci`.

## Consequences

- **Positive:** No wasted tool calls from mis-named services or wrong paths.
- **Positive:** Failures surface at the correct suite boundary with full output.
- **Positive:** Single-agent execution keeps token spend minimal.
- **Negative:** Sequential run is slower than parallel for a passing battery.
- **Negative:** Host `npm test` creates a host-Node dependency until a
  containerised alternative is wired up in the compose stack.
