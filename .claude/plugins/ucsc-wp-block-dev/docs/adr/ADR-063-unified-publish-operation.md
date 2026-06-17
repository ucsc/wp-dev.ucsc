---
title: "ADR-063: Unify publishing into a publish operation with slides/docs/all targets"
status: Accepted
date: 2026-06-16
---

# ADR-063: Unify publishing into a publish operation with slides/docs/all targets

## Status

Accepted

## Context

`generate-docs` produces two portable artifacts — the prose guide
(`ucsc_wp_block_dev_main.md`, derived from `README.md`) and a deck copy
(`ucsc_wp_block_dev_presentation.md`). However, the maintainer skill only
exposed a `publish-slides` operation, which publishes the canonical **deck** to
a Google Doc. The generated **prose guide was never publishable** — an
asymmetry between what we generate and what we can publish.

The publisher `publish_to_gdoc.py` also hardcoded the deck as its only source.

## Decision

Replace the single-purpose `publish-slides` operation with one `publish`
operation that takes a target:

- `publish slides` — publish the canonical maintainer deck (unchanged behavior).
- `publish docs` — regenerate and publish the prose guide
  (`ucsc_wp_block_dev_main.md`) to its own Google Doc.
- `publish all` — both.

Supporting changes:

1. `publish_to_gdoc.py` accepts `--source <markdown>` (defaulting to the deck
   for back-compat), so the same publisher serves both artifacts.
2. Each target keeps a focused token-frugal fast-path script
   (`refresh_and_publish_slides.sh`, `refresh_and_publish_docs.sh`).
3. Each target has its own destination Google Doc URL.

This supersedes the `publish-slides` operation named in ADR-018. ADR-018's
decision that the maintainer skill **owns the canonical deck** still stands;
only the operation surface changes.

## Consequences

- **Positive:** The generated prose guide can now be published, closing the
  generate→publish loop; one mental model (`publish <target>`) for all outputs.
- **Positive:** The publisher is reusable for any markdown source.
- **Negative:** `publish-slides` is renamed; references in README, the deck,
  `generate-docs.md`, and ADR-020's operation list are updated to `publish`.
- Publishing remains explicit and is excluded from `all` (ADR unchanged).
