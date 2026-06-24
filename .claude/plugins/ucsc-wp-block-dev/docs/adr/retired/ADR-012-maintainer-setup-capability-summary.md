---
title: "ADR-012: Setup provides a simple capability summary"
status: Superseded
date: 2026-06-09
---

# ADR-012: Setup capability summary

Superseded by ADR-039. The concise capability overview now lives in `map`;
`setup` is retired with `start` and `menu`.

## Context

The original plugin needed a `setup` skill to give users a capability overview
on first use. Superseded by ADR-039, which moved this role to `map`.

## Decision

Provide a manual-only `setup` skill that briefly explains build, fix, test,
review, run, understand, and maintain capabilities. It must not perform broad
discovery and must point users to `map` for app-aware routing.
