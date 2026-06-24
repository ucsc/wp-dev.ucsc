---
name: verify
description: This skill should be used when the user asks to "verify this change", "confirm this works", "prove this acceptance criterion", "check the rendered block", or demonstrate that a ucsc-gutenberg-blocks change behaves correctly in the running WordPress editor or frontend without substituting automated tests or type checks.
argument-hint: "[block] [change or acceptance criterion]"
allowed-tools:
  - bash
  - curl
  - docker
  - docker-compose
  - wp
  - jq
---

# Verify In The Running App

## Implements

implements: ADR-030-VERIFY-SEPARATION, ADR-068-VERIFY-SHARED-SCRIPTS, ADR-074-VERIFY-BLOCK-COVERAGE, ADR-093-VERIFY-BLOCK-TARGET

Verify behavior against the live `wp-dev.ucsc` application, following the
recorded launch recipe in the `run` skill.

## What `verify` proves — DOM vitals, the "is it alive?" check

Per the ADR-030 (2026-06-23) amendment, `verify` is the per-block **"are you
alive?"** test: it loads the relevant page(s) in the running editor/frontend and
asserts on concrete **DOM vitals** — landmarks/signals proving the target block
actually rendered and behaves as specified (expected wrapper/class, block markup,
rendered content, hydrated interactive state). Proving a DOM is merely *served*
is the `run` skill's job and is not sufficient here.

Two ways to find those vitals, in order of preference:

1. **Against a seeded fixture (preferred).** Drive a known sample page that
   contains the target block, so the same landmarks are present every run. The
   `run` skill seeds such fixtures during bring-up — `run/seed-demo-page.sh`
   upserts a demo page containing every registered `ucsc/*` block (and
   `run/seed-events-cache.sh` for data-backed blocks). Drive the URL it prints.
2. **Smoke test (fallback).** When no fixture exists, look for general
   signals/landmarks on the site's main page (and optionally a few other pages)
   confirming the app and target block are alive, rather than asserting against a
   guaranteed fixture.

## Universal Command Intake

Resolve the target block, natural-language change or acceptance criterion, app
surface, and optional Jira key/URL from the full input and session context.
Ask one concise question only when the target or behavior to prove is missing.

**Block target (ADR-093).** Resolve the block target with the shared contract in
[`../develop/references/block-target-session.md`](../develop/references/block-target-session.md):
ARGUMENTS → persisted session value (`develop/scripts/session-target.sh get`) →
cwd inference → prompt. Validate an inferred directory with
`develop/scripts/block-target-check.sh` before adopting it, and persist a newly
resolved target with `session-target.sh set`.

## Build And Launch

1. Use the `run` recipe to inspect prerequisites and start only what is missing.
2. Build the current plugin source in Docker.
3. Confirm the plugin is active and the WordPress services are running.
4. Open the canonical app at `https://wp-dev.ucsc/wp-admin/`.

Do not use Jest, PHP tests, lint, type checks, or a successful build as proof
that the user-facing behavior works. Those checks belong to the `validate` skill.

## Deterministic Pre-Checks — `driver.sh`

