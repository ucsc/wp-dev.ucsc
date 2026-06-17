---
title: "ADR-066: Introduce test/driver.sh script for automated test suites"
status: Accepted
date: 2026-06-16
---

# ADR-066: Introduce test/driver.sh script for automated test suites

## Status

Accepted

## Context

The plugin establishes high-value patterns with token-frugal driver scripts: `run/driver.sh` and `verify/driver.sh`. They run entire development phases in a single call and print a compact summary, while redirection of verbose logs to log files reduces the agent's token consumption.
However, a gap remained: the `test` skill still required running separate commands for PHP, Jest, or e2e tests and reading their full, verbose stdout.

## Decision

We will introduce a test driver at `skills/test/driver.sh` to match the established driver conventions:

1. The script accepts subcommands: `php`, `jest`, `e2e`, and `all` (default).
2. It detects the `wp-dev.ucsc` root and plugin paths.
3. It runs the selected test suites within Docker (for PHP tests, it runs all tests in a single container run call; for Jest tests, it uses the `plugin_npm_start` service).
4. All verbose test logs are redirected to a log file (`/tmp/ucsc-test-*.log`).
5. It parses the log file to output pass/fail counts and lists the names of failing tests.
6. It exits with 0 on overall success and non-zero on any failure.

## Consequences

- **Positive:** Reduces token use significantly for running tests (from hundreds of lines of output down to less than 10 lines of summary).
- **Positive:** Parity with `run/driver.sh` and `verify/driver.sh`.
- **Negative:** None.
