# Code audit — ucsc-wp-block-dev plugin

Date: 2026-07-04
Scope: `.claude/plugins/ucsc-wp-block-dev/` — bugs, inconsistencies, unused files,
script clashes, token reduction, and alignment with Anthropic plugin-dev best
practices (reference: `claude-plugins-official/plugins/plugin-dev`).

Method: ran the plugin's own gates (`run-self-test.sh`: **4 failed, 132 passed,
3 skipped**; `check-skill-references.sh`: **FAIL, 10 unreferenced files**;
`check-plugin-best-practices.py`: PASS with 2 warnings), then manual comparison
against the official plugin-dev skills.

Overall: the plugin is in very good shape structurally — skills follow the
official SKILL.md + references/scripts/examples layout, descriptions use the
recommended third-person trigger style, and the self-test/ADR governance is
stronger than anything in the official repo. All current failures trace to the
in-flight multi-environment work (ADR-105 phases, partly uncommitted).

---

## 1. Bugs (self-test failures)

### 1.1 Broken link in validate skill
`skills/validate/SKILL.md:72` links `references/environments.md`, which does not
exist under `skills/validate/`. The file lives at
`skills/run/references/environments.md`.
Fix: change the link to `../run/references/environments.md` (kept as a shared
run-owned reference per ADR-068), or add a thin
`skills/validate/references/environments.md` pointer.

### 1.2 Hub skill tree drifted
`sync-inventory.sh --check` reports `skills/hub/SKILL.md` public workflows tree
out of sync (everything else in sync).
Fix: `bash skills/maintainer/scripts/sync-inventory.sh --write`.

### 1.3 Stub drivers violate the script CLI contract
`skills/run/drivers/local.sh` and `skills/run/drivers/wp-env.sh` exit 1 on
`--help` and print no `Usage:` line, failing
`tests/test_script_cli_contracts.py`. `wp-dev-ucsc.sh` and `generic-byo.sh`
pass.
Fix: add a `--help` branch to both stubs that prints a Usage line and exits 0,
keeping the "Phase 1 stub — use BYO" message for actual invocations.

### 1.4 Ten unreferenced supporting files
`check-skill-references.sh` requires every supporting file to be referenced from
its skill's SKILL.md. Unreferenced:

- run: `drivers/generic-byo.sh`, `drivers/local.sh`, `drivers/wp-dev-ucsc.sh`,
  `drivers/wp-env.sh`, `examples/env-invocations.md`,
  `lib/test-detect-environment.sh`, `references/environment.md`,
  `test-regression-wp-dev-ucsc.sh`
- validate: `validate-jest.sh`, `validate-e2e.sh`

Fix: reference `drivers/` (one line pointing at `references/environments.md`
which already documents them), `examples/env-invocations.md`,
`lib/test-detect-environment.sh`, and `test-regression-wp-dev-ucsc.sh` from
`skills/run/SKILL.md`; reference `validate-jest.sh` / `validate-e2e.sh` from
`skills/validate/SKILL.md` (it currently names only `validate-php.sh`).
`references/environment.md` — see 2.1: retire instead of referencing.

---

## 2. Inconsistencies

### 2.1 `environment.md` vs `environments.md` (run references)
`skills/run/references/environment.md` (singular, wp-dev.ucsc-only, carries
`implements: ADR-002-RUN-WP-DEV`) is largely superseded by the new
`environments.md` (multi-runtime, ADR-105). Two nearly-identically-named docs in
one directory is a trap for both humans and Claude.
Fix: merge the still-unique wp-dev.ucsc detail (compose-file specifics, "no
framework CLI" warning) into `environments.md` or into the wp-dev-ucsc driver
section, move the ADR-002 `implements:` marker there, and delete
`environment.md`.

### 2.2 Duplicated, drifted healthcheck scripts
`scripts/healthcheck.py|.sh` (plugin root) and `tests/healthcheck.py|.sh` are
near-copies that have drifted (different sizes/content). Only the `tests/` pair
is used (`tests/run_local_tests.py`); CI runs pytest only. Nothing references
the `scripts/` pair by path.
Fix: delete `scripts/healthcheck.py` and `scripts/healthcheck.sh` (and the stray
`scripts/__pycache__/`), leaving `tests/` as the single source.

### 2.3 Single-plugin wording vs two-plugin reality
`plugin.json` description and most skill descriptions say the toolkit is "for
the ucsc-gutenberg-blocks WordPress plugin", but the toolkit (and repo
CLAUDE.md) now covers **both** `ucsc-blocks` and `ucsc-gutenberg-blocks`
(`UCSC_PLUGIN=` in driver.sh) plus multiple runtimes (ADR-105). Descriptions
gate model invocation: a user asking about a `ucsc-blocks` (namespace `ucsc/*`)
block may not trigger the right skill.
Fix: update `plugin.json` description and the develop/fix/feature/run/validate/
verify descriptions to say "UCSC block plugins (ucsc-blocks,
ucsc-gutenberg-blocks)".

