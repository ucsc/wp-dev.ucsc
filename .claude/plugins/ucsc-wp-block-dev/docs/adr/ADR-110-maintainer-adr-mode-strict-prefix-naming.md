---
title: "ADR-110: Strict ADR filename prefix and lightweight retirement"
status: Accepted
date: 2026-06-29
related: ["ADR-086"]
---

# ADR-110: Strict ADR filename prefix and lightweight retirement

## Status

Accepted

## Context

ADR filenames follow `ADR-NNN-<slug>.md` but there is no enforced rule about
what the first segment after the number must be. Over time, ADRs have
accumulated with inconsistent prefixes — some use the skill name, some use a
general description, and some use a mode name directly. Without a strict
convention, it is hard to scan which skill owns an ADR or whether an ADR is
plugin-wide.

Separately, when ADRs are retired (Superseded, Deprecated, or Rejected), the
current practice of keeping full files in `docs/adr/retired/` creates clutter
and leaves broken prose references in skill files that referenced the old number.

## Decision

### A. Strict prefix format

Every ADR filename must follow one of these forms:

| Case | Format | Example |
|---|---|---|
| Skill-wide decision | `ADR-NNN-<skill>-<detail>.md` | `ADR-003-maintainer-low-token-use.md` |
| Mode-specific decision | `ADR-NNN-<skill>-<mode>-mode-<detail>.md` | `ADR-026-develop-fix-mode-token-reduction.md` |
| Plugin-wide (cross-cutting) | `ADR-NNN-plugin-<detail>.md` or `ADR-NNN-maintainer-<detail>.md` | (use `maintainer` as the governance skill) |

`<skill>` must be one of the plugin's live skill names: `develop`, `feedback`,
`hub`, `maintainer`, `review`, `run`, `validate`, `verify`. Plugin-wide
decisions that span all skills default to the `maintainer` prefix because
`maintainer` is the governance skill; `plugin` is accepted as an alternative
for decisions with no single owning skill.

### B. Lightweight retirement

When an ADR is retired (Superseded, Deprecated, or Rejected):

1. Add a one-line entry to `docs/adr/adrs_retired.md`:
   `| ADR-NNN | Title | Superseded by ADR-MMM | YYYY-MM-DD |`
2. Remove the full ADR file from `docs/adr/`. Do not move it to `retired/`.
3. Update every prose reference to `ADR-NNN` in skill files to cite the
   surviving ADR instead.

The `retired/` subdirectory is a legacy artifact from before this ADR; do not
add new files there. Existing files in `retired/` may remain until the prose
references that cite them are updated.

## Consequences

- **Positive:** Scanning `docs/adr/` immediately reveals which skill owns each
  ADR and whether it is mode-specific.
- **Positive:** Retirement is a one-liner with no orphaned files and no broken
  prose references.
- **Positive:** The `test_adr_filenames_use_current_convention` test can be
  tightened to check the prefix is a known skill name.
- **Negative:** Existing ADRs in `retired/` are a temporary inconsistency until
  their prose references are updated.
- **Negative:** Requires updating prose in skill files when retiring, not just
  moving a file.
