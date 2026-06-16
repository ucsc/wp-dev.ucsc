---
name: maintainer
description: Maintain the ucsc-wp-block-dev plugin itself — validate structure, run tests, review or promote contributed skills, verify ADR consistency, review skills, and publish the maintainer-owned slide deck. Use for plugin health checks, contribution review, slide publishing, or release readiness.
---

# Maintainer — ucsc-wp-block-dev

Maintenance workflow for the `ucsc-wp-block-dev` plugin (not for block code —
use `develop`/`fix`/`run` for that). For Markdown artifact regeneration, read
[`references/generate-docs/generate-docs.md`](references/generate-docs/generate-docs.md).

Use this skill with one operation: `validate`, `test`, `review-skills`,
`review-contrib`, `promote-contrib`, `check-references`, `generate-docs`,
`publish-slides`, or `all`. Run all commands below from the repo root.

Keep token use low: run the validator and tests rather than reading every file by hand. See ADR-003.

## Universal Command Intake

Apply ADR-011: resolve the plugin target, natural-language maintenance request, and optional Jira key/URL from the full input and session context.

Per ADR-020, when the user enters maintainer mode **without an explicit operation** (a bare `maintainer`), do **not** launch into `validate`, `review-skills`, or any plugin-dev agent. First prompt the user for what to do, offering the available operations as options: `validate`, `test`, `review-skills`, `review-contrib`, `promote-contrib`, `check-references`, `generate-docs`, `publish-slides`, and `all`. Run the chosen operation only after they pick. When the user already named an operation (e.g. `maintainer test`), honor it directly without prompting. Once an operation is running, ask one concise question only when missing or conflicting information prevents useful work.

## Anthropic plugin-dev tools

These are the built-in `plugin-dev:*` agents and skills available for delegating maintenance work. Install the plugin-dev plugin if not already present:

```text
/plugin install plugin-dev@claude-plugins-official
```

| Tool | Type | Purpose |
|---|---|---|
| `plugin-dev:plugin-validator` | Agent | Validates plugin manifest, skill frontmatter, naming, structure, and security |
| `plugin-dev:skill-reviewer` | Agent | Reviews skill quality — description clarity, triggering effectiveness, best practices |
| `plugin-dev:skill-development` | Skill | Guidance for writing and improving skills — frontmatter fields, description patterns, argument handling |
| `plugin-dev:plugin-structure` | Skill | Plugin directory layout, manifest configuration, component organization |

## validate

Launch the `plugin-dev:plugin-validator` agent against this plugin to check the manifest, skill frontmatter, naming, structure, and security.

Use the Agent tool:

- `subagent_type`: `plugin-dev:plugin-validator`
- `prompt`: "Validate the Claude Code plugin at `.claude/plugins/ucsc-wp-block-dev`. Report critical errors, warnings, and overall quality."

Relay only the findings that matter; fix critical errors before publishing.

## test

Run the bundled pytest suite (manifest validity, skill frontmatter, ADR index consistency, file layout).

If `pytest` is installed globally:

```bash
cd .claude/plugins/ucsc-wp-block-dev && python3 -m pytest -q
```

Or using the virtual environment:

```bash
cd .claude/plugins/ucsc-wp-block-dev && ../ucsc-wp-block-dev-venv/bin/pytest -q
```

Some tests skip gracefully when the `claude` CLI is unavailable — that is expected in CI.

## review-skills

Launch the `plugin-dev:skill-reviewer` agent to audit skill quality, description effectiveness, and best-practice adherence after creating or modifying any `SKILL.md`.

Use the Agent tool:

- `subagent_type`: `plugin-dev:skill-reviewer`
- `prompt`: "Review the skills in the Claude Code plugin at `.claude/plugins/ucsc-wp-block-dev`. Check quality, description triggering effectiveness, and best practices."

Relay actionable findings; fix description or frontmatter issues before publishing.

## skill-development

When creating or modifying skills, invoke the `plugin-dev:skill-development` skill for guidance on skill structure, frontmatter conventions, description writing, and best practices.

Use the Skill tool:

- `skill`: `plugin-dev:skill-development`

Consult this before writing a new `SKILL.md` or refactoring an existing one to ensure correct frontmatter fields, argument patterns, and triggering descriptions.

## review-contrib

Review a proposal under `contrib/proposals/` or a candidate under
`contrib/incubator/`. Require the candidate name when it is not clear from the
request. Read `contrib/README.md` before reviewing.

For a proposal:

1. Check that it follows `contrib/proposals/TEMPLATE.md`.
2. Compare its triggers and workflow with existing production skills.
3. Check that the scope is specific to UCSC WordPress block development.
4. Return one decision: `reject`, `revise`, or `incubate`, with concise reasons.
5. For `incubate`, create `contrib/incubator/<skill-name>/SKILL.md` from
   `contrib/incubator/TEMPLATE.md`, carrying forward the accepted proposal
   details. Keep the original proposal until promotion for review history.

