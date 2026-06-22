---
title: "ADR-086: ADR and skill conventions (filename, combine-default, implements, launcher)"
status: Accepted
date: 2026-06-18
related: ["ADR-046", "ADR-020", "ADR-070", "ADR-065", "ADR-081"]
---

# ADR-086: ADR and skill conventions

## Status

Accepted

## Context

The ADR set and skill surface have grown quickly. Four conventions were requested
together to keep decisions traceable and skills consistent. Per the combine-default
established here, they are recorded as one ADR rather than four. This ADR owns
the filename convention and the migration of existing ADR files to that
convention.

## Decision

### A. Filename convention

ADRs use `ADR-NNNN_<skill>_<mode>_<detail>.md` — four-digit number,
underscore-separated, lowercase — naming the primary skill, mode
(sub-operation), and detail the decision applies to, e.g.
`ADR-086_maintainer_conventions.md`. Legacy hyphenated three-digit files are
renamed to the same four-digit underscore convention. `new_adr.sh` is updated
to emit the new format and to detect the highest ADR number across older and
current filename shapes so numbering stays correct during transition.

### B. Combine-default for new ADRs

When a new decision arises, default to extending the most relevant existing ADR.
Create a new ADR only when the user explicitly says "add", or when no existing ADR
is a reasonable home.

### C. `implements:` traceability marker

Each skill `SKILL.md` and each script declares which ADR(s) it implements:

- In `SKILL.md`: a body marker line `implements: ADR-086-MAINTAINER-CONVENTIONS, …`
  (under an `## Implements` heading). It is **not** placed in frontmatter, to keep
  frontmatter portable per ADR-070.
- In scripts (`.py`, `.sh`): a comment line `# implements: ADR-086-MAINTAINER-CONVENTIONS, …`.

The human-readable slug is `ADR-NNNN-SKILL-MODE` (uppercase, hyphenated); the
checker keys only on the leading ADR number, so it resolves current four-digit
ADR files and older three-digit references during migration.
`check_adr_implements.py` enforces consistency in both directions (see Rollout).

### D. Per-skill launcher + menu mode

Each skill provides a `launcher.md` describing what to do when the skill is invoked
via its slash command: if a mode was specified, run that mode; otherwise load
`skill-menu-mode.md` to present the available modes as a menu before acting
(formalizes the ADR-020 bare-invocation prompt). Piloted on `maintainer` first,
then rolled out per skill.

## Rollout

C and D are piloted on `maintainer` before wider rollout (one skill at a time).
`check_adr_implements.py` runs two checks:

1. **Reverse (hard gate):** every ADR referenced by an `implements:` marker must
   resolve to an existing, active ADR (status `Accepted`/`Proposed`, not
   `Superseded`/`Deprecated`/`Rejected`). Violations exit non-zero.
2. **Forward (coverage, advisory during rollout):** every active ADR should be
   implemented by at least one skill or script. Unimplemented ADRs are reported as
   warnings until the per-skill rollout completes, then promoted to a hard gate.

## Consequences

- **Positive:** ADR filenames advertise their skill, mode, and detail; skills and
  scripts trace back to decisions; coverage gaps and stale references are
  detectable by script.
- **Positive:** The combine-default slows ADR sprawl.
- **Negative:** Existing links and tests must be migrated when the filename
  convention changes; tooling tolerates older shapes only for transition.
- **Negative:** Until rollout completes, forward-coverage is advisory, so the
  "every ADR implemented" goal is not yet enforced.
