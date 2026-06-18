---
name: maintainer
description: Maintain the ucsc-wp-block-dev plugin itself — validate structure, run tests, review or promote contributed skills, verify ADR consistency, review skills, and publish the maintainer-owned slide deck. Use for plugin health checks, contribution review, slide publishing, or release readiness.
---

# Maintainer — ucsc-wp-block-dev

Maintenance workflow for the `ucsc-wp-block-dev` plugin (not for block code —
use `develop`/`fix`/`run` for that). For Markdown artifact regeneration, read
[`references/generate-docs.md`](references/generate-docs.md).

Use this skill with one operation: `validate`, `test`, `review-skills`,
`review-contrib`, `promote-contrib`, `check-references`, `generate-docs`,
`publish` (`slides`/`docs`/`all`), `new-adr`, `sync-inventory`,
`skill-details`, or `all`. Run all commands below from the repo root.

To work on the plugin itself, launch Claude Code from the repo root with the
plugin loaded directly from its development directory:

```bash
claude --plugin-dir .claude/plugins/ucsc-wp-block-dev
```

This loads the in-tree plugin (skills, agents, hooks) so maintainer edits take
effect without installing from a marketplace.

Keep token use low: run the validator and tests rather than reading every file by hand. See ADR-003 and ADR-058 (single-agent mode by default).

Per ADR-073, all plugin operations are scoped to `.claude/plugins/ucsc-wp-block-dev/`. Ignore `.agents/` — it holds legacy tooling unrelated to this plugin.

## Universal Command Intake

Apply ADR-011: resolve the plugin target, natural-language maintenance request, and optional Jira key/URL from the full input and session context.

Per ADR-020, when the user enters maintainer mode **without an explicit operation** (a bare `maintainer`), do **not** launch into `validate`, `review-skills`, or any plugin-dev agent. First prompt the user for what to do, offering the available operations as options: `validate`, `test`, `review-skills`, `review-contrib`, `promote-contrib`, `check-references`, `generate-docs`, `publish` (`slides`/`docs`/`all`), `new-adr`, `sync-inventory`, `skill-details`, and `all`. Per ADR-064, when presenting these, flag that `validate` and `review-skills` each spawn a token-heavy Anthropic `plugin-dev` agent so the choice is informed; never run them automatically. Run the chosen operation only after they pick. When the user already named an operation (e.g. `maintainer test`), honor it directly without prompting. Once an operation is running, ask one concise question only when missing or conflicting information prevents useful work.

## Anthropic plugin-dev tools

`plugin-dev` is the required companion plugin for all Tier 2 operations (ADR-079).
Docs: https://code.claude.com/docs/en/plugins  
Source: https://github.com/anthropics/claude-plugins-official

**Before running any Tier 2 operation, verify it is installed:**

```bash
claude plugin list | grep plugin-dev
```

If absent, install it then reload:

```text
/plugin install plugin-dev@claude-plugins-official
/reload-plugins
```

| Tool | Type | Purpose |
|---|---|---|
| `plugin-dev:plugin-validator` | Agent | Validates plugin manifest, skill frontmatter, naming, structure, and security |
| `plugin-dev:skill-reviewer` | Agent | Reviews skill quality — description clarity, triggering effectiveness, best practices |
| `plugin-dev:skill-development` | Skill | Guidance for writing and improving skills — frontmatter fields, description patterns, argument handling |
| `plugin-dev:plugin-structure` | Skill | Plugin directory layout, manifest configuration, component organization |

## validate

Two-tier validation per ADR-078:

**Tier 1 — CLI structural check (free, deterministic):**

```bash
claude plugin validate --strict .claude/plugins/ucsc-wp-block-dev
```

Run this first. It checks manifest, frontmatter, naming, and file structure
with no agent tokens. This is also exercised by `maintainer test` via the
pytest suite.

**Tier 2 — plugin-dev agent semantic review (opt-in, ~10k tokens):**

Only offer this after Tier 1 passes and a deeper qualitative review is wanted
(ADR-064). Launch via the Agent tool:

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

If the host lacks Python/pytest, run the deterministic suite in Docker using
the local Node image's Python. This installs pytest only inside the ephemeral
container and keeps host Python out of the workflow (ADR-050):

```bash
docker run --rm -v "$PWD:/workspace" -w /workspace node:22.5.1 bash -lc \
  'apt-get update >/tmp/apt-update.log && \
   apt-get install -y python3-pytest >/tmp/apt-install.log && \
   python3 -m pytest -q .claude/plugins/ucsc-wp-block-dev/tests'
```

Claude CLI-dependent tests are skipped in this container unless `claude` is
available inside the image; that is expected for deterministic structural
validation.

Some tests skip gracefully when the `claude` CLI is unavailable — that is expected in CI.

## review-skills

Opt-in only and token-heavy (~14k tokens): never run automatically or as part of `all` (ADR-064). Launch the `plugin-dev:skill-reviewer` agent to audit skill quality, description effectiveness, and best-practice adherence after creating or modifying any `SKILL.md`.

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

1. Update `README.md`, `AGENTS.md`, the `hub` skill, and the maintainer slide
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

## refactor-links

When reference files are renamed or moved, update all markdown links in bulk
rather than one by one. See
[`references/refactor-links.md`](references/refactor-links.md) for the
`find`/`sed` one-liner and the threshold for manual vs. bulk approach.

## generate-docs

Regenerate portable Markdown documentation artifacts for Google Docs or
Confluence. Read
[`references/generate-docs.md`](references/generate-docs.md),
then run:

```bash
bash .claude/plugins/ucsc-wp-block-dev/skills/maintainer/scripts/regenerate-docs.sh
```

