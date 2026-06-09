---
title: "ADR-011: Every command resolves target, natural-language request, and optional Jira context"
status: Accepted
date: 2026-06-09
---

# ADR-011: Universal command intake

## Context

Commands need a consistent way to understand a target app, folder, GUI, block, file, or artifact; the user's goal in ordinary language; and optional Jira context.

## Decision

Every user-facing router and command handler must parse those three elements by meaning rather than fixed position. Explicit user instructions take precedence, Jira is optional, and handlers ask one concise question only when missing or conflicting information prevents useful work.

`start` is the primary entry point, `menu` is the lightweight router, `setup` is the short capability overview, and `issue-context` is the shared Jira normalizer. Routers preserve unresolved input when handing work to another skill.

Reference-only skills are excluded from owning task intake.

## Consequences

The WordPress and Laravel/Vue plugins share the same interaction model while retaining stack-specific commands, evidence, implementation patterns, and validation.
