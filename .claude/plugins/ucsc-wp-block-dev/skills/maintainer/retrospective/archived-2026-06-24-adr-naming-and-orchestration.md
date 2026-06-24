# Archived Retrospective — ADR Naming and Script Orchestration (2026-06-24)

Status: Accepted (historical record)
Date: 2026-06-24

## Context

During this session, we established a strict hyphenated format for ADR filenames that includes the target skill name (and mode, if applicable). We also decided to adopt orchestration/wrapper scripts to consolidate sequential commands and reduce the frequency of user approval prompts in agentic workflows.

## Decision

Standardize ADR naming patterns across the entire repository (both active and retired records) to follow `ADR-XXX-<skill>-<mode>-mode-details.md` or `ADR-XXX-<skill>-details.md`, and document wrapper scripting preferences to improve user experience.

## What went well

- Standardized all 98 active and retired ADR filenames successfully on disk with their skill-prefixes.
- Created and executed the `rename-adrs.py` automated script, which performed the renames and updated all reference strings across the entire codebase in one pass.
- Verified that all pytest contracts and plugin best-practice checks passed successfully (123 tests passing).

## What could be improved

- **Temporary script tracking**: Placing `rename_adrs.py` inside `skills/` triggered test failures because it lacked shebangs, help parameters, executable permissions, and SKILL.md references. Re-creating the script as kebab-case `rename-adrs.py` with standard shebangs and help checks resolved these structural compliance errors.

## Follow-ups / Next steps

1. Prefer orchestrating wrapper scripts that consolidate multiple command calls into a single invocation to minimize user permission prompt friction.
2. Ensure any temporary scripts created under `skills/` for bulk operations are either made fully compliant or removed immediately after execution to keep pytest checks green.

Retrospective owner: maintainer
