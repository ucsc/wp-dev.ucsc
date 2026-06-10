---
name: maintainer
description: Maintain the ucsc-wp-block-dev plugin itself — validate structure, run tests, verify ADR consistency, review skills, and publish the maintainer-owned slide deck. Use for plugin health checks, slide publishing, or release readiness.
argument-hint: "[target | maintenance request | Jira key/URL]"
arguments: [input]
---

# Maintainer — ucsc-wp-block-dev

Maintenance workflow for the `ucsc-wp-block-dev` plugin (not for block code — use `develop`/`fix`/`run` for that).

**Usage:** `/ucsc-wp-block-dev:maintainer [validate | test | review-skills | publish-slides | all]`. Run all commands below from the repo root.

Keep token use low: run the validator and tests rather than reading every file by hand. See ADR-003.

## Universal Command Intake

Apply ADR-011: resolve the plugin target, natural-language maintenance request, and optional Jira key/URL from the full input and session context.

Per ADR-020, when the user enters maintainer mode **without an explicit operation** (a bare `maintainer`), do **not** launch into `validate`, `review-skills`, or any plugin-dev agent. First prompt the user for what to do, offering the available operations as options: `validate`, `test`, `review-skills`, `publish-slides`, and `all`. Run the chosen operation only after they pick. When the user already named an operation (e.g. `maintainer test`), honor it directly without prompting. Once an operation is running, ask one concise question only when missing or conflicting information prevents useful work.

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

## publish-slides

The canonical Marp source is maintainer-owned:

`skills/maintainer/assets/ucsc_wp_block_dev_presentation.md`

Before publishing:

1. Compare the deck's skill inventory with every top-level directory under `skills/`.
2. Compare its command table with the modes in `start/SKILL.md` and `menu/SKILL.md`.
3. Compare its ADR summary with `docs/adr/index.md`.
4. Refresh the title slide's `Generated:` value to the current date.
5. Run the plugin tests, which enforce the deck path and inventory contract.

Publish the verified source to the existing Google Doc:

```bash
python3 .claude/scripts/publish_to_gdoc.py --doc "https://docs.google.com/document/d/18Ozi1BJ60eH2_-mX5rpA08YsLtFwUAHC0nMErhsCxwo/edit"
```

The publisher reads only the maintainer asset path. Do not restore a second deck at the repository root (ADR-018).

## all

Run `test` first (fast, deterministic), then `validate`, then `review-skills`. Publishing remains explicit through `publish-slides`. Report a single combined summary.

## When the manifest or skills change

After editing `plugin.json`, any `SKILL.md`, or adding components, run `validate` to catch structure regressions and `review-skills` to catch description and quality issues early. Use `skill-development` for guidance when writing new skills.
