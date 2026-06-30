---
title: "ADR-007: Fix requires a user-provided concrete problem"
status: Superseded
date: 2026-06-09
---

# ADR-007: Fix requires a user-provided concrete problem

## Status

Accepted

## Context

The `fix` command can be invoked with only a broad target, such as a block name. Starting investigation from that alone encourages speculative debugging, unnecessary tool use, and changes that may not address the user's actual problem.

## Decision

Before any investigation, the `fix` skill must obtain from the user the target and the concrete thing that needs to be fixed. Per ADR-009, a plain-language description is sufficient. Additional useful forms include:

- a symptom or broken behavior;
- an error message or relevant log output;
- a failing test or build result;
- expected behavior contrasted with actual behavior.

A block, component, GUI, app, file, or feature name by itself is not sufficient because it supplies only the target. A problem description without a target is also insufficient. When either is missing, `fix` must ask one concise clarifying question and wait for the user's answer.

Until this gate is satisfied, `fix` must not inspect source files, logs, git history, browser state, runtime state, builds, or tests. After the user supplies the problem, the normal reproduce-first workflow begins.

## Consequences

- Investigation remains tied to the user's observed problem.
- Broad requests such as `fix course catalog` require clarification before tool use.
- The first reproduction and validation steps have a concrete success condition.
- Fix sessions may require one additional user turn when the initial request is underspecified.
