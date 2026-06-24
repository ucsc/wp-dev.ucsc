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
- Generated `generate-docs` assets (run `generate-docs` to refresh)

Run `sync-inventory.sh --write` first, then `check-references` and `test`.

## Publishing is per-target

Each `publish` target has its own destination Google Doc. `publish_to_gdoc.py --source <md> --doc <url>` publishes any markdown. Each fast-path script holds its own `GDOC_URL` (ADR-063).

## Markdown links to local absolute paths — use `file://`

When referencing generated local files (e.g., code reviews) via absolute paths, use the `file://` scheme (e.g., `file:///path/to/file`). The `test_all_markdown_links_resolve` test ignores `file://` links; bare absolute paths are parsed as relative and flagged as broken.

## Superseding an ADR can leave a stale test

Tests sometimes assert a decision's literal wording (e.g., a commit-syntax string). When an ADR is superseded, `grep` the tests for phrases tied to the old ADR, update the assertions to the current wording, and re-point the test docstring to the superseding ADR(s). A superseded ADR whose test still asserts the old text fails `test` even though the skills are correct.

## Temporary scripts under `skills/` trigger test failures

Every script placed under `skills/<skill>/scripts/` must be executable, start with a shebang, and be referenced in the skill's `SKILL.md`. One-off helper scripts (e.g., custom migration or renaming scripts) should be run from outside the `skills/` structure, or deleted immediately after use, to avoid breaking the automated plugin structure tests.