This writes generated artifacts under
`skills/maintainer/references/`, including
[`references/generate-docs-main.md`](references/generate-docs-main.md)
and
[`references/generate-docs-presentation.md`](references/generate-docs-presentation.md).
It does not publish or upload anything.

## publish

Per ADR-063, `publish` takes a target: `slides`, `docs`, or `all`. Publishing is
always explicit and never part of `all`.

### publish slides

The canonical Marp source is maintainer-owned:

`skills/maintainer/assets/ucsc_wp_block_dev_presentation.md`

**Fast path:** `bash .claude/plugins/ucsc-wp-block-dev/skills/maintainer/scripts/refresh_and_publish_slides.sh` bumps the `Generated:` date to today, runs the deck-contract tests, then publishes — in one token-frugal call. Pass `--no-publish` to refresh and test without uploading. The numbered steps below are what it automates and what to reconcile when deck content has drifted.

Before publishing:

1. Compare the deck's skill inventory with every top-level directory under `skills/`.
2. Compare its ADR summary with `docs/adr/index.md`.
3. Refresh the title slide's `Generated:` value to the current date.
4. Run the plugin tests, which enforce the deck path and inventory contract.

Publish the verified deck to the existing Google Doc:

```bash
python3 .claude/scripts/publish_to_gdoc.py --doc "https://docs.google.com/document/d/1r5gglrwp6AXabaXqOWhzWj7qDpJZhjvUAFci0-rXIII/edit"
```

Do not restore a second deck at the repository root (ADR-018).

### publish docs

Publishes the generated prose guide
`skills/maintainer/references/generate-docs-main.md`
(derived from `README.md` via `generate-docs`) to its own Google Doc.

**Fast path:** `bash .claude/plugins/ucsc-wp-block-dev/skills/maintainer/scripts/refresh_and_publish_docs.sh` regenerates the artifacts, runs the generate-docs contract tests, then publishes. Pass `--no-publish` to refresh and test without uploading.

The guide's destination Google Doc URL must be set in `GDOC_URL` inside
`refresh_and_publish_docs.sh` before first publish; until then the script refuses
to upload. The underlying publisher accepts an explicit source:

```bash
python3 .claude/scripts/publish_to_gdoc.py \
  --source skills/maintainer/references/generate-docs-main.md \
  --doc "https://docs.google.com/document/d/18Ozi1BJ60eH2_-mX5rpA08YsLtFwUAHC0nMErhsCxwo/edit"
```

### publish all

Run `publish slides` then `publish docs`.

## new-adr

Automatically allocates the next available ADR number, creates a new ADR markdown file with standard frontmatter and markdown skeleton, and updates the ADR index file. Run the script:

```bash
bash .claude/plugins/ucsc-wp-block-dev/skills/maintainer/scripts/new_adr.sh <slug> "<title>"
```

## sync-inventory

Enforces skill inventory consistency across all documentation and testing assets
by treating the directories in `skills/` as the source of truth. Per ADR-080,
this includes the root `AGENTS.md` routing table so Codex sees the live skill
set before plugin work begins. Run the script:

```bash
# Check for any drift (dry-run check)
bash .claude/plugins/ucsc-wp-block-dev/skills/maintainer/scripts/sync_inventory.sh --check

# Reconcile and regenerate all files automatically
bash .claude/plugins/ucsc-wp-block-dev/skills/maintainer/scripts/sync_inventory.sh --write
```

## skill-details

Live developer view of every skill's actual frontmatter and invocation settings (ADR-071). Shows `user-invocable`, `model-invocable`, `discoverable`, `disable-model-invocation`, `allowed-tools`, `context`, `agent`, and any extra fields — resolved to their actual values, not static defaults. Flags any skill that differs from the all-defaults baseline.

```bash
python3 .claude/plugins/ucsc-wp-block-dev/skills/maintainer/scripts/skill_details.py
```

Run after any `SKILL.md` frontmatter change to confirm the invocation posture is what you intended. The `hub` static grid is a snapshot; this script is the authoritative live source.

## all

Run the token-frugal deterministic checks in order: `test` (pytest suite),
`check-references`, then the CLI structural validator. Report a single combined
summary.

```bash
# Tier 1 structural validation included in `all` (ADR-078)
claude plugin validate --strict .claude/plugins/ucsc-wp-block-dev
```

Per ADR-064, `all` deliberately **excludes** the agent-backed checks
(`plugin-dev:plugin-validator` and `plugin-dev:skill-reviewer`) — each spawns
a token-heavy subagent, so they run only when explicitly requested. Offer them
after `all` if a deeper semantic review is wanted.

Contribution candidates are also excluded from `all`; run
`review-contrib <candidate>` explicitly because proposals and incubator skills
may be incomplete.

## Skill visibility and invocation (hidden skills)

For frontmatter fields (`user-invocable`, `disable-model-invocation`), combined behavior tables, platform capabilities (`when_to_use`, dynamic context injection, `context: fork`), and how this plugin currently hides skills, see [`references/skill-visibility.md`](references/skill-visibility.md).

## When the manifest or skills change

After editing `plugin.json`, any `SKILL.md`, or adding components, run `validate` to catch structure regressions, `check-references` to catch unreferenced support files, and `review-skills` to catch description and quality issues early. Use `skill-development` for guidance when writing new skills. When the main guide or deck should be prepared for Google Docs or Confluence without publishing, use the `generate-docs` operation in this skill.

## Maintenance gotchas

See [`references/maintenance-gotchas.md`](references/maintenance-gotchas.md) for the full list. Critical items:

- **Claim the ADR number before writing** — check both `docs/adr/index.md` and `ls docs/adr/` before creating a new ADR file.
- **Skill inventory sync set** — adding/removing a skill requires updating README, hub, slide deck, AGENTS.md, and two test files together. Run `sync_inventory.sh --write` first.
