# Docs mode (regenerate, check, publish)

Operational reference for the maintainer `docs` mode (legacy alias
`generate-docs`). `docs` prepares portable Markdown for the `ucsc-wp-block-dev`
plugin that can be pasted or imported into Google Docs or Confluence. The bare
`docs` run regenerates artifacts and does not publish or upload anything;
publishing is the optional final step (`docs publish`, see below).

`docs` has three forms:

- `docs` — regenerate the guide and deck artifacts and stamp a source hash.
- `docs check` — report-only staleness check (no writes); see *Staleness detection*.
- `docs publish [guide|slides]` — publish both by default, or name one output;
  see *Publishing*.

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
- `.claude/plugins/ucsc-wp-block-dev/.claude-plugin/plugin.json`
- `.claude/plugins/ucsc-wp-block-dev/skills/maintainer/assets/ucsc-wp-block-dev-presentation.md`
- `.claude/plugins/ucsc-wp-block-dev/docs/adr/index.md` and referenced ADRs,
  as source-of-truth context for documentation scope, policy, and roadmap
  themes.

It writes the two generated Markdown artifacts under
`skills/maintainer/references/`, refreshes generated-date metadata, and stamps a
`source-hash` (see below). The guide begins with visible generated date, plugin
version, and Git commit metadata; the full commit is also recorded in its YAML
frontmatter. Treat the maintainer slide deck as canonical; do not edit the
generated presentation copy directly.

## Staleness detection

Regeneration is on demand only, so the generated artifacts can silently drift
behind their sources. To detect this without re-reading every file, the script
stamps a **source hash** into the generated guide's frontmatter
(`source-hash:`) and the deck's header comment. The hash is computed with
`git hash-object` over exactly the bytes the script copies into the artifacts —
`README.md`, `plugin.json`, and the canonical deck source — so a
committed-but-unregenerated source or version change is still caught (it is
independent of working-tree state). When `git` is unavailable the script falls
back to `shasum`.

Run the report-only check (writes nothing):

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/maintainer/scripts/regenerate-docs.sh" --check
```

It prints `FRESH` (exit 0) when the stored hash matches the current sources, or
`STALE` (exit 3) when the sources changed or no artifact exists yet — meaning a
plain `docs` run is needed. ADR narrative reconciliation (below) is a manual
step and is deliberately excluded from the hash so the docs are not reported
stale on every ADR edit.

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

## Publishing

Publishing is the optional final step of `docs`, never automatic. Use
`maintainer docs publish` to publish both slides and guide by default. Use
`docs publish guide` or `docs publish slides` only for a single output; `deck`
is accepted as an alias for `slides`. `maintainer publish` remains a legacy alias. See
[`publish.md`](publish.md) for the full publish workflow.
