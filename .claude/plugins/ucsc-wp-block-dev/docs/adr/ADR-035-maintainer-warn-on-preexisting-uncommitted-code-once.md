---
title: "ADR-035: Warn once about pre-existing uncommitted code"
status: Accepted
date: 2026-06-12
---

# ADR-035: Warn once about pre-existing uncommitted code

## Context

Starting work in a repository that already contains uncommitted code creates a risk of confusing the user's changes with changes made during the current session. The user should know about that condition before the plugin operates on code.

Once an implementation session is underway, uncommitted changes are expected because the user and agent are iterating. Repeated dirty-worktree warnings during that iteration add noise and do not improve safety.

## Decision

Before the first code operation in a session or newly selected repository, inspect the target repository's Git status.

- If tracked or untracked code changes already exist, warn the user once before editing code.
- Briefly identify the affected paths or summarize the scope without dumping an unnecessarily large status listing.
- Treat those changes as pre-existing user work and preserve them.
- Do not block the requested work unless the existing changes make it unsafe or impossible to proceed.
- Record the initial state as the session baseline.
- Do not repeat the warning merely because the working tree remains dirty or gains changes during the current iteration.
- Check and warn again only when the target repository changes or a new session begins.

Documentation-only inspection and other read-only discovery do not require the warning, but the check must occur before the first operation that modifies or could overwrite code.

## Consequences

- Users receive an early warning when new work begins on top of uncommitted code.
- Pre-existing changes remain distinct from changes introduced during the session.
- Normal iterative development does not produce repeated dirty-worktree warnings.
- Implementations need a lightweight session baseline or equivalent once-per-repository state.