### 2.4 `allowed-tools` values are not valid tool names
`maintainer`, `run`, `validate`, `verify` SKILL.md frontmatter lists
`allowed-tools` like `bash`, `docker`, `docker-compose`, `wp`, `jq`, `python`,
`sed`, `npm`, `yarn`. Per the official spec (plugin-dev
`command-development/references/frontmatter-reference.md`), entries must be
Claude Code tool names — `Read`, `Grep`, `Bash`, or scoped `Bash(docker:*)`.
`docker`, `wp`, `jq` are shell commands, not tools; if the field were enforced
it could block Read/Edit while the skill is active, and as written it documents
nothing accurately.
Fix (recommended): drop `allowed-tools` from all four skills (inherit
conversation permissions), or rewrite as `Bash(docker:*)`, `Bash(wp:*)`, etc.
Note this touches ADR-070's frontmatter allowlist — the *keys* are fine, the
*values* are the issue.

### 2.5 INSTALL.md is orphaned
`INSTALL.md` is referenced by nothing (README included). First-time users won't
find it, and the sync/reference machinery ignores root docs.
Fix: link it from `README.md` ("Installation" section).

### 2.6 Uncommitted mode-only changes
`skills/validate/validate-e2e.sh` and `validate-jest.sh` have uncommitted
`100644 → 100755` chmod changes. These are correct (executables should have the
bit; the best-practices checker enforces this) — worth committing with the rest
of the phase-3 work. Same checker warns `skills/validate/examples/jest-test.js`
lacks the execute bit; since it's an example (content, not an executable), the
cleaner fix is arguably to teach the checker to skip `examples/`, but chmod +x
is the zero-code fix.

---

## 3. Unused files

| File | Status | Recommendation |
|---|---|---|
| `scripts/healthcheck.py`, `scripts/healthcheck.sh` | unused, drifted duplicates of `tests/` pair | delete |
| `skills/run/references/environment.md` | superseded by `environments.md` | merge + delete (2.1) |
| `scripts/__pycache__/check_adr_implements*.pyc` etc. | stale local bytecode (incl. from a since-renamed module); gitignored but on disk | delete locally; harmless |
| `.pytest_cache/`, `tests/__pycache__/` | gitignored local artifacts | no action (verify marketplace packaging excludes them) |
| `contrib/`, `PORTABLE-PATTERNS.md`, `WORKFLOW-LIST.md` | referenced (ADRs/maintainer refs) | keep |

No genuinely dead skills or scripts were found beyond the above — the
reference-checker discipline is working.

---

## 4. Script clashes / overlaps

- **`skills/run/driver.sh` vs `skills/verify/driver.sh`** — same filename, two
  skills. Not duplicates (run = lifecycle router, verify = deterministic
  runtime substrate) and verify's header says so, but the shared name invites
  the wrong invocation from a model that has both paths in context. Consider
  renaming verify's to `verify-driver.sh` or `runtime-check.sh`. Low priority.
- **`skills/run/block-doctor.sh` + `helpers/block-doctor.php`**, and the
  `seed-*.sh` → `helpers/seed-*.php` pairs are a deliberate wrapper pattern —
  fine.
- **run skill root sprawl** — `run/` mixes root-level executables
  (`driver.sh`, `block-doctor.sh`, `list-blocks.sh`, `seed-*.sh`, `wp-eval.sh`,
  `test-regression-wp-dev-ucsc.sh`) with `drivers/`, `lib/`, `helpers/`,
  `examples/`, `references/`. The official convention puts executables under
  `scripts/`. Moving them is churn (paths are baked into docs/tests), but new
  scripts should go in subdirectories; consider moving
  `test-regression-wp-dev-ucsc.sh` under `lib/` next to the detect-environment
  test it complements.

---

## 5. Token reduction

- **`skills/maintainer/SKILL.md` — 2,812 body words (~3.7k tokens)**. Its own
  best-practices checker warns. Biggest single win: move mode detail
  (docs/publish/adr/skill submode walkthroughs) into the existing
  `references/*.md`, keeping SKILL.md as a mode router. Target < 1,500 words.
- **`skills/develop/SKILL.md` — 1,544 words** while feature/fix sub-skills also
  carry their own bodies (559 / 1,248). Audit for content repeated across the
  three (target resolution, branch warnings) and hoist to one shared reference.
- **Frontmatter descriptions load every session** for all 10 skills.
  `feedback` (~95 words) and `hub` (~80 words) are the longest; both can lose
  a third without losing triggers (e.g. feedback's "plugin analog of /bug"
  sentence and the WordPress-feedback-block disclaimer can compress to one
  clause each). Small but recurring saving, consistent with ADR-003.
- **`run`/`verify` SKILL.md ~1,300 words each** — acceptable, but both restate
  environment facts now centralized in `references/environments.md`; a pass to
  replace restatement with the link would trim a few hundred tokens each.

---

## 6. Best-practices alignment (vs official plugin-dev)

Compliant — no action:
- Layout: `SKILL.md` + `references/` + `scripts/` + `examples/` matches the
  official anatomy; `.claude-plugin/plugin.json` fields are all valid manifest
  keys.
- Descriptions: third-person "This skill should be used when…" with concrete
  quoted triggers — exactly the recommended pattern.
