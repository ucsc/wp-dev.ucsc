---
title: "ADR-033: Store work-list state under CLAUDE_CONFIG_DIR"
status: Accepted
date: 2026-06-10
---

# ADR-033: Store work-list state under CLAUDE_CONFIG_DIR

## Status

Accepted

## Context

The plugin tracks cross-session progress in a work-list (historically `WORKFLOW-LIST.md` at the plugin root). Committing mutable session state into the plugin repo causes noisy diffs, merge conflicts across git worktrees, and ships throwaway progress notes inside the published plugin. The state is per-user and per-machine, not part of the plugin's source.

Claude Code exposes its configuration home as `CLAUDE_CONFIG_DIR` (default `~/.claude`). It is per-user, persists across clean checkouts and worktrees, and is already outside any project repo.

## Decision

Work-list / session-progress state is stored under `CLAUDE_CONFIG_DIR`, not in the plugin working tree.

- Resolve the base as `${CLAUDE_CONFIG_DIR:-$HOME/.claude}`.
- Persist plugin work-list state under a namespaced path, e.g. `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/ucsc-wp-block-dev/workflow-list.md`.
- Tools and skills that read or write work-list state MUST resolve this location rather than assume a repo-relative file.
- Source-controlled docs (ADRs, READMEs, the slide deck) remain in the repo; only mutable work-list/progress state moves out.

## Consequences

- The plugin repo stops accumulating progress-note churn; diffs stay about code and durable docs.
- State survives across git worktrees and clean checkouts and is shared per user.
- Migration follow-up: relocate the existing `WORKFLOW-LIST.md` content to the `CLAUDE_CONFIG_DIR` path and update any tooling/maintainer steps that reference the old repo-root file. Until migrated, the repo file is the fallback.
