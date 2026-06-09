---
title: "ADR-094: Expand harness path variables when issuing script commands to Claude"
status: Accepted
date: 2026-06-23
---

# ADR-094: Expand harness path variables when issuing script commands to Claude

## Status

Accepted

## Context

Skill instructions hand shell commands to Claude, which runs them through the
Bash tool. Two failure modes recur:

1. **Unstable paths.** Commands written with relative paths
   (`bash skills/develop/scripts/foo.sh`) only work when the working directory
   happens to be the plugin root, and commands that assign a script path to a
   temporary shell variable (`SCRIPT=…/foo.sh; bash "$SCRIPT"`) break because
   **shell state does not persist between Bash tool calls** — the variable is
   gone on the next invocation.
2. **Re-derivation.** When a skill lists several related one-off commands, Claude
   re-issues and re-derives them each run, multiplying the chance of a path slip.

The harness already exports stable, absolute path variables into every Bash
invocation: `${CLAUDE_PLUGIN_ROOT}` (this plugin's root) and
`${CLAUDE_PROJECT_DIR}` (the project root). These expand at execution time and do
not depend on the current directory or on prior shell state.

## Decision

**Where possible, issue commands using harness-expanded path variables, and
prefer a single self-locating wrapper script over a list of ad-hoc commands.**

1. **Use `${CLAUDE_PLUGIN_ROOT}` / `${CLAUDE_PROJECT_DIR}`** for script and
   project paths in skill instructions:

   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/skills/develop/scripts/session-target.sh" get
   bash "${CLAUDE_PLUGIN_ROOT}/skills/develop/scripts/block-target-check.sh" <path>
   ```

   Do **not** assign script paths to temporary shell variables, and do not rely
   on the current working directory.

2. **Self-locate inside scripts** with `${BASH_SOURCE[0]}` so a script can call
   its siblings without depending on the caller's cwd or on
   `${CLAUDE_PLUGIN_ROOT}` being set:

   ```bash
   SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
   bash "$SCRIPT_DIR/session-target.sh" get
   ```

3. **Bundle related checks into one wrapper script.** When a skill would
   otherwise instruct Claude to run several related commands in sequence, put
   that logic in a single script and instruct Claude to run only that one
   canonical command. `skills/develop/scripts/check-session-target.sh` is the
   reference example: it lists the target scripts and prints the persisted
   session target in one call, so the skill issues just:

   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/skills/develop/scripts/check-session-target.sh"
   ```

This complements ADR-092 (zsh-safe command issuance): together they say *how* to
hand a command to Claude — absolute via harness vars, no temp vars, one wrapper
over many ad-hoc lines.

## Consequences

- **Positive:** Commands work regardless of cwd and survive the non-persistent
  shell between Bash calls; fewer path slips; one canonical command per task is
  easier to issue correctly and cheaper in tokens than a re-derived sequence.
- **Positive:** Scripts that self-locate via `${BASH_SOURCE[0]}` are portable —
  they run the same from a skill, a test, or a developer shell.
- **Negative:** Adds small wrapper scripts that must be referenced from their
  SKILL.md (ADR-032) and kept in sync as the underlying scripts evolve.

## Related

- ADR-092: zsh-safe terminal command issuance on macOS
- ADR-093: Persistent session block target (the scripts wrapped here)
