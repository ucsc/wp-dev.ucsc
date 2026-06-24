# Generate Docs

Regenerate portable Markdown documentation for the `ucsc-wp-block-dev` plugin.
This maintainer reference prepares files that can be pasted or imported into
Google Docs or Confluence. It does not publish or upload anything.

## Universal Command Intake

Resolve the documentation request, optional target, and optional Jira key/URL
from the full input and session context. Ask one concise question only when the
requested artifact is ambiguous and regenerating both artifacts would be
inappropriate.

## Artifacts

The generated files live under `references/` (alongside this file):

- `generate-docs-main.md` — main plugin guide generated from `README.md`.
- `generate-docs-presentation.md` — portable Markdown copy of the
  maintainer-owned slide deck source.

## Regenerate

Run the script from the repository root:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/maintainer/scripts/regenerate-docs.sh"
```

The script reads:

- `.claude/plugins/ucsc-wp-block-dev/README.md`
- `.claude/plugins/ucsc-wp-block-dev/skills/maintainer/assets/ucsc-wp-block-dev-presentation.md`
- `.claude/plugins/ucsc-wp-block-dev/docs/adr/index.md` and referenced ADRs,
  as source-of-truth context for documentation scope, policy, and roadmap
  themes.

It writes the two generated Markdown artifacts under
`skills/maintainer/references/` and refreshes generated-date metadata. Treat
the maintainer slide deck as canonical; do not edit the generated presentation
copy directly.

## ADR-Derived Content

When refreshing the guide or deck, reconcile the narrative with the ADRs before
regenerating artifacts:

- The guide should reflect current accepted decisions and avoid presenting
  superseded ADR behavior as current.
- The slide deck should include a future roadmap slide that draws from ADRs
  marked as studies, open-ended maintenance decisions, or recently accepted
  direction-setting policies.
- Roadmap items should point to the ADR number when practical so readers can
  trace the rationale.

## After Regeneration

1. Review the generated files for obvious formatting issues.
2. Run `maintainer check-references` because this reference owns a script and
   generated assets.

Per ADR-045, regeneration is **on demand only**. A skill change does not require
or trigger a docs regeneration: when skills change, update the source-of-truth
inventories (`README.md`, `AGENTS.md`, the `hub` skill, the maintainer slide
deck, and the API signature) as part of that change, and regenerate these
derived artifacts separately only when the user explicitly asks.

Use `maintainer publish` (bare = both; or `guide`/`deck`) only when the user explicitly
asks to publish the canonical slide deck or the prose guide to Google Docs.
