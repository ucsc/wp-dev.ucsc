---
title: "ADR-068: Allow establishing shared scripts in a shared skill folder"
status: Accepted
date: 2026-06-16
---

# ADR-068: Allow establishing shared scripts in a shared skill folder

## Status

Accepted

## Context

As the number of custom workflows and driver scripts (like `run/driver.sh`, `verify/driver.sh`, and `test/driver.sh`) grows within the `ucsc-wp-block-dev` plugin, the need arises to share utility functions, shell libraries, or helper scripts across multiple skills.
Duplicate scripts across multiple skill directories violate DRY (Don't Repeat Yourself) principles and increase maintenance overhead.
However, according to ADR-032, every supporting file under a skill directory must be referenced from that skill's `SKILL.md` to pass validation and structural tests.

## Decision

We will establish a dedicated `shared` skill directory (e.g., `skills/shared/`) to house reusable scripts, shell helpers, and other assets that are shared across multiple skill workflows.

1. Shared scripts and assets will reside under `skills/shared/` (e.g., `skills/shared/scripts/`, `skills/shared/references/`).
2. A top-level `skills/shared/SKILL.md` will be created to document and link to all nested files inside the `shared` folder, ensuring full compliance with ADR-032 reference checks.
3. The `shared` skill will be marked as a hidden manual skill (e.g., `disable-model-invocation: true` and/or omitting it from public routing as needed).

## Consequences

- **Positive:** Reduces code duplication across skill scripts and drivers, making utility updates easier to maintain.
- **Positive:** Satisfies the ADR-032 structure validation tests via a central `skills/shared/SKILL.md`.
- **Negative:** Shared utilities must be carefully designed to remain compatible with all calling skills.
