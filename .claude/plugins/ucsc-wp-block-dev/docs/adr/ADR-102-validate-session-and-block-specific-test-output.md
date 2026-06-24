---
title: "ADR-102: test results, logs, and artifacts must be session and block-target specific"
status: Accepted
date: 2026-06-24
supersedes: []
related: ["ADR-066", "ADR-093", "ADR-101"]
---

# ADR-102: test results, logs, and artifacts must be session and block-target specific

## Status

Accepted

## Context

Previous iterations of the test runners and validation scripts (such as the repo-local `bin/validate-*.sh` referenced in ADR-066) wrote output to static global paths like `/tmp/ucsc-validate-php.log`. Similarly, ad-hoc agent workflows sometimes write markdown summaries or JSON test data to static filenames like `validation-results.md` or `/tmp/test-output.json`.

This approach creates significant problems:
1. **Stomping:** Concurrent sessions or parallel CI runs using the same runner will overwrite each other's logs.
2. **Stale Data:** If a test driver fails to execute but the script reads a pre-existing static log file, it may erroneously report success or failure based on a previous run's stale cache.
3. **Cross-contamination:** Output for one block target (e.g., `ucsc-events`) could be mistaken for the output of another block target (e.g., `calendar-feed`) if the filename does not distinguish between them.

## Decision

All generated test outputs—including raw console logs, structured data (JSON/XML), and generated markdown artifacts—must be explicitly scoped to ensure uniqueness.

1. **Session Isolation:** Scripts writing to shared host directories (like `/tmp`) must incorporate a session ID, timestamp, or process ID into the filename (e.g., `/tmp/ucsc-test-${SESSION_ID:-$$}.log`).
2. **Block Target Isolation:** When output is specific to a block target, the block slug must be included in the artifact name (e.g., `validate-results-calendar-feed.md` rather than `validate-results.md`).
3. **Agent Artifacts:** When the agent creates markdown files or scratch scripts, it must leverage the inherent isolation of the `conversation-id` artifact directory (`<appDataDir>/brain/<conversation-id>/`) and name files specifically for the target (e.g., `test-report-<block-target>.md`).
4. **No Stale Reads:** Scripts that parse logs to generate summaries must ensure the log file is freshly created for the current run, typically by ensuring unique paths per run or explicitly cleaning up known static paths before execution.

## Consequences

- **Positive:** Eliminates race conditions and cross-session contamination.
- **Positive:** Prevents false positives/negatives caused by reading stale logs from aborted runs.
- **Positive:** Clear, traceable history of test results mapped to specific block targets and agent conversations.
- **Negative:** Leaves orphaned log files in `/tmp` if cleanup is not aggressively handled. (Drivers should use `trap` for cleanup of temp files unless explicitly preserved for debugging).
