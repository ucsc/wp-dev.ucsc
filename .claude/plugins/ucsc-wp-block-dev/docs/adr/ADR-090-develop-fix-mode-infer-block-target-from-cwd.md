---
title: "ADR-090: Infer block target from CWD"
status: Accepted
date: 2026-06-22
---

# ADR-090: Infer block target from CWD

## Status

Accepted

## Context

[ADR-084](ADR-084-develop-select-block-target-workflow.md) made selecting a block target
the primary workflow and directed target-aware skills (`develop`,
`develop/feature`, `develop/fix`, `verify`, `validate`) to **prompt** for the
target early "rather than guessing" when it is not unambiguously provided.

In practice the prompt fires even when the working directory already identifies
the target. For example, invoking `develop fix` from
`public/wp-content/plugins/ucsc-blocks/src/blocks/ucsc-events` still asks "which
block?", even though the path unambiguously names `ucsc-events`. That is
redundant friction and contradicts the low-token, low-back-and-forth goal that
motivated ADR-084 in the first place.

## Decision

Refine ADR-084's intake contract: a target-aware skill must **attempt to infer
the block target from the current working directory before prompting**, when the
target is not explicitly supplied.

- Inference walks up from the CWD looking for a recognizable block-source path
  (e.g. a `.../src/blocks/<slug>` segment, or a directory matching a canonical
  slug in `develop/references/targets.md`).
- When inference yields exactly one confident match, the skill adopts it as the
  session target and states the inferred target so the user can correct it,
  rather than blocking on a prompt.
- When inference is ambiguous (multiple candidates) or yields nothing, the skill
  falls back to the ADR-084 selection prompt.
- Explicitly supplied targets (argument, environment, or a named slug in the
  request) always win over inference. Programmatic/driver invocations still
  require an explicit target and fail fast without one.

This amends, and does not revoke, ADR-084: selection remains the contract; CWD
inference is the preferred way to satisfy it before falling back to a prompt.

## Consequences

- **Positive:** Removes redundant target prompts when the CWD already names the
  block; lowers tokens and friction; keeps a single authoritative session
  target; preserves ADR-084's determinism because an inferred target is stated
  and overridable.
- **Negative:** Adds an inference step (bounded CWD path inspection) and a small
  risk of a wrong-but-confident guess; mitigated by always announcing the
  inferred target and by falling back to the prompt whenever inference is
  ambiguous.
