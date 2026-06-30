---
title: "ADR-109: Cross-link guide and slides so readers can navigate between companion documents"
status: Accepted
date: 2026-06-26
---

# ADR-109: Cross-link guide and slides so readers can navigate between companion documents

## Context

The plugin produces two companion published documents:

- **Guide** — a Google Doc generated from `skills/maintainer/references/generate-docs-main.md`,
  published via `publish-docs.sh`. Intended for day-to-day install and use reference.
- **Slides** — a Google Doc rendered from the Marp deck at
  `skills/maintainer/assets/ucsc-wp-block-dev-presentation.md`, published via the same
  script. Intended as a guided tour of every skill.

Both documents already mention the other in prose but without a navigable link:

- The guide says: *"For a guided tour of every skill and the plugin's design, see the
  companion slide deck."*
- The slides say: *"For install and day-to-day use, see the companion Guide, not these
  slides."*

Because the Google Doc URLs (`SLIDES_DOC_URL`, `GUIDE_DOC_URL`) are environment-specific
and already resolved at publish time inside `publish-docs.sh`, they cannot be hardcoded
in the source Markdown without creating a maintenance hazard. The cross-link must
therefore be injected during the publish step, not stored in the source files.

## Decision

The publish script (`publish-docs.sh`) injects a cross-link into each document
immediately after publishing both outputs:

- After publishing the **guide**: replace the prose mention of the companion slide deck
  with a hyperlink to `SLIDES_DOC_URL`.
- After publishing the **slides**: replace the prose mention of the companion Guide with
  a hyperlink to `GUIDE_DOC_URL`.

Both documents already carry a consistent prose anchor that the script can target:

| Document | Prose anchor | Injected link target |
|---|---|---|
| Guide (`generate-docs-main.md`) | `see the companion slide deck` | `SLIDES_DOC_URL` |
| Slides (`ucsc-wp-block-dev-presentation.md`) | `see the companion **Guide**` | `GUIDE_DOC_URL` |

Rules:

1. Cross-link injection runs **only when both documents are published in the same
   `--target both` run**, so each link has a valid destination. Publishing a single
   target (`--target slides` or `--target guide`) skips injection and logs a notice.
2. The source Markdown files are **not modified** — injection is applied to the
   published Google Doc content via the existing `publish_to_gdoc.py` mechanism, not
   written back to disk.
3. The `--dry-run` flag suppresses injection (consistent with other publish-script
   dry-run behaviour).
4. A `--check` run of `regenerate-docs.sh` does not validate the injected links (the
   links live in the published docs, not the source), so no staleness check is needed.

## Consequences

- **Positive:** Readers of either document can navigate directly to the companion
  without searching; the two artifacts become self-referencing.
- **Positive:** The source Markdown files remain clean and URL-free; there is no
  hardcoded Google Doc URL to rotate if a document is re-created.
- **Negative:** Cross-links are only present after a `--target both` publish run;
  single-target publishes leave the prose mention unlinked. This is an acceptable
  trade-off — partial publishes are the exception, not the rule.
- **Negative:** Link injection requires a second API call per document (read-and-patch
  after write), adding a small latency cost to publish runs.
