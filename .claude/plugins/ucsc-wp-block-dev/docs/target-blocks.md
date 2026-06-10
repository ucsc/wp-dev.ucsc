# Block Targets

Registry of the block targets that command arguments may name (see ADR-024).
Universal command intake (ADR-011) resolves a target token against this table by
slug or alias and routes to the owning skill. Maintainer-owned — update as blocks
are added or renamed.

| Slug | Aliases | Block name | Render class | Owning skill | Data source |
|---|---|---|---|---|---|
| class-schedule | class schedule, schedule, wcsi | `ucscblocks/classschedule` | `classes/ClassSchedule.php` | `class-schedule` | WCSI scheduling app |
| course-catalog | course catalog, catalog | `ucscblocks/coursecatalog` | `classes/CourseCatalog.php` | `course-catalog` | PeopleSoft XML + client-side sort |
| campus-directory | campus directory, directory, people | `ucscblocks/campusdirectory` | `classes/CampusDirectory.php` | `campus-directory` | LDAP / profile rewrite rules |

## Conventions

- **Slug** is the canonical lowercase identifier used in command arguments.
- **Aliases** are alternate spellings or names that resolve to the same slug.
- A target token that matches no slug or alias is treated as part of the
  natural-language request, not as a block target.
- When a user references a block not in this table, ask whether to add it rather
  than guessing its identity.
