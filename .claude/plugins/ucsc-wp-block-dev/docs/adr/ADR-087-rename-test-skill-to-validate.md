ADR-087: Rename `test` skill to `validate`

Status: Accepted
Date: 2026-06-18

Context

The plugin skills inventory used `test` for automated test suite runs. To better reflect intent and to align with maintainer/validate naming (validate equals asserting correctness, including CI and manual checks), the skill is renamed to `validate`.

Decision

Rename skill directory `skills/test` to `skills/validate`, update skill frontmatter and references, and update user-facing docs to refer to `validate`.

Consequences

- Backwards-incompatible for scripts or bookmarks referencing the old path; maintainers should update saved driver invocations.
- Improves clarity: `validate` covers running automated tests and validation checks; `verify` remains for live runtime verification.

Follow-ups

- Update any external integrations or CI jobs that reference the old path.
- Add a short note in release/upgrade docs about the path change.

