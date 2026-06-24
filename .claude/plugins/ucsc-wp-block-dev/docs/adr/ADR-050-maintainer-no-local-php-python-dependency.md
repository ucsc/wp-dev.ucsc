---
title: "ADR-050: No Local PHP or Python Dependency"
status: Accepted
date: 2026-06-15
---

# ADR-050: No Local PHP or Python Dependency

## Context

The `ucsc-wp-block-dev` plugin's workflows and test scripts (such as PHP test suites or Python validation scripts) historically made assumptions about the user's host environment. Specifically, we might assume that a local `php` binary or `python` environment is available to quickly execute code without booting Docker. This creates inconsistencies, runtime failures, and "command not found" errors for users missing those specific binaries.

## Decision

The `ucsc-wp-block-dev` plugin must not depend on a local `php` or `python` binary being installed on the host machine. 

1. **Docker Preferred:** For anything related to WordPress, PHP, or core plugin logic, always execute commands using Docker images (e.g., `php:8.1-cli` for standalone PHP testing, or the `wp-dev.ucsc` containers).
2. **Plugin Cache Fallback:** If specific tooling is required that isn't suited for a Docker run, the tool must be provisioned and made available entirely within the plugin cache or virtual environment, completely isolating it from the host's global binary expectations.

### Amendment (2026-06-24): Node and all test modes

The no-host-runtime rule explicitly includes **Node**, not just PHP and Python,
and applies to **all three test modes** (`php`, `jest`, `e2e`):

- `php` — throwaway `php:8.1-cli` container (tests stub WordPress).
- `jest` — ~~the stack's `plugin_npm_start` node service~~ **CORRECTED (2026-06-24):**
  `plugin_npm_start` does not exist in the compose stack. Jest unit tests for
  `ucsc-blocks` currently run via host `npm test --ci` as a temporary exception.
  See ADR-101 for the canonical suite commands and the known pitfalls list.
- `e2e` — a Node+Chromium container that drives the live `https://wp-dev.ucsc`
  frontend, reaching the host's published 443 via
  `--add-host=wp-dev.ucsc:host-gateway` (no host Chrome). The runner installs the
  container's own linux `node_modules` into a named volume so the host's tree is
  never used. See `skills/validate/references/run.md` for the canonical commands
  and the reusable host-gateway pattern.

## Consequences

- **Positive:** Guaranteed consistency across different developer machines. No more `command not found: php` errors.
- **Negative:** Executing tests or scripts via Docker adds slight overhead compared to native execution, and relies on the Docker daemon being active.
