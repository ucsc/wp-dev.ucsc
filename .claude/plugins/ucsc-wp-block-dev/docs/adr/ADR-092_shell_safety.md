---
title: "ADR-092: Detect the shell and emit zsh-safe terminal commands on macOS"
status: Accepted
date: 2026-06-23
---

# ADR-092: Detect the shell and emit zsh-safe terminal commands on macOS

## Status

Accepted

## Context

The developer environment for this project is macOS, where the interactive shell
is **zsh** (default since Catalina) and the system `bash` is 3.2. Skills routinely
issue ad-hoc terminal commands while running, building, and inspecting the
wp-dev.ucsc stack. When those commands assume bash-4 syntax, bash-only constructs,
or carry inline `#` comments, they fail or misbehave in interactive zsh — the
developer "always sees errors due to commands not valid in zsh, then retries."
Each retry wastes time and tokens and erodes trust in the driver-first workflow.

This is a cross-cutting concern: it applies to every skill that emits terminal
commands (`run`, `verify`, `validate`, `develop`), not just one.

## Decision

Before issuing terminal commands, assume the target is **macOS zsh** and emit
shell-safe commands. Concretely:

1. **Detect when it matters.** When command behavior depends on the shell,
   confirm it with `echo "$SHELL"` or `ps -p $$` rather than guessing; otherwise
   default to zsh-on-macOS.
2. **Run scripts through an explicit interpreter.** Invoke driver/helper scripts
   as `bash <script>` (they are `#!/bin/bash`), never by relying on the
   interactive shell to interpret bash syntax. This is why the run/verify/validate
   drivers are invoked as `bash .../driver.sh` — it sidesteps zsh/bash differences
   entirely.
3. **No inline `#` comments in commands handed to the user.** Interactive zsh can
   choke on them; put explanations in prose before/after the command.
4. **Avoid bash-4-only / bash-specific constructs** in interactive commands:
   `${var,,}`, `declare -A`, `&>>`, `|&`, process-substitution assumptions. Use
   portable forms (e.g. `tr '[:upper:]' '[:lower:]'`).
5. **Quote globs and paths** instead of relying on shell-specific globbing or
   word-splitting.

`run` is the reference implementation (the command-heaviest surface); the same
convention applies to the other command-issuing skills.

## Consequences

- **Positive:** Fewer failed commands and retries; commands the developer can
  paste directly into their zsh prompt; lower token use; a consistent,
  predictable driver-first UX.
- **Negative:** Slightly more conservative command syntax, and an extra shell
  check in the rare cases where behavior genuinely depends on the shell.

## Related

- ADR-016: Avoid bundling Python in the plugin (portability of host tooling)
- ADR-066 / ADR-091: drivers are `#!/bin/bash` scripts invoked via `bash <path>`
- Project `CLAUDE.md` macOS/zsh and bash-3.2 constraints
