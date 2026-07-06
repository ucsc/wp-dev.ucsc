---
name: maintainer
description: This skill should be used when the user asks to "maintain the plugin", "validate the plugin structure", "run the plugin self-tests", "review or promote a skill", "check ADR consistency", "study upstream plugin patterns", "publish the maintainer docs", or prepare ucsc-wp-block-dev for release.
version: 0.1.0
argument-hint: "[backlog|adr|skill|training|retro|self-test|validate|docs|all] [submode or target]"
disable-model-invocation: true
user-invocable: true
allowed-tools:
  - Read
  - Grep
  - Bash(bash:*)
  - Bash(docker:*)
  - Bash(wp:*)
  - Bash(jq:*)
  - Bash(python3:*)
---

# Maintainer — ucsc-wp-block-dev

<!-- doc-slide: Maintains the plugin itself — ADRs, skills, self-tests, docs, and release readiness; it never touches block code. -->

## Implements

implements: ADR-003-PLUGIN-LOW-TOKEN, ADR-004-MAINTAINER-VALIDATION, ADR-015-MAINTAINER-SLIDE-DATE, ADR-016-MAINTAINER-NO-BUNDLED-PYTHON, ADR-017-MAINTAINER-AGENTS-SYMLINKS, ADR-018-MAINTAINER-SLIDE-DECK, ADR-020-MAINTAINER-MENU, ADR-028-MAINTAINER-JIT-MCP, ADR-032-MAINTAINER-REFERENCE-CHECKS, ADR-033-MAINTAINER-WORKLIST, ADR-038-MAINTAINER-CONTRIB, ADR-045-MAINTAINER-GENERATE-DOCS, ADR-048-MAINTAINER-GENERATE-DOCS-ADRS, ADR-063-MAINTAINER-PUBLISH, ADR-067-MAINTAINER-SYNC-INVENTORY, ADR-070-MAINTAINER-FRONTMATTER, ADR-071-MAINTAINER-SKILL-DETAILS, ADR-072-MAINTAINER-SKILL-DISPLAY, ADR-076-MAINTAINER-TOKEN-LOG, ADR-078-MAINTAINER-CLI-VALIDATE, ADR-081-MAINTAINER-SUB-SKILLS, ADR-083-MAINTAINER-RETROSPECTIVE, ADR-085-MAINTAINER-TARGET, ADR-086-MAINTAINER-CONVENTIONS, ADR-089-MAINTAINER-PUBLIC-SLASH, ADR-099-MAINTAINER-RETRO-MODE-ORCHESTRATION-WRAPPER-SCRIPTS, ADR-106-MAINTAINER-GENERATE-DOCS-MODE-MARKER-DRIVEN-DOCUMENTATION, ADR-107-MAINTAINER-DOCS-MODE-CONSOLIDATION, ADR-109-MAINTAINER-CROSS-LINK-GUIDE-AND-SLIDES, ADR-110-MAINTAINER-ADR-MODE-STRICT-PREFIX-NAMING

This body marker traces the skill to the ADRs it implements (ADR-086, decision C).

Maintenance workflow for the `ucsc-wp-block-dev` plugin. Invoke as `maintainer`. Run all commands from the repo root.
Use this skill with one mode: `backlog`, `adr`, `skill`, `training`, `retro`, `self-test`, `validate`, `docs`, or `all`.

Keep token use low: run the validator and tests rather than reading every file by hand. See ADR-003.

## Universal Command Intake

Resolve the plugin target, natural-language maintenance request, and optional Jira key/URL from the full input and session context.
Per ADR-020, when the user enters maintainer mode without an explicit mode, first prompt the user for what to do. Present the durable modes first: `backlog`, `adr`, `skill`, `training`, and `retro`; then offer `self-test`, `validate`, `docs`, and `all`. Ask one concise question only when missing or conflicting information prevents useful work.

## Sub-workflows & Reference Files

- [references/maintainer-checklist.md](references/maintainer-checklist.md) — Reviewer checklist.
- [references/self-test.md](references/self-test.md) — Deterministic pytest and best-practices checker.
- [references/skill-visibility.md](references/skill-visibility.md) — Visibility reference.
- [references/generate-docs.md](references/generate-docs.md) — Artifact regeneration.
- [references/publish.md](references/publish.md) — Publication workflow.
- [references/adr-consolidation.md](references/adr-consolidation.md) — ADR management.
- [references/training.md](references/training.md) — Upstream study.
- [references/external-references.md](references/external-references.md) — Upstream truth links.
- [references/maintenance-gotchas.md](references/maintenance-gotchas.md) — Gotchas.
- [launcher.md](launcher.md) & [skill-menu-mode.md](skill-menu-mode.md) — Launchers.
- [retrospective/SKILL.md](retrospective/SKILL.md) — Retrospective workflow.