Before the browser pass, run the bundled [`driver.sh`](driver.sh) to confirm the change is even in a verifiable state — built, active, and server-side registered — in one compact call instead of a string of Docker/wp commands:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/verify/driver.sh" <block-slug> [--url URL --needle STRING]
```

It checks: plugin active, `build/` current with `src/`, the target block registered, and (optionally) a frontend URL returns 200 and contains an expected string. Slug matching is hyphen-insensitive (`campus-directory` matches `campusdirectory`). If `${CLAUDE_PLUGIN_ROOT}` is unset, use the in-plugin path `skills/verify/driver.sh`; the root is autodetected (override with `WP_DEV_ROOT=`).

These checks are a **gate, not proof**. A PASS only means the change is ready to verify; it does **not** substitute for the verification below. Point `--url` at a page that actually renders the block, and still confirm the user-facing behavior visually.

## Repo-local smoke runner — `bin/verify.sh` (`ucsc-gutenberg-blocks`)

When the target repo ships `bin/verify.sh`, prefer it for the host-side "are you
alive?" gate. It depends on `run` having launched the stack, and runs three
ordered checks, stopping at the first hard failure:

1. **ALIVE** — the site answers over HTTPS (`curl -k --resolve wp-dev.ucsc:443:127.0.0.1`).
2. **BUILT** — the compiled asset is present (`build/index.js`).
3. **RENDER** — a known page returns 200 and its body contains both the page
   marker and the target block's DOM marker (e.g. `id="classSchedule"` for
   ClassSchedule), proving the dynamic block server-rendered into the page.

```bash
bash bin/verify.sh
```

Every target is env-overridable: `VERIFY_BASE_URL`, `VERIFY_PAGE`,
`VERIFY_PAGE_EXPECT`, `VERIFY_BLOCK_EXPECT`, `VERIFY_RESOLVE`. Logs to
`$UCSC_LOG_DIR/ucsc-verify.log` (default `/tmp`). Like `driver.sh`, a PASS is a
**gate, not proof** — for interactive blocks still confirm behavior in the
browser per the steps below. The DOM-marker check (gate 3) is the script form of
the **DOM vitals** this skill requires; pick a marker the target block always
emits, and drive a page whose criterion currently returns data.

## Verify Behavior

Use the available browser tool to:

1. Log in with the documented development credentials when needed.
2. Navigate to the relevant editor, post, page, or frontend route.
3. Create or reuse the minimum content needed to exercise the change.
4. Perform the user action described by the request or acceptance criteria.
5. Inspect the rendered result, browser console, and network behavior when relevant.
6. Capture a screenshot when it materially demonstrates the result.

For data-backed blocks, account for the appropriate integration:

- Campus Directory may require UCSC VPN and LDAP access.
- Course Catalog and Class Schedule may require live external data.
- Clear transients only when stale cache is a plausible cause.

## Dev-vs-Prod Block Comparison — `compare-blocks.sh`

Compare a block's rendered DOM between the local dev site and a production site. Both pages must contain the same block type configured with the same division/department and block settings. The script fetches each page, extracts the block container, normalizes away ephemeral differences (nonces, cache-busters, timestamps), and diffs the structure.

The script lives in `_WP_tools` alongside the other reporting and regression tools. Note: that external hardcoded path is fragile. A plugin-local wrapper exists at `skills/verify/scripts/compare-blocks.sh` which prefers a plugin-local copy and falls back to `~/_code/_WP_tools/compare-blocks.sh`. If neither is available the wrapper prints concise manual steps and exits non-zero. When `--prod` and `--block` are omitted, both are auto-detected from the dev page content:

```bash
bash ~/\_code/\_WP\_tools/compare-blocks.sh \
  --dev https://test-henryh.wordpress-dev.ucsc.edu/class-schedule-test/
```

The prod URL is detected by looking for a "compare with `<URL>`" note on the dev page, or any content-area link to a `*.ucsc.edu` prod site. The block type is detected from known container elements in the page. To enable auto-detect, add a note like "compare with https://philosophy.ucsc.edu/class-schedule/" to the dev test page.

Explicit mode still works:

```bash
bash ~/\_code/\_WP\_tools/compare-blocks.sh \
  --dev  https://wp-dev.ucsc/page-with-block/ \
  --prod https://example.ucsc.edu/page-with-block/ \
  --block class-schedule
```

Use `--chrome` for JS-rendered DOM (headless Chrome `--dump-dom`) instead of curl. Override the auto-detected container selector with `--selector id=myId` or `--selector class=my-class`. Add `--keep` to preserve the fetched HTML and diff output.

Known blocks: `class-schedule`, `course-catalog`, `campus-directory`, `accordion`, `accordion-wrapper`, `content-sharer`, `feedback`.

A MATCH result means the block DOM is identical after normalization. DIFFERS means the diff found changes — review the output to determine if the differences are expected (e.g. different live data, different block settings) or indicate a rendering bug.

Reference: plugin-local wrapper at `scripts/compare-blocks.sh` (see `skills/verify/scripts/compare-blocks.sh`).
A self-contained local-only variant that does not fall back to an external `_WP_tools` path is available at `scripts/compare-blocks-local.sh` (see `skills/verify/scripts/compare-blocks-local.sh`).

## Result

Report:

- target and behavior checked;
- exact route or editor surface used;
- observed result;
- pass or fail for each acceptance criterion;
- runtime errors or environmental limitations;
- anything not verified.

If runtime verification fails, preserve the evidence and route the problem to
the `fix` skill. Do not claim success from automated tests alone.

## Lessons Learned

- **Multi-Block Directory Auditing**: Freshness checks in verification drivers must dynamically resolve the target block's location (checking `build/blocks/<slug>/index.js` or `build/index.js` depending on the plugin's architecture).
- **Source File Filtering**: Restrict staleness checking to JS/CSS/JSON source files, explicitly ignoring local configuration files (like `.claude/` settings) or uncompiled PHP templates, preventing false-positive stale reports.
- **Log Isolation for Low Token Consumption**: Verification scripts should redirect detailed logs to a file and output only a clean PASS/FAIL status along with the log path. The AI should only ingest the logs if a failure is reported.
