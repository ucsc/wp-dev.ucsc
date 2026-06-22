---
name: retrospective
description: Capture lessons learned from the current working session into the ucsc-wp-block-dev skill files while context is still live. Use at the end of a fix, feature, review, or run session, or whenever new patterns, gotchas, or domain knowledge should be persisted. Do not use to produce a task summary for the user — use for enriching skill references only.
---

# Retrospective — Capture Lessons Into Skills

## Implements

implements: ADR-059-RETROSPECTIVE-SKILL-ENRICHMENT, ADR-077-RETROSPECTIVE-LESSONS, ADR-083-MAINTAINER-RETROSPECTIVE

Run this at the end of any meaningful work session to persist what was learned
before the context window closes. Keep it token-light: grep before reading,
write only what isn't already documented.

## When To Run

- At the conclusion of every fix, feature, review, or run session when there
  are reusable lessons to preserve (per ADR-059).
- When a new pattern, gotcha, or domain boundary was discovered.
- When an existing skill reference was found to be missing, wrong, or misleading.

## Workflow

### 1. Identify What Was Learned

In a few sentences, answer:

- What pattern or technique did this session introduce or validate?
- What assumption proved wrong or required a workaround?
- Which skill or reference was the insight closest to?

Keep this step purely mental — no tool calls yet.

### 2. Check If It Is Already Documented

Grep the most likely target reference before reading the whole file:

```bash
grep -n "keyword" .claude/plugins/ucsc-wp-block-dev/skills/<target>/references/<file>.md
```

If the lesson is already captured, stop — do not duplicate.

### 3. Write The Lesson

Append to the closest existing reference file. Prefer these targets in order:

| Lesson type | Target file |
|---|---|
| PHP test pattern, stub recipe, guard-condition checklist | `test/references/create.md` |
| Running PHP or Jest tests via Docker | `test/references/run.md` |
| WordPress routing, FSE theme, block rendering | `develop/references/domain-blocks.md` |
| Fix diagnostic, known transient/cache edge case | `develop/fix/SKILL.md` recovery or gotchas section |
| Run / environment / Docker edge case | `run/SKILL.md` Recovery section |
| Broad domain knowledge spanning multiple skills | `develop/references/domain-blocks.md` |
| Onboarding a new block target | `develop/references/domain-add-target.md` |
| Bulk link updates after file renames/moves | `maintainer/references/refactor-links.md` |

Use a concise bullet under a clearly named `## Lessons Learned` or existing
`## Gotchas` heading. If no such heading exists, add one at the end of the file.

Write in present tense, imperative where possible. Include a concrete example
or command when the lesson is procedural.

### 4. Create An ADR If The Lesson Is A Decision

If the lesson represents a deliberate architectural or workflow decision (not
just a tip or gotcha), create a new ADR in `docs/adr/`:

```text
ADR-NNN_skill_mode_detail.md
```

With proper frontmatter (`title`, `status: Accepted`, `date`), then add it to
`docs/adr/index.md`. See existing ADRs for the format.

### 5. Consider Scripts and Skill Improvements (ADR-077)

Ask three questions before closing (answer in one sentence each; skip if
nothing applies):

1. **Script candidate** — Was there a multi-step manual operation that could be
   automated? If yes, write a script under `skills/<skill>/scripts/` and link
   it from `SKILL.md`.
2. **Skill improvement candidate** — Was there guidance the AI re-derived that
   should be captured in a reference file or `SKILL.md` section? If yes, add it.
3. **Token-reduction candidate** — Did a token-heavy operation (see ADR-076 log
   at `logs/token-usage.log`) surface something a cheaper structural test could
   catch? If yes, add or improve the test.

If none apply, state "no script/skill/test improvements this session" and move on.

### 6. Verify Nothing Is Broken

Run the reference checker to confirm no unreferenced files were added:

```bash
bash .claude/plugins/ucsc-wp-block-dev/skills/maintainer/scripts/check_skill_references.sh
```

If a new reference file was added (not just an existing file updated), also
link it from the owning skill's `SKILL.md`.

### 7. Report

Tell the user:
- Which file(s) were updated and what was added (one line each).
- Whether an ADR was created.
- The `check_skill_references.sh` result.

Do not summarize the entire session — focus only on what changed in the skills.
