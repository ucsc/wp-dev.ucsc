---
title: "ADR-066: Introduce validate/driver.sh script for automated test suites"
status: Accepted
date: 2026-06-16
---

# ADR-066: Introduce validate/driver.sh script for automated test suites

## Status

Accepted

## Context

The plugin establishes high-value patterns with token-frugal driver scripts: `run/driver.sh` and `verify/driver.sh`. They run entire development phases in a single call and print a compact summary, while redirection of verbose logs to log files reduces the agent's token consumption.
However, a gap remained: the `validate` skill still required running separate commands for PHP, Jest, or e2e tests and reading their full, verbose stdout.

## Decision

We will introduce a validate driver to run the plugin's automated PHP suite in a
single token-frugal call. As amended (see below), the driver is **PHP-only**:

1. The script is `skills/validate/validate-php.sh` and takes no subcommands.
2. It runs the `ucsc-blocks` PHPUnit suite inside the running wp-dev.ucsc
   WordPress container.
3. It auto-detects the container (`ucsc-wordpress-wp`, image `wp-devucsc-wp`),
   overridable via `WP_CONTAINER`, and targets the plugin folder via
   `PLUGIN_SLUG` (default `ucsc-blocks`).
4. Because the container ships no Composer/PHPUnit and `tests/bootstrap.php` runs
   in standalone mode (stubs WordPress, loads block PHP directly), the driver
   provisions a PHPUnit 10 phar to `/tmp` on demand. Override the source with
   `PHPUNIT_PHAR_URL`.
5. It exits 0 on success and non-zero on failure.

Jest is run via the plugin's `npm` scripts, not this driver.

## Amendment (2026-06-23)

The original decision (below) described a driver with `php|jest|e2e|all`
subcommands, `wp-dev.ucsc` path detection, `/tmp/ucsc-test-*.log` redirection,
and pass/fail summary parsing. **None of that was ever implemented.** A
2026-06-23 review/fix session found `validate-php.sh` was a PHP-only stub that
additionally pointed at the wrong container name (`wp-dev.ucsc`) and wrong plugin
slug (`ucsc-gutenberg-blocks`, a separate legacy plugin), and assumed an
installed phpunit that the container lacks — so it never ran. Rather than build
out the unimplemented surface, we scope this ADR down to the PHP-only driver that
the workflow actually needs (Jest already has an `npm` path). The original
Decision is retained for history:

> 1. The script accepts subcommands: `php`, `jest`, `e2e`, and `all` (default).
> 2. It detects the `wp-dev.ucsc` root and plugin paths.
> 3. It runs the selected test suites within Docker (for PHP tests, it runs all
>    tests in a single container run call; for Jest tests, it uses the
>    `plugin_npm_start` service).
> 4. All verbose test logs are redirected to a log file (`/tmp/ucsc-test-*.log`).
> 5. It parses the log file to output pass/fail counts and lists the names of
>    failing tests.
> 6. It exits with 0 on overall success and non-zero on any failure.

## Consequences

- **Positive:** A single call runs the PHP suite even on a container without
  Composer/PHPUnit installed.
- **Positive:** Docs and the script now agree (no false subcommand interface).
- **Negative:** No log-redirection/summary parsing or Jest/e2e parity with
  `run/driver.sh` and `verify/driver.sh`; revisit if that parity is wanted.