## backlog
Generate combined backlog (ADR-085).
```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/maintainer/scripts/backlog.py"
```

## adr
Create next ADR (ADR-086, ADR-110). Default to updating the existing adr for the affected skill when it fits; one adr per skill is preferred. `new-adr` remains a legacy alias.
```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/maintainer/scripts/new-adr.sh" <skill> <mode> "<title>"
```
For retiring/consolidating ADRs, see [references/adr-consolidation.md](references/adr-consolidation.md).

## skill
Umbrella mode for skill maintenance:
- `skill details [name]` / `skill-details` — live developer settings.
- `skill sync` / `sync-inventory` — reconcile inventories.
- `skill review [name\|all]` / `review-skills` — qualitative review.
- `skill review-contrib <candidate>` / `review-contrib` — review proposed/incubating skill under `contrib/proposals/` or `contrib/incubator/`. Do not place a candidate under `skills/` during review.
- `skill promote <candidate>` / `promote-contrib` — promote candidate.

## training
Read [references/training.md](references/training.md) to compare against patterns in [references/upstream-plugin-patterns.md](references/upstream-plugin-patterns.md).

## retro
Invoke retrospective sub-workflow at [retrospective/SKILL.md](retrospective/SKILL.md) to capture reusable lessons.

## self-test
Run deterministic pytest and best-practices checker. See [references/self-test.md](references/self-test.md).
```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/maintainer/scripts/run-self-test.sh"
```

## validate
Run structural validation (ADR-078):
```bash
claude plugin validate --strict .claude/plugins/ucsc-wp-block-dev
```

## docs
Regenerate (and optionally publish) Markdown documentation artifacts. Per ADR-107, `docs` is the single documentation mode and is a first-class `docs` operation; `generate-docs` remains a legacy alias.
Use `docs check` (or the `--check` flag) to check for staleness. bare `docs` is the update path using `scripts/regenerate-docs.sh` to update guide/slides.
`docs publish` is the optional final step of docs to publish guide/slides.
```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/maintainer/scripts/regenerate-docs.sh"
```
For publishing/environment details, see [references/generate-docs.md](references/generate-docs.md) and [references/publish.md](references/publish.md).

## publish
Legacy alias for `docs publish`. Bare `publish` publishes both guide and slides.
See [references/publish.md](references/publish.md) and:
```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/maintainer/scripts/publish-docs.sh" --target both --confirm
```

## sync-inventory
Reconcile skill inventories across docs and tests.
```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/maintainer/scripts/sync-inventory.sh" --write
```

## skill-details
Live settings view:
```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/maintainer/scripts/skill-details.py"
```

## all
Run deterministic checks (`self-test`, `check-references`, CLI validation) (ADR-086):
```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/maintainer/scripts/run-all-plugin-tests.sh"
```

## Supporting Files
All nested files must be referenced to satisfy ADR-032 checks:
- [assets/ucsc-wp-block-dev-presentation.md](assets/ucsc-wp-block-dev-presentation.md)
- [references/contrib.md](references/contrib.md)
- [references/generate-docs-main.md](references/generate-docs-main.md)
- [references/generate-docs-presentation.md](references/generate-docs-presentation.md)
- [references/refactor-links.md](references/refactor-links.md)
- [references/upstream-plugin-patterns.md](references/upstream-plugin-patterns.md)
- [retrospective/archived-2026-06-18-gutenberg-hardening.md](retrospective/archived-2026-06-18-gutenberg-hardening.md)
- [retrospective/archived-2026-06-24-adr-naming-and-orchestration.md](retrospective/archived-2026-06-24-adr-naming-and-orchestration.md)
- [scripts/build-slides.py](scripts/build-slides.py)
- [scripts/check-plugin-best-practices.py](scripts/check-plugin-best-practices.py)
- [scripts/publish-env.sh](scripts/publish-env.sh)
- [scripts/refresh-and-publish-docs.sh](scripts/refresh-and-publish-docs.sh)
- [scripts/refresh-and-publish-slides.sh](scripts/refresh-and-publish-slides.sh)
- [scripts/rename-adrs.py](scripts/rename-adrs.py)
- [scripts/retire-adr.sh](scripts/retire-adr.sh)
- [scripts/token-usage.py](scripts/token-usage.py)
- [scripts/check-skill-references.sh](scripts/check-skill-references.sh)
- [scripts/check-adr-implements.py](scripts/check-adr-implements.py)
