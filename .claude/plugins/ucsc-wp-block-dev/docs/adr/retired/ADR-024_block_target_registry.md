---
title: "ADR-024: Command arguments may name a block target, resolved against a block registry"
status: Superseded
date: 2026-06-10
---

# ADR-024: Block target argument and registry

Superseded by ADR-041. Targets are now resolved through
`skills/develop/references/targets/index.md` and load target references rather
than top-level target skills.

## Context

[ADR-011](ADR-011_universal_command_intake.md) lists a "target" among the things command intake resolves, but there was no canonical list of the blocks this plugin actually targets. The three primary blocks — **Class Schedule**, **Course Catalog**, and **Campus Directory** — each have their own owning skill, render class, and external data source, and users reference them by short name. Handlers need one shared way to recognize them instead of guessing per command.

## Decision

Command arguments may include a **block target** token in any position, alongside the natural-language request, optional Jira reference ([ADR-021](../ADR-021_accept_jira_id_or_url_in_arguments.md)), and optional PR reference ([ADR-022](../ADR-022_accept_github_and_bitbucket_pr_references.md)).

Known block targets are maintained in a single registry: `docs/target-blocks.md`. It records each block's slug, aliases, block name (`ucscblocks/*`), render class, owning skill, and data source. Universal command intake resolves a target token against that registry by **slug or alias** and routes to the owning skill:

| Slug | Block name | Owning skill |
|---|---|---|
| class-schedule | `ucscblocks/classschedule` | `class-schedule` |
| course-catalog | `ucscblocks/coursecatalog` | `course-catalog` |
| campus-directory | `ucscblocks/campusdirectory` | `campus-directory` |

A token that matches no entry is treated as part of the natural-language request, not as a block target. When a user names a block absent from the registry, the handler asks whether to add it rather than inventing its identity.

## Consequences

There is one authoritative list of recognized blocks, so every command resolves a target argument the same way and routes to the correct per-block skill. New blocks are onboarded by editing one file, and unknown tokens degrade gracefully into the natural-language request.
