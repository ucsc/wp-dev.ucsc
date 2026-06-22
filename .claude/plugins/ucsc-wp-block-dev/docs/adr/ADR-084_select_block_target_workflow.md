---
title: "ADR-084: Make selecting a block target the primary workflow"
status: Accepted
date: 2026-06-18
---

# ADR-084: Make selecting a block target the primary workflow

> Amended by [ADR-090](ADR-090_develop_fix_infer_block_target_from_cwd.md):
> skills infer the block target from the current working directory before
> falling back to the selection prompt described here.

## Context

Working with ucsc-gutenberg-blocks commonly begins with the developer or maintainer identifying which block (or block surface) they intend to change, verify, or test. Many skills (develop, fix, verify, test, survey) operate on a specific block target and currently rely on ad-hoc intake patterns to determine that target.

Because skills must be token-efficient and deterministic, normalizing how callers select and declare the intended block target reduces back-and-forth clarification, avoids unnecessary file inspection, and scopes downstream operations (build, verify, test) to a small, predictable set of files and runtime checks.

## Decision

Adopt a standard intake contract across skills that operate on block code or runtime surfaces:

- Every skill that modifies, verifies, or reports on blocks (develop, develop/feature, develop/fix, verify, test, survey) must prompt the user to select a block target early in the Universal Command Intake flow when the target is not unambiguously provided.

- The selection mechanism shall present the user with:
  1. A short list of canonical block slugs (from develop/references/targets.md) when available for the repo, and
  2. A freeform "other" option allowing a slug or file path when the desired block is not listed.

- Skills must treat the chosen block target as authoritative for the session and limit file reads, builds, and verification steps to the files and assets associated with that target.

- When a skill is invoked programmatically (e.g., from a script, CI, or driver), the target must be supplied by argument or environment value; failing that, the skill will fail fast with a clear message requesting the target.

- Maintain a canonical per-repo targets index at `skills/develop/references/targets.md` and keep target-specific references under `skills/develop/references/target-<slug>.md`.

## Consequences

- Positive:
  - Reduces token usage and unnecessary disk or network reads by scoping operations up-front.
  - Makes skill behavior predictable and easier to test (`verify` and `test` drivers can be targeted deterministically).
  - Encourages a single UX pattern across skills, simplifying documentation and onboarding.

- Negative / Tradeoffs:
  - Requires maintainers to keep the targets index up-to-date; adding new blocks requires updating `targets.md` and a `target-<slug>.md` reference.
  - Increases upfront friction for ad-hoc exploratory prompts (the skill will ask for the target rather than guessing). This is intentional to avoid accidental wide-scope actions.

## Implementation notes

- Implement the intake prompt as part of ADR-011's Universal Command Intake: if target ambiguous, ask one concise question that offers the canonical list plus an "Other" choice.
- Add CI checks (maintainer `check-references`) to ensure each `target-*.md` is listed in `targets.md` (existing tests already enforce this pattern).
- Update driver and verify scripts to accept an explicit `BLOCK_TARGET` variable for unattended runs.

## Related

- ADR-011: Universal command intake
- ADR-032: Skill support file referencing
- develop/references/targets.md (canonical per-repo target index)

