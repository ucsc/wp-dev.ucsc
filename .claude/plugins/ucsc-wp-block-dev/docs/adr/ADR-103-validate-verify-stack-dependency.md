---
title: "ADR-103: Validate and verify should invoke run skill if docker is down"
status: Accepted
date: 2026-06-24
---

# ADR-103: Validate and verify should invoke run skill if docker is down

## Status

Accepted

## Context

The `validate` skill (specifically the `e2e` and `all` modes) and the `verify` skill both require the local WordPress environment (the Docker/ddev stack) to be actively running so that headless browsers or manual tests can reach the frontend URLs (e.g., `https://wp-dev.ucsc/...`). When the stack is down, these operations fail with cryptic errors (such as `net::ERR_CONNECTION_REFUSED`), wasting time and tokens. The `run` skill already encapsulates the logic to correctly bring up the local development stack.

## Decision

Before executing operations that depend on a live backend (`validate e2e`, `validate all`, or `verify`), the agent must verify if the Docker environment is running. If the stack is down or unreachable, the agent must proactively invoke the `run` skill to start the local WordPress environment and ensure it is ready before proceeding with the tests or verification.

## Consequences

- **Positive:** Eliminates false-negative test failures and cryptic network errors. Gracefully handles a missing dependency by automating the spin-up process.
- **Negative:** May slightly increase the time to start tests if a health-check is required, and silently invoking the `run` skill in the background may consume more tokens.
