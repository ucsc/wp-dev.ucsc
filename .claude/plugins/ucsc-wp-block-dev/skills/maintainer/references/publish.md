# Publish workflow

implements: ADR-063-MAINTAINER-PUBLISH, ADR-018-MAINTAINER-SLIDE-DECK, ADR-015-MAINTAINER-SLIDE-DATE, ADR-107-MAINTAINER-DOCS-MODE-CONSOLIDATION

Full workflow for publishing the maintainer docs. Per ADR-107, publishing is the
optional final step of the `docs` mode: invoke it as `docs publish`. The
top-level `publish` mode remains a legacy alias for `docs publish`. The
`## docs` section in `SKILL.md` is the lean dispatch stub; this file is the
operational detail.

Per ADR-063, **bare `docs publish` (or `publish`) publishes both**, in this
order: slides, then guide. A specific output is named only to publish it alone:
`docs publish guide` (the prose docs) or `docs publish slides`. `deck` remains a
compatibility alias for `slides`. Publishing is always explicit and is never
part of the `all` health-check mode. Legacy aliases include `publish slides`
and `publish all`.

## Hardened publisher

Use the bundled orchestrator for all new publishing flows:

```bash
# Bare docs publish: validate everything, then publish slides and guide.
bash "${CLAUDE_PLUGIN_ROOT}/skills/maintainer/scripts/publish-docs.sh" \
  --target both --confirm

# Full local preflight with no Google Docs writes.
bash "${CLAUDE_PLUGIN_ROOT}/skills/maintainer/scripts/publish-docs.sh" --dry-run
```

The orchestrator:

1. Loads and validates environment-configured Google Doc URLs, then verifies the local publisher, credentials, and Python
   dependencies.
2. Refreshes and tests every selected output with uploads disabled.
3. Runs reference and freshness checks before any external write.
4. Publishes slides first, then guide, keeping separate logs.
5. Stops the guide upload when slides fail and reports `BLOCKED`, avoiding a
   misleading partial-success result.

`--confirm` is required for external writes. Use `--target guide` or
`--target slides` only when intentionally publishing one output.

## Destination configuration

Real Google Doc URLs are private operator configuration and are never committed
to this plugin. Add them to the gitignored project-root `.env`:

```dotenv
UCSC_WP_BLOCK_DEV_SLIDES_DOC_URL=https://docs.google.com/document/d/<SLIDES_DOCUMENT_ID>/edit
UCSC_WP_BLOCK_DEV_GUIDE_DOC_URL=https://docs.google.com/document/d/<GUIDE_DOCUMENT_ID>/edit
```

The scripts load that file automatically. Set
`UCSC_WP_BLOCK_DEV_ENV_FILE=/absolute/path/to/private.env` before invoking a
publisher to use a different file. Existing exported environment variables also
work and are overridden only when the selected env file defines the same name.

The URL selects the destination; it does not grant access. Authentication is
provided separately by `.claude/scripts/service_account.json`,
`.claude/scripts/credentials.json`, `.claude/scripts/token.json`, or Google
Application Default Credentials. These credential files must remain untracked,
and the authenticated identity must have edit access to the configured docs.

If a selected destination variable is absent or malformed, the publisher exits
before any upload and prints the variable name, expected URL form, and README
section to consult. `--no-publish` refresh operations need no destination URLs.

## publish slides

(Compatibility target: `docs publish deck`.)

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

Publish the verified deck to the configured Google Doc:

```bash
python3 .claude/scripts/publish_to_gdoc.py --doc "$UCSC_WP_BLOCK_DEV_SLIDES_DOC_URL"
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

The guide's destination comes from `UCSC_WP_BLOCK_DEV_GUIDE_DOC_URL`; until it
is configured the script refuses to upload. The underlying publisher accepts an
explicit source:

```bash
python3 .claude/scripts/publish_to_gdoc.py \
  --source skills/maintainer/references/generate-docs-main.md \
  --doc "$UCSC_WP_BLOCK_DEV_GUIDE_DOC_URL"
```

## publish (both)

Bare `docs publish` runs the hardened `publish-docs.sh --target both --confirm`
orchestrator. The top-level bare `publish` and `publish all` compatibility forms
do the same.
