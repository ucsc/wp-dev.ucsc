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

Enforces skill inventory consistency across all documentation and testing assets by treating the directories in `skills/` as the source of truth. Run the script:

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

For detailed reference rules on plugin skill visibility, see [`references/skill-visibility.md`](references/skill-visibility.md).

Official skills reference: `https://code.claude.com/docs/en/skills`

Claude Code exposes two frontmatter booleans that control *how* a skill can be
invoked. Know what they do before deciding how to "hide" a skill:

| Field | Default | When set to the non-default | Effect |
|---|---|---|---|
| `user-invocable` | `true` | `user-invocable: false` | Hides the skill from the `/` slash-command menu. The user can no longer invoke it by name; **the model can still auto-invoke it** from its description. |
| `disable-model-invocation` | `false` | `disable-model-invocation: true` | The model will **not** auto-trigger the skill from its description; **the user can still run it** explicitly via `/<skill>`. |

Combined behavior:

| `user-invocable` | `disable-model-invocation` | Who can invoke |
|---|---|---|
| `true` (default) | `false` (default) | User (slash menu) **and** model (auto) — fully public |
| `false` | `false` | Model only — auto-invoked, hidden from the slash menu |
| `true` | `true` | User only — manual `/<skill>`, no model auto-trigger |
| `false` | `true` | Effectively unreachable — avoid |

Note the defaults are `user-invocable: true` and
`disable-model-invocation: false`; writing those values explicitly does nothing,
so only add a field when you mean to flip it.

### How this plugin currently hides skills

Per ADR-070, the structural test `test_frontmatter_uses_portable_agent_skills_fields`
now accepts the full official Claude Code frontmatter field set, so
`user-invocable` and `disable-model-invocation` are permitted in any
`skills/*/SKILL.md`. Despite this, the plugin currently achieves hiding by
convention rather than frontmatter:

- **`maintainer`** is a hidden *manual* skill (ADR-046): it stays a live,
  type-able skill but is removed from the public workflow tables in `README`,
  `hub`, and the slide deck so it does not clutter the product-facing list.
  Hiding is documentation-level, not frontmatter-level.
- **`develop`** is kept from direct triggering by **description wording**
  ("Invoked by the `feature` and `fix` skills after scope is defined; do not
  trigger directly"), not by `disable-model-invocation`.

To use frontmatter-enforced visibility, add the field and document the
decision in an ADR — the test will no longer reject it.

### Platform capabilities worth knowing when authoring skills

- **1,536-char truncation cap** — the combined `description` + `when_to_use`
  text is truncated at 1,536 characters in the skill listing. Put the key
  trigger phrase first in `description`; use `when_to_use` for secondary
  phrases that don't fit.
- **`when_to_use`** — optional field appended to `description` in the listing;
  useful for adding trigger phrases without bloating the primary description.
- **`${CLAUDE_SKILL_DIR}`** — expands to the skill's own directory at runtime.
  Reference bundled scripts with this variable so paths survive regardless of
  where the session starts. To inject output at load time, prefix a line with `!`
  followed by a backtick-wrapped shell command (e.g. `!` + `` `bash …/scripts/run.sh` ``).
- **Dynamic context injection** — a line beginning with `!` and a backtick-wrapped
  command (or a fenced ` ```! ` block) runs the command *before* Claude sees the skill and
  inlines its output. Use to inject live state (current branch, build status,
  etc.) directly into a skill prompt without extra tool calls.
- **`context: fork` + `agent`** — runs the skill in an isolated subagent; the
  skill body becomes the subagent's prompt. Candidate pattern if `validate` or
  `review-skills` are ever converted from manual Agent-tool calls.

## When the manifest or skills change

After editing `plugin.json`, any `SKILL.md`, or adding components, run `validate` to catch structure regressions, `check-references` to catch unreferenced support files, and `review-skills` to catch description and quality issues early. Use `skill-development` for guidance when writing new skills. When the main guide or deck should be prepared for Google Docs or Confluence without publishing, use the `generate-docs` operation in this skill.

## Maintenance gotchas

- **Claim the ADR number before writing.** Concurrent edits (or a linter) can add
  an ADR with the next sequential number while you work, so a fresh `ADR-NNN`
  file can collide. Before creating one, check **both** `docs/adr/index.md` and
  `ls docs/adr/`; if your number was taken, renumber the file, its title/heading,
  every in-body reference, and the index row.
- **Adding or removing a skill touches an inventory sync set — move them
  together or `test` fails.** The set is: the README skills table, the `hub`
  listing, the slide deck skill table (`skills/maintainer/assets/…presentation.md`),
  `EXPECTED_LIVE_SKILLS` in `tests/test_plugin_structure.py` (plus any
  hardcoded skill lists in tests, e.g. `test_plugin_validity.py`), and the
  generated `generate-docs` assets (run `generate-docs` to refresh). Then run
  `check-references` and `test`.
- **Publishing is per-target.** Each `publish` target has its own destination
  Google Doc; `publish_to_gdoc.py --source <md> --doc <url>` publishes any
  markdown, and each fast-path script holds its own `GDOC_URL` (ADR-063).
- **Markdown links to local filesystem absolute paths (`file://`) must be excluded in tests.** When referencing generated local files (e.g., code reviews) via absolute paths, always format them using the `file://` scheme (e.g., `file:///path/to/file`). The link check test (`test_all_markdown_links_resolve` in `test_plugin_structure.py`) is configured to ignore links starting with `file://` so they are not parsed as relative paths and incorrectly flagged as broken.
- **Superseding an ADR can leave a stale test.** Tests sometimes assert a
  decision's literal wording (e.g. a commit-syntax string). When an ADR is
  superseded — including by concurrent/external work — `grep` the tests for
  phrases tied to the old ADR, update the assertions to the current wording, and
  re-point the test docstring to the superseding ADR(s). A superseded ADR whose
  test still asserts the old text fails `test` even though the skills are
  correct (e.g. ADR-029's `git add`/`commit`/`push` literal after the git-ops
  rework).
