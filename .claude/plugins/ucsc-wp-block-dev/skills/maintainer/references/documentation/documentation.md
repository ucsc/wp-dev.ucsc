# Documentation

Regenerate portable Markdown documentation for the `ucsc-wp-block-dev` plugin.
This maintainer reference prepares files that can be pasted or imported into
Google Docs or Confluence. It does not publish or upload anything.

## Universal Command Intake

Apply ADR-011: resolve the documentation request, optional target, and optional
Jira key/URL from the full input and session context. Ask one concise question
only when the requested artifact is ambiguous and regenerating both artifacts
would be inappropriate.

## Artifacts

The generated files live under `assets/`:

- `assets/ucsc_wp_block_dev_main.md` — main plugin guide generated from
  `README.md`.
- `assets/ucsc_wp_block_dev_presentation.md` — portable Markdown copy of the
  maintainer-owned slide deck source.

## Regenerate

Run the script from the repository root:

```bash
bash .claude/plugins/ucsc-wp-block-dev/skills/maintainer/references/documentation/scripts/regenerate.sh
```

The script reads:

- `.claude/plugins/ucsc-wp-block-dev/README.md`
- `.claude/plugins/ucsc-wp-block-dev/skills/maintainer/assets/ucsc_wp_block_dev_presentation.md`

It writes the two generated Markdown artifacts under
`skills/maintainer/references/documentation/assets/` and refreshes
generated-date metadata. Treat the maintainer slide deck as canonical; do not
edit the generated presentation copy directly.

## After Regeneration

1. Review the generated files for obvious formatting issues.
2. Run `maintainer check-references` because this reference owns a script and
   generated assets.
3. If top-level skills changed, update `README.md`, `AGENTS.md`,
   `skills/map/SKILL.md`, the maintainer slide deck, and the API signature
   before regenerating the artifacts.

Use `maintainer publish-slides` only when the user explicitly asks to publish
the canonical slide deck to Google Docs.