For an incubator candidate:

1. Apply the `skill-development` guidance.
2. Check trigger clarity, workflow completeness, overlap, security, support-file
   references, tests, and realistic examples.
3. Return one decision: `revise` or `promote`, with remaining work listed.

Do not place a candidate under `skills/` during review.

## promote-contrib

Promote a named directory from `contrib/incubator/<skill-name>/` into
`skills/<skill-name>/`. Read `contrib/README.md` and apply the
`skill-development` guidance first.

Before moving files:

1. Confirm no production skill has the same name or substantially overlapping
   triggers.
2. Confirm the directory name matches the frontmatter `name`.
3. Confirm the description clearly states behavior and trigger context.
4. Confirm every support file is linked from `SKILL.md`.
5. Run focused candidate tests or examples.

After moving files:

1. Update `README.md`, `AGENTS.md`, `map/SKILL.md`, and the maintainer slide
   deck when the new skill changes those inventories.
2. Add or update structural tests for the supported skill surface.
3. Run `test`, `validate`, `check-references`, and `review-skills`.
4. Remove the corresponding proposal only after the promotion checks pass.

If any check fails, leave the candidate in `contrib/incubator/` and report the
required revisions.

## check-references

Enforce ADR-032: every supporting file under a skill directory must be referenced from that skill's `SKILL.md`, so nested `references/`, `assets/`, and `scripts/` files stay discoverable (progressive disclosure). Run the bundled scanner:

```bash
bash .claude/plugins/ucsc-wp-block-dev/skills/maintainer/scripts/check_skill_references.sh
```

It prints one line per skill and a PASS/FAIL summary, exiting non-zero when any nested file is not linked from its `SKILL.md`. Fix a FAIL by adding a skill-relative reference (e.g. `references/foo.md`) to the skill — under a "Reference files" heading when one is warranted — or by removing the obsolete file. The pytest suite runs this same check, so a gap fails `test` too.

## generate-docs

Regenerate portable Markdown documentation artifacts for Google Docs or
Confluence. Read
[`references/generate-docs/generate-docs.md`](references/generate-docs/generate-docs.md),
then run:

```bash
bash .claude/plugins/ucsc-wp-block-dev/skills/maintainer/references/generate-docs/scripts/regenerate.sh
```

This writes generated artifacts under
`skills/maintainer/references/generate-docs/assets/`, including
[`references/generate-docs/assets/ucsc_wp_block_dev_main.md`](references/generate-docs/assets/ucsc_wp_block_dev_main.md)
and
[`references/generate-docs/assets/ucsc_wp_block_dev_presentation.md`](references/generate-docs/assets/ucsc_wp_block_dev_presentation.md).
It does not publish or upload anything.

## publish-slides

The canonical Marp source is maintainer-owned:

`skills/maintainer/assets/ucsc_wp_block_dev_presentation.md`

**Fast path:** `bash .claude/plugins/ucsc-wp-block-dev/skills/maintainer/scripts/refresh_and_publish_slides.sh` bumps the `Generated:` date to today, runs the deck-contract tests, then publishes — in one token-frugal call. Pass `--no-publish` to refresh and test without uploading. The numbered steps below are what it automates and what to reconcile when deck content has drifted.

Before publishing:

1. Compare the deck's skill inventory with every top-level directory under `skills/`.
2. Compare its skill map with `map/SKILL.md`.
3. Compare its ADR summary with `docs/adr/index.md`.
4. Refresh the title slide's `Generated:` value to the current date.
5. Run the plugin tests, which enforce the deck path and inventory contract.

Publish the verified source to the existing Google Doc:

```bash
python3 .claude/scripts/publish_to_gdoc.py --doc "https://docs.google.com/document/d/18Ozi1BJ60eH2_-mX5rpA08YsLtFwUAHC0nMErhsCxwo/edit"
```

The publisher reads only the maintainer asset path. Do not restore a second deck at the repository root (ADR-018).

## all

Run `test` first (fast, deterministic), then `validate`, then `check-references`, then `review-skills`. Publishing remains explicit through `publish-slides`. Report a single combined summary.

Contribution candidates are intentionally excluded from `all`; run
`review-contrib <candidate>` explicitly because proposals and incubator skills
may be incomplete.

## When the manifest or skills change

After editing `plugin.json`, any `SKILL.md`, or adding components, run `validate` to catch structure regressions, `check-references` to catch unreferenced support files, and `review-skills` to catch description and quality issues early. Use `skill-development` for guidance when writing new skills. When the main guide or deck should be prepared for Google Docs or Confluence without publishing, use the `generate-docs` operation in this skill.
