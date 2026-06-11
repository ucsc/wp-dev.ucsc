---
name: verify
description: Build and run wp-dev.ucsc, then verify a ucsc-gutenberg-blocks code change or acceptance criterion in the live WordPress editor or frontend. Use when asked to verify, confirm, demonstrate, or prove that a block change works; do not substitute unit tests or type checks for runtime verification.
argument-hint: "[target | expected behavior | Jira key/URL]"
arguments: [input]
---

# Verify In The Running App

Verify behavior against the live `wp-dev.ucsc` application, following the recorded launch recipe in `/ucsc-wp-block-dev:run`.

## Universal Command Intake

Apply ADR-011: resolve the target block or app surface, natural-language expected behavior, and optional Jira key/URL from the full input and session context. Merge available acceptance criteria. Ask one concise question only when the behavior to prove or the target surface is missing.

## Build And Launch

1. Use the `run` recipe to inspect prerequisites and start only what is missing.
2. Build the current plugin source in Docker.
3. Confirm the plugin is active and the WordPress services are running.
4. Open the canonical app at `https://wp-dev.ucsc/wp-admin/`.

Do not use Jest, PHP tests, lint, type checks, or a successful build as proof that the user-facing behavior works. Those checks belong to `/ucsc-wp-block-dev:test`.

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

## Result

Report:

- target and behavior checked;
- exact route or editor surface used;
- observed result;
- pass or fail for each acceptance criterion;
- runtime errors or environmental limitations;
- anything not verified.

If runtime verification fails, preserve the evidence and route the problem to `/ucsc-wp-block-dev:fix`. Do not claim success from automated tests alone.
