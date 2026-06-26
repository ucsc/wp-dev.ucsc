# Maintenance Gotchas

Common failure modes when maintaining the `ucsc-wp-block-dev` plugin.

## Claim ADR number before writing

Concurrent edits can grab the next sequential number while you work, causing a collision. Before creating a new ADR, check **both** `docs/adr/index.md` and `ls docs/adr/`. If the number was taken, renumber the file, its title/heading, every in-body reference, and the index row.

## Adding or removing a skill — move the full inventory sync set together

`test` fails if any surface is out of sync. The full set to update:

- `README.md` skills table
- `skills/hub/SKILL.md` public workflows table
- Slide deck: `skills/maintainer/assets/ucsc-wp-block-dev-presentation.md`
- Root `AGENTS.md` routing table
- `EXPECTED_LIVE_SKILLS` in `tests/test_plugin_structure.py`
- Any hardcoded skill lists in other tests (e.g., `test_plugin_validity.py::test_core_skills_present`)
- Generated `docs` assets (run `docs` to refresh; `docs check` reports staleness)

Run `sync-inventory.sh --write` first, then `check-references` and `test`.

## Renaming, folding, or adding a maintainer mode — `skill-tree.json` is the source of truth

A mode rename/fold/add is a recurring task; do it in this order so the gates pass first try:

1. **Edit `skills/hub/references/skill-tree.json`** — the canonical mode list. Add/rename/nest modes here (nested `modes:` render as sub-branches). Never hand-edit the menu trees in `skill-menu-mode.md`, `hub/SKILL.md`, or `README.md`; `sync-inventory.sh --write` regenerates them and will overwrite manual edits (and `--check`/`test` fail on the drift).
2. **Update the SKILL.md `argument-hint`** to list **exactly** the top-level modes in `skill-tree.json` — `sync-inventory.sh` hard-fails if they differ. **Legacy aliases must NOT appear in `argument-hint`** (e.g. `test`, `new-adr`, `generate-docs`, `publish`); list them only in prose as aliases.
3. Run `sync-inventory.sh --write` to regenerate every menu surface, then update the prose: the `## <mode>` section, the intake paragraph, and launcher alias routing.
4. Prefer **non-breaking**: keep the old mode name as a legacy alias and keep generated artifact filenames stable (rename the mode, not the files) to avoid churn across scripts and tests. See ADR-107 for the `generate-docs`→`docs` worked example.
5. Add/extend an ADR, update any test asserting the old `## heading` or operation phrasing, then run `all`.

## Publishing is per-target

Each `docs publish` target has its own destination Google Doc. `publish_to_gdoc.py --source <md> --doc <url>` publishes any markdown. Each fast-path script holds its own `GDOC_URL` (ADR-063).

## Markdown links to local absolute paths — use `file://`

When referencing generated local files (e.g., code reviews) via absolute paths, use the `file://` scheme (e.g., `file:///path/to/file`). The `test_all_markdown_links_resolve` test ignores `file://` links; bare absolute paths are parsed as relative and flagged as broken.

`test_all_markdown_links_resolve` also parses a link of the form `[text]` immediately followed by `(path)` even **inside backticks / code spans**, so an illustrative example link must still resolve from the containing file's directory. When writing an example link, either point it at a real file (relative to that `.md`) or separate the brackets from the parenthetical so the two are not adjacent (then it is not parsed as a link).

## Superseding an ADR can leave a stale test

Tests sometimes assert a decision's literal wording (e.g., a commit-syntax string). When an ADR is superseded, `grep` the tests for phrases tied to the old ADR, update the assertions to the current wording, and re-point the test docstring to the superseding ADR(s). A superseded ADR whose test still asserts the old text fails `test` even though the skills are correct.

## Temporary scripts under `skills/` trigger test failures

Every script placed under `skills/<skill>/scripts/` must be executable (`chmod +x`), start with a shebang, and be referenced in the skill's `SKILL.md`. It must also implement `--help`/`-h` that prints `Usage`/`usage` and exits 0 **with no side effects** — two pytest contracts enforce this (`test_all_skill_scripts_are_executable_with_shebang` and `test_all_skill_scripts_implement_help_without_side_effects`, which snapshots every plugin file and fails if `--help` writes anything). A common miss: a new script that only special-cases `--check` lets `--help` fall through to the writing path. Handle `--help` first, before any work. One-off helper scripts (e.g., custom migration or renaming scripts) should be run from outside the `skills/` structure, or deleted immediately after use, to avoid breaking the automated plugin structure tests.

## The slide deck has harvested AUTO regions — never hand-edit them

The deck's per-skill slides and roadmap are generated, not hand-written (ADR-106). `skills/maintainer/scripts/build-slides.py` rewrites the regions between `<!-- BEGIN AUTO:skills -->`/`<!-- END AUTO:skills -->` and `<!-- BEGIN AUTO:roadmap -->`/`<!-- END AUTO:roadmap -->` from `skill-tree.json`, a `<!-- doc-slide: ... -->` landmark in each `SKILL.md`, and the Proposed ADRs in `docs/adr/index.md`. To change a skill's slide copy, edit its `doc-slide:` landmark — edits inside the `AUTO:` markers are overwritten on the next `docs` run. `regenerate-docs.sh` runs the harvester before hashing, `sync-inventory.sh` delegates the deck to it, and `build-slides.py --check` (run by the pytest suite) fails if the regions drift. The guide is the README span between `<!-- BEGIN GUIDE -->`/`<!-- END GUIDE -->` only.

