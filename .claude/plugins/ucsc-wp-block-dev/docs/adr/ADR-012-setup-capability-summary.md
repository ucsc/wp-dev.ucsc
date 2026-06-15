---
title: "ADR-012: Setup provides a simple capability summary"
status: Superseded
date: 2026-06-09
---

# ADR-012: Setup capability summary

Superseded by ADR-039. The concise capability overview now lives in `map`;
`setup` is retired with `start` and `menu`.

## Decision

Provide a manual-only `setup` skill that briefly explains build, fix, test,
review, run, understand, and maintain capabilities. It must not perform broad
discovery and must point users to `map` for app-aware routing.