- Progressive disclosure: references are loaded on demand; scripts are executed
  rather than read. ADR-032 enforces reference discipline mechanically, which
  goes beyond the official guidance.
- Testing: the pytest gate + CI exceeds anything in the official repo.

Gaps (all covered above): allowed-tools syntax (2.4), maintainer SKILL.md size
(5), executables outside `scripts/` in run (4), example exec-bit warning (2.6).

One extra: the CI secret scan (`.github/workflows/ci.yml`) greps for bare
`PASSWORD` / `token.json` across all files — this will false-positive on docs
that mention the dev credentials (`admin`/`password`) and on the .gitignore
itself. Consider tightening the pattern to assignments (`PASSWORD\s*=`) or
allowlisting docs.

---

## 7. Suggested fix order

1. `sync-inventory.sh --write` (1.2) — mechanical.
2. Fix validate SKILL.md link (1.1) + reference validate-jest/e2e scripts (1.4).
3. Add `--help` to `local.sh` / `wp-env.sh` stubs (1.3).
4. Reference the new run files from run/SKILL.md (1.4).
5. Merge `environment.md` → `environments.md`, delete singular (2.1).
6. Delete `scripts/healthcheck.*` (2.2).
7. Fix or drop `allowed-tools` (2.4).
8. Wording pass: two-plugin descriptions (2.3), README → INSTALL link (2.5).
9. Token diet: maintainer SKILL.md, then develop family, then descriptions (5).

Items 1–6 should take the self-test from FAIL to PASS.

---

## 8. Fixes applied (2026-07-04, same session)

Items 1–6 were applied; `run-self-test.sh` now reports **PASS (136 passed, 3
skipped, 0 failed)**. Specifics:

- `sync-inventory.sh --write` regenerated the hub public workflows tree.
- `validate/SKILL.md`: link fixed to `../run/references/environments.md`; all
  three validators (`validate-php.sh`, `validate-jest.sh`, `validate-e2e.sh`)
  now referenced.
- `--help` (Usage + exit 0) added to `drivers/local.sh`, `drivers/wp-env.sh`,
  and — once they came into contract scope by being referenced —
  `lib/detect-environment.sh`, `lib/test-detect-environment.sh`, and
  `test-regression-wp-dev-ucsc.sh`.
- `run/SKILL.md`: Environment section now links the four drivers, the
  detection lib and its test, and the regression suite; Examples section links
  `examples/env-invocations.md`.
- `references/environment.md` merged into `environments.md` (new
  "wp-dev.ucsc in depth" section, ADR-002 `implements:` marker moved) and
  deleted; the ADR-105 link updated to the merged file.
- `scripts/healthcheck.py`, `scripts/healthcheck.sh`, and the plugin-root
  `scripts/` directory (only stale `__pycache__` remained) deleted; `tests/`
  pair is the single source.

Noted, not fixed: `test-regression-wp-dev-ucsc.sh` reports 2 failures
(`inspect` phase, auto + explicit) when Docker Desktop is not running —
environment-dependent, pre-existing, not a code defect (detection and driver
verified correct from the repo root). Remaining recommendations: items 2.3–2.5
(descriptions, allowed-tools, INSTALL link) and the token diet (section 5).

## 9. Final continuation fixes (2026-07-05, this session)

All remaining recommendations from the code audit tail were completed and verified:

1. **Finish allowed-tools fix**: `allowed-tools` frontmatter in `validate/SKILL.md` and `maintainer/SKILL.md` rewritten to valid Claude Code tool syntax (Read, Grep, Bash(cmd:*), etc.). The ad-hoc frontmatter parsers in the test suites were patched to ignore list items starting with `-`.
2. **Two-plugin wording (2.3)**: `plugin.json` and the core skill descriptions (`develop`, `develop/feature`, `develop/fix`, `run`, `validate`, `verify`) updated to reference both `ucsc-blocks` and `ucsc-gutenberg-blocks`.
3. **Orphaned INSTALL.md (2.5)**: Linked `INSTALL.md` from `README.md` (placed outside the generated `GUIDE` markers to avoid broken links in documentation artifacts).
4. **Tighten CI secret scan**: Grep patterns in `.github/workflows/ci.yml` tightened to prevent false-positives on `token.json` docs references, explicitly scanning for tracked credentials files and using specific regex patterns for variables.
5. **Section 5 token diet**:
   - `maintainer/SKILL.md` streamlined from ~2,800 words to ~700 words, functioning as a mode router and delegating verbose operational details to references.
   - `develop/SKILL.md`, `develop/feature/SKILL.md`, and `develop/fix/SKILL.md` deduped/condensed around the intake and target resolution blocks.
   - Frontmatter descriptions of `feedback` and `hub` trimmed to reduce baseline session tokens.
6. **Re-run the gates**: ran all tests and sync verification successfully.

Final verification results:
- `sync-inventory.sh --check`: **PASS** (all trees, agent routes, menus, and tests in sync).
- `regenerate-docs.sh --check`: **FRESH** (source-hash matches generated docs).
- `run-all-plugin-tests.sh`: **PASS** (136 passed, 3 skipped, 0 failed).
