---
title: "ADR-107: docs mode consolidates generate-docs and publish with staleness detection"
status: Accepted
date: 2026-06-25
---

# ADR-107: docs mode consolidates generate-docs and publish with staleness detection

## Status

Accepted

## Context

Documentation work was split across two maintainer modes that always operated on
the same pair of artifacts (the prose guide and the slide deck): `generate-docs`
regenerated the portable Markdown, and a separate top-level `publish` mode
uploaded it to Google Docs. The publish step is conceptually the tail end of the
docs workflow — its operator name was even meant to read as "publish-docs" — so
two sibling top-level modes added surface area without adding a distinct concept.

Separately, regeneration is on-demand only (ADR-045): a skill or README change
does not trigger it. That makes it easy for the generated artifacts to drift
silently behind their sources, with no cheap way to tell whether a regeneration
is actually needed short of re-running it and diffing.

## Decision

1. **Rename the mode to `docs`.** `docs` is the single documentation mode.
   `generate-docs` remains an accepted legacy alias.
2. **Fold publish into `docs` as its optional final step.** Publishing is reached
   as `docs publish [guide|deck]` (bare = both). The top-level `publish` mode (and
   `publish docs`/`publish slides`) remains a legacy alias for `docs publish`.
   Publishing stays always-explicit and is never part of `all` (ADR-063 unchanged
   in substance).
3. **Add a git-hash staleness signal.** `regenerate-docs.sh` stamps a
   `source-hash` — computed with `git hash-object` over exactly the bytes it
   copies into the artifacts (`README.md` and the canonical deck source) — into
   the generated guide's frontmatter and the deck's header comment. A new
   `docs check` (`regenerate-docs.sh --check`) recomputes the hash and reports
   `FRESH` (exit 0) or `STALE` (exit 3) without writing. ADR narrative
   reconciliation is deliberately excluded from the hash so docs are not flagged
   stale on every ADR edit.

This ADR extends ADR-045 (docs is a maintainer reference), ADR-048 (ADR-derived
content) and ADR-063 (unified publish), which remain in force.

## Consequences

- **Positive:** one documentation mode instead of two; publish is discoverable as
  the natural last step of `docs`; staleness is detectable in one report-only
  command without re-reading sources by hand.
- **Positive:** non-breaking — `generate-docs`, `publish`, and the existing
  fast-path scripts continue to work as aliases.
- **Negative:** the generated artifact filenames remain `generate-docs-main.md` /
  `generate-docs-presentation.md` (kept to avoid churn across publish scripts and
  tests), so the artifact names no longer match the mode name.
- **Negative:** the source hash reflects only the copied bytes; drift in ADR
  narrative that should reshape the prose is not caught by `docs check` and still
  relies on the manual reconciliation step.
