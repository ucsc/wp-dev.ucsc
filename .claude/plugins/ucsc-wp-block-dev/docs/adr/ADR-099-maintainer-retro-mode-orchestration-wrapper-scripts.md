---
title: "ADR-099: Use orchestrating wrapper scripts to minimize system/tool calls"
status: Accepted
date: 2026-06-24
---

# ADR-099: Use orchestrating wrapper scripts to minimize system/tool calls

## Status

Accepted

## Context

In agentic development environments, each terminal command executed by the agent (using the Bash or run_command tool) requires explicit user approval or permission prompts. Running multiple individual commands in sequence (e.g., checking status, running tests, linting, and checking git state) results in multiple sequential permission prompts, creating high friction for the user and slower execution times.

## Decision

To minimize tool-call frequency and user approval prompts, we will:
1. **Prefer orchestrating scripts** that bundle multiple sequential system calls or validation steps into a single executable command (e.g., a master test script or a sync script).
2. **Design scripts to output clear summaries** of each orchestrated step so the agent can parse all results from a single execution run.
3. **Draft new skill guidelines** to instruct the agent to run the consolidated wrapper command instead of separate discovery/validation commands where appropriate.
4. **Redirect detailed/verbose outputs to logs** rather than stdout. Orchestrating scripts should output a single PASS/FAIL line and the log file path. The agent should only read the log file on `FAIL` to minimize token ingestion and context clutter.

## Consequences

- **Positive:** Dramatically reduces the number of interactive permission prompts the user must approve during a task.
- **Positive:** Speeds up execution by running sequential tasks in a single process invocation.
- **Positive:** Reduces token consumption/burn since the AI does not ingest noisy verbose logs on successful runs.
- **Negative:** Adds complexity to shell scripts that must handle multiple steps and bubble up individual failure exit codes correctly.
