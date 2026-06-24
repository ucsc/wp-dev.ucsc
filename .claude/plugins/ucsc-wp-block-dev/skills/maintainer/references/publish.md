# Publish workflow

implements: ADR-063-MAINTAINER-PUBLISH, ADR-018-MAINTAINER-SLIDE-DECK, ADR-015-MAINTAINER-SLIDE-DATE

Full workflow for the maintainer `publish` mode. The `## publish` section in
`SKILL.md` is the lean dispatch stub; this file is the operational detail.

Per ADR-063, **bare `publish` publishes both** the guide and the deck. A specific
output is named: `guide` (the prose docs) or `deck` (the slides). Publishing is
always explicit and is never part of the `all` health-check mode. Legacy aliases:
`docs` = `guide`, `slides` = `deck`, and `all` = both.

## publish deck

(Legacy alias: `publish slides`.)

The canonical Marp source is maintainer-owned:

`skills/maintainer/assets/ucsc-wp-block-dev-presentation.md`

**Fast path:** `bash "${CLAUDE_PLUGIN_ROOT}/skills/maintainer/scripts/refresh-and-publish-slides.sh"`
bumps the `Generated:` date to today, runs the deck-contract tests, then
publishes — in one token-frugal call. Pass `--no-publish` to refresh and test
without uploading. The numbered steps below are what it automates and what to
reconcile when deck content has drifted.

Before publishing:

1. Compare the deck's skill inventory with every top-level directory under `skills/`.
2. Compare its ADR summary with `docs/adr/index.md`.
3. Refresh the title slide's `Generated:` value to the current date.
4. Run the plugin tests, which enforce the deck path and inventory contract.

Publish the verified deck to the existing Google Doc:

```bash
python3 .claude/scripts/publish_to_gdoc.py --doc "https://docs.google.com/document/d/1Qj8bnNorBnD_ChbKD4BDLzBNFmTeqOArbrepNQh2Elw/edit"
```

Do not restore a second deck at the repository root (ADR-018).

## publish guide

(Legacy alias: `publish docs`.)

Publishes the generated prose guide
`skills/maintainer/references/generate-docs-main.md`
(derived from `README.md` via `generate-docs`) to its own Google Doc.

**Fast path:** `bash "${CLAUDE_PLUGIN_ROOT}/skills/maintainer/scripts/refresh-and-publish-docs.sh"`
regenerates the artifacts, runs the generate-docs contract tests, then
publishes. Pass `--no-publish` to refresh and test without uploading.

The guide's destination Google Doc URL must be set in `GDOC_URL` inside
`refresh-and-publish-docs.sh` before first publish; until then the script refuses
to upload. The underlying publisher accepts an explicit source:

```bash
python3 .claude/scripts/publish_to_gdoc.py \
  --source skills/maintainer/references/generate-docs-main.md \
  --doc "https://docs.google.com/document/d/18Ozi1BJ60eH2_-mX5rpA08YsLtFwUAHC0nMErhsCxwo/edit"
```

## publish (both)

Bare `publish` runs `publish deck` then `publish guide`. (Legacy alias:
`publish all`.)
