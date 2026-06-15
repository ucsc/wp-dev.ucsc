# ucsc-wp-block-dev Plugin — Workflow List

Last updated: 2026-06-08
Previous session: Codex review (ran out of context), then Claude Code review session confirmed all 6 Codex findings + plugin-validator + skill-reviewer results.

## Context

Brand new plugin at `.claude/plugins/ucsc-wp-block-dev/`. First full review completed 2026-06-08.
Target codebase: `public/wp-content/plugins/ucsc-gutenberg-blocks/` (version 1.1.29).
Docker services: `wp`, `wpcli` (not `wordpress`).
Block namespace: `ucscblocks/*` (not `ucsc/*`).

## In Progress

(none)

## Queue — P2 (Improvements)

(cleared)

## Queue — P3 (Hygiene)

(cleared)

## Done

- [x] Initial Codex review — 6 findings (2026-06-08)
- [x] Plugin validator review — 3 warnings, structure valid (2026-06-08)
- [x] Skill reviewer review — 2 major, 4 minor, overall pass (2026-06-08)
- [x] Verified all Codex findings against actual codebase (2026-06-08)
- [x] Fix 1: Docker service name — `wordpress` -> `wpcli` in fix/SKILL.md, run/SKILL.md (8 occurrences)
- [x] Fix 2: Block namespace `ucsc/*` -> `ucscblocks/*`, registration via `add_action('init', ...)`, JS export-function pattern in dev/SKILL.md and domain reference
- [x] Fix 3: `npm test` references — added "no test script" notes across all 4 skills
- [x] Fix 4: stack-profile.md — version 1.1.29, correct git SHA, replaced nonexistent `src/API/Course_Schedule_API.php` with actual `classes/ClassSchedule.php`
- [x] Fix 5: ADR-001 — corrected plugin discovery claim; documented `--plugin-dir` / install requirement
- [x] Fix 6: Converted blocks guidance from hidden skill concept to hidden reference material
- [x] Fix 7: Added `argument-hint` to run/SKILL.md
- [x] Fix 8: README — removed `/ucsc-wp-block-dev:blocks` from command table, noted it as hidden reference material
- [x] Fix 9: Removed non-standard `paths` key from run/SKILL.md frontmatter
- [x] Fix 10: Added .gitignore
- [x] Fix 11: Added `paths` to dev/SKILL.md and fix/SKILL.md
- [x] Fix 12: Added cross-reference to `/ucsc-wp-block-dev:run` at end of fix/SKILL.md
- [x] Fix 13: Added MIT LICENSE file
- [x] Fix 14: Removed `__pycache__/` and `.pytest_cache/` from disk
- [x] Plugin-validator re-run: PASS, no regressions (2026-06-08)
- [x] Fixed test cwd bug: `claude plugin details` must run from project root for project-scoped install — added `PROJECT_ROOT`/`plugin_details()` helper in test_plugin_validity.py (2026-06-09)
- [x] Renamed skills `dev` -> `develop` and `maintain` -> `maintainer` (no alias); updated README, ADR-001/002/003/004/005, and test skill-name lists (2026-06-09)
- [x] Added `maintainer` to hardcoded skill-name lists in test_plugin_structure.py and test_plugin_validity.py for explicit coverage (2026-06-09)
- [x] Plugin-validator re-run post-rename: PASS, rename fully consistent (2026-06-09)
- [x] Skill-reviewer re-run on all 5 skills: all PASS. Applied fixes — develop: §8 REST constructor now uses `add_action('init'/'rest_api_init')`, template wrapper class `wp-block-ucscblocks-block-name`; fix: gated Jest table row on "test script exists"; maintainer: description ("verify ADR index consistency", dropped "hooks") + repo-root cwd note; removed empty run/scripts/ dir (2026-06-09)
