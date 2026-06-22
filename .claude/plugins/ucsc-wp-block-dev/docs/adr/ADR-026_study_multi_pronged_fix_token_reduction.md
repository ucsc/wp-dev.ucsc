---
title: "ADR-026: Study multi-pronged token reduction for fix mode"
status: Accepted
date: 2026-06-10
---

# ADR-026: Study multi-pronged token reduction for fix mode

## Context

The `fix` skill is the plugin's second-largest command skill at approximately 897 words. Its workflow also influences the larger session cost by prescribing intake, reproduction, source reads, validation, Docker checks, and completion output.

Reducing only the `SKILL.md` length may not reduce total token use. An underspecified workflow can cause broader searches, repeated file reads, unnecessary command output, incorrect patches, or validation reruns. Token optimization must therefore measure the whole fix session while preserving diagnostic accuracy and completed fixes.

## Decision

Study and improve fix-mode token use through separate, measurable workstreams. Establish a baseline before changing the workflow, then evaluate one workstream at a time so its effect can be attributed.

### 1. Loaded instruction size

- Measure the current on-invoke token cost and word count of `fix/SKILL.md`.
- Keep the core workflow short and imperative.
- Move symptom tables, Docker recipes, LDAP notes, cache guidance, and plugin-maintenance guidance into references or owning skills when they are not required on every fix.
- Avoid duplicating guidance already owned by `run`, `test`, block-specific skills, or shared ADRs.

### 2. Intake and routing

- Preserve the target-and-description gate from ADR-007 and ADR-009 because it prevents speculative investigation.
- Reuse target, Jira, PR, error, and prior-session context already supplied; do not ask for or resolve the same context twice.
- Route immediately to the named block and likely layer when the symptom is specific.
- Load `issue-context` or an owning block skill only when its context is needed.

### 3. Evidence funnel

- Start from the user's strongest evidence: exact failure, stack trace, failing test, changed file, URL, or reproducible action.
- Run the narrowest command that can confirm or reject the first hypothesis.
- Prefer bounded output (`rg`, focused tests, relevant log windows, targeted diffs) over repository-wide searches and full logs.
- Broaden investigation only after the current hypothesis is disproved or the evidence identifies a wider dependency.

### 4. Progressive file reading

- Read the failing region and its direct callers or consumers before reading whole files.
- Read full files only when behavior depends on file-wide registration, lifecycle, schema, or state.
- Avoid rereading unchanged content already present in the session.
- Use the block registry and nearest existing pattern to avoid rediscovering known paths.

### 5. Risk-based validation

- Validate the reproduced failure first.
- Add the smallest relevant regression test when practical.
- Run broader build, Docker, browser, or cross-block checks only when the change's blast radius requires them.
- Delegate environment startup and broad smoke testing to `run`; delegate substantial test creation to `test` rather than duplicating those workflows inside `fix`.

### 6. Output and tool-result discipline

- Summarize only actionable command output and findings.
- Do not echo large logs, diffs, or unchanged code into the conversation.
- Keep progress updates and the completion summary proportional to the change.
- Report validation performed and any unverified risk without narrating every investigation step.

## Study Method

Create a small benchmark set covering at least:

1. A focused JavaScript or Jest failure.
2. A PHP render-callback failure.
3. A REST, external-data, or transient-cache failure.
4. A Docker or browser-only runtime regression.

For each case, record:

- fix skill on-invoke tokens;
- total input and output tokens when available;
- tool calls, files read, and repeated reads;
- command-output volume;
- whether the correct root cause and minimal patch were found;
- focused and broad validation performed;
- extra user clarification turns.

Compare the baseline with each proposed workstream independently, then with the combined workflow. Keep a change only when it reduces median token use without reducing fix completion, correctness, security, accessibility, or appropriate test coverage.

## Guardrails

- Do not weaken the required target-and-description intake gate.
- Do not skip reproduction when one is feasible.
- Do not replace focused investigation with unsupported assumptions.
- Do not impose a fixed tool-call or token ceiling that forces incomplete work.
- Do not use subagents solely to shift token usage elsewhere.
- Preserve broader validation for shared code, schema changes, security-sensitive paths, and high-blast-radius fixes.

## Consequences

Fix-mode optimization becomes an evidence-based sequence rather than a one-time shortening exercise. The likely end state is a smaller core `fix` skill with conditional references and narrower default investigation, but implementation follows measured results rather than being assumed by this ADR.
