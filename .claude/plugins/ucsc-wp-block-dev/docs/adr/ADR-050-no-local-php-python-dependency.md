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

## Consequences

- **Positive:** Guaranteed consistency across different developer machines. No more `command not found: php` errors.
- **Negative:** Executing tests or scripts via Docker adds slight overhead compared to native execution, and relies on the Docker daemon being active.
