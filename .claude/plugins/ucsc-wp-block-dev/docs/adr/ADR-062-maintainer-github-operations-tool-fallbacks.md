---
title: "ADR-062: GitHub operations may use CLI, MCP, or REST"
status: Accepted
date: 2026-06-16
---

# ADR-062: GitHub operations may use CLI, MCP, or REST

## Context

GitHub pull request work is often easiest with the `gh` CLI, and legacy
workflows may use `hub`. Those tools are not always installed or authenticated
in the local shell. MCP tools or direct GitHub REST API calls may be available
instead.

The plugin should not fail a GitHub workflow only because `gh` or `hub` is
missing. Per ADR-003, the workflow should prefer the path that uses the fewest
tokens while still providing the needed correctness and safety.

## Decision

GitHub operations may use any available safe channel, in this preference order:

1. GitHub MCP tools, if already available and low-token for the task.
2. `gh` CLI for local/manual CLI work.
3. GitHub REST API with a fine-grained token, when an appropriate token is
   available.
4. `hub` CLI only for legacy compatibility.
5. Manual compare URLs and user-run commands when no authenticated tool is
   available.

Prefer the least-token path that can complete the requested operation reliably.
Do not require installing `gh` or `hub` before attempting MCP or REST fallback.

ADR-055 still governs branch publication: the assistant must not run `git push`
or remote history rewrite operations. None of these GitHub channels should be
used by the assistant to push code. Pull request creation is allowed only after
the branch is already available remotely. If a PR cannot be created because the
branch is not remotely available, provide the manual push command and stop.

## Consequences

- **Positive:** GitHub workflows remain usable in shells without `gh` or `hub`.
- **Positive:** The assistant can choose lower-token MCP or REST paths when they
  are already available.
- **Negative:** Workflow behavior varies by available authentication and tooling,
  so summaries must state which channel was used.
