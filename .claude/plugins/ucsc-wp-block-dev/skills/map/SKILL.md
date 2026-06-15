---
name: map
description: Map a UCSC WordPress block-development request to the right ucsc-wp-block-dev skill. Use as the entry point when the target workflow is unclear, when identifying the active app or block, or when routing a natural-language request or Jira reference.
---

# UCSC WordPress Block Development Map

Use this as the portable entry point for `ucsc-wp-block-dev`.

## Universal Input Routing

Apply ADR-011: parse the full input by meaning as a possible target,
natural-language request, and Jira key/URL, regardless of order. Preserve the
target, request, and Jira values when handing work to another skill. Ask one
concise question only when the active app or intended outcome cannot be
resolved.

## Identify the Active App

Resolve the app before routing:

1. A working directory containing `docker-compose.yml` and
   `public/wp-content/plugins/ucsc-gutenberg-blocks/` is the `wp-dev.ucsc` app
   root.
2. A working directory inside
   `public/wp-content/plugins/ucsc-gutenberg-blocks/` belongs to that app.
3. Otherwise ask which WordPress app or folder is the target.

State the app, stack, and current directory in one short context receipt.

## Skill Map

| Skill | Route when the user wants to |
| --- | --- |
| `feature` | Add new block behavior through the preferred feature workflow. |
| `develop` | Use the existing development workflow during migration. |
| `fix` | Diagnose and repair incorrect behavior. |
| `test` | Create or run PHP, Jest, or end-to-end tests. |
| `review` | Review a diff, branch, file, pull request, or block. |
| `run` | Build, launch, watch, open, or interact with WordPress. |
| `verify` | Prove acceptance criteria in the running editor or frontend. |
| `maintainer` | Maintain, validate, or extend this skill set. |
When work touches `ucsc-gutenberg-blocks`, load domain guidance from
[`../develop/references/domain/blocks.md`](../develop/references/domain/blocks.md)
inside the selected workflow. `blocks` is intentionally a hidden reference, not
a top-level skill.

When the request is to regenerate Markdown documentation artifacts, route to
`maintainer` and its
[`../maintainer/references/documentation/documentation.md`](../maintainer/references/documentation/documentation.md)
reference. `documentation` is intentionally a hidden reference, not a top-level
skill.

Route by intent rather than command syntax. A clear bug routes to `fix`; new
behavior routes to `feature`; proving completed behavior routes to `verify`.
Targets are selected inside `develop` and resolved from its target references,
not routed as top-level skills.
