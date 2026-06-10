---
name: maintainer
description: Maintain the ucsc-wp-block-dev plugin itself — validate structure, run the test suite, and verify ADR index consistency. Use when asked to validate, lint, or health-check this plugin, after editing skills or the manifest, or before publishing a new version.
argument-hint: "[target | maintenance request | Jira key/URL]"
arguments: [input]
---

# Maintainer — ucsc-wp-block-dev

Maintenance workflow for the `ucsc-wp-block-dev` plugin (not for block code — use `develop`/`fix`/`run` for that).

**Usage:** `/ucsc-wp-block-dev:maintainer [validate | test | all]`. Run all commands below from the repo root — the validate prompt path and the test `cd` are both relative to it.

Keep token use low: run the validator and tests rather than reading every file by hand. See ADR-003.

## Universal Command Intake

Apply ADR-011: resolve the plugin target, natural-language maintenance request, and optional Jira key/URL from the full input and session context. A bare `maintainer` command implies the `all` health check. Ask one concise question only when the requested scope is ambiguous enough to change the operation.

## Anthropic plugin-dev tools

These are the built-in `plugin-dev:*` agents and skills available for delegating maintenance work. Install the plugin-dev plugin if not already present:

```
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

## all

Run `test` first (fast, deterministic), then `validate`, then `review-skills`. Report a single combined summary.

## When the manifest or skills change

After editing `plugin.json`, any `SKILL.md`, or adding components, run `validate` to catch structure regressions and `review-skills` to catch description and quality issues early. Use `skill-development` for guidance when writing new skills.
