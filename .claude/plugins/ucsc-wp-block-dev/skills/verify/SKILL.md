---
name: verify
description: Build and run wp-dev.ucsc, then do a live DOM test of a ucsc-gutenberg-blocks code change or acceptance criterion in the running WordPress editor or frontend. Use when asked to verify, confirm, demonstrate, or prove that a block change works; do not substitute unit tests or type checks for live DOM testing.
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

## Universal Command Intake

Resolve the target block or app surface, natural-language expected behavior, and optional Jira key/URL from the full input and session context. Merge available acceptance criteria. Ask one concise question only when the behavior to prove or the target surface is missing.

**Block target (ADR-093).** Resolve the block target with the shared contract in
[`../develop/references/block-target-session.md`](../develop/references/block-target-session.md):
ARGUMENTS → persisted session value (`develop/scripts/session_target.sh get`) →
cwd inference → prompt. Validate an inferred directory with
`develop/scripts/block_target_check.sh` before adopting it, and persist a newly
resolved target with `session_target.sh set`.

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

## Verify Behavior

Use the available browser tool to:

1. Log in with the documented development credentials when needed.
2. Navigate to the relevant editor, post, page, or frontend route.
3. Create or reuse the minimum content needed to exercise the change.
4. Perform the user action described by the request or acceptance criteria.
5. Inspect the rendered result, browser console, and network behavior when relevant.
6. Capture a screenshot when it materially demonstrates the result.

For data-backed blocks, verify the appropriate integration:

- Campus Directory may require UCSC VPN and LDAP access.
- Course Catalog and Class Schedule may require live external data.
- Clear transients only when stale cache is a plausible cause.

## Dev-vs-Prod Block Comparison — `compare_blocks.sh`

Compare a block's rendered DOM between the local dev site and a production site. Both pages must contain the same block type configured with the same division/department and block settings. The script fetches each page, extracts the block container, normalizes away ephemeral differences (nonces, cache-busters, timestamps), and diffs the structure.

The script lives in `_WP_tools` alongside the other reporting and regression tools. Note: that external hardcoded path is fragile. A plugin-local wrapper exists at `skills/verify/scripts/compare_blocks.sh` which prefers a plugin-local copy and falls back to `~/_code/_WP_tools/compare_blocks.sh`. If neither is available the wrapper prints concise manual steps and exits non-zero. When `--prod` and `--block` are omitted, both are auto-detected from the dev page content:

```bash
bash ~/\_code/\_WP\_tools/compare_blocks.sh \
  --dev https://test-henryh.wordpress-dev.ucsc.edu/class-schedule-test/
```

The prod URL is detected by looking for a "compare with `<URL>`" note on the dev page, or any content-area link to a `*.ucsc.edu` prod site. The block type is detected from known container elements in the page. To enable auto-detect, add a note like "compare with https://philosophy.ucsc.edu/class-schedule/" to the dev test page.

Explicit mode still works:

```bash
bash ~/\_code/\_WP\_tools/compare_blocks.sh \
  --dev  https://wp-dev.ucsc/page-with-block/ \
  --prod https://example.ucsc.edu/page-with-block/ \
  --block class-schedule
```

Use `--chrome` for JS-rendered DOM (headless Chrome `--dump-dom`) instead of curl. Override the auto-detected container selector with `--selector id=myId` or `--selector class=my-class`. Add `--keep` to preserve the fetched HTML and diff output.

Known blocks: `class-schedule`, `course-catalog`, `campus-directory`, `accordion`, `accordion-wrapper`, `content-sharer`, `feedback`.

A MATCH result means the block DOM is identical after normalization. DIFFERS means the diff found changes — review the output to determine if the differences are expected (e.g. different live data, different block settings) or indicate a rendering bug.

Reference: plugin-local wrapper at `scripts/compare_blocks.sh` (see `skills/verify/scripts/compare_blocks.sh`).
A self-contained local-only variant that does not fall back to an external `_WP_tools` path is available at `scripts/compare_blocks_local.sh` (see `skills/verify/scripts/compare_blocks_local.sh`).

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
