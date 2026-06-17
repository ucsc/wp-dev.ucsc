# UCSC WordPress Block Development

This repository contains the local WordPress environment and the
`ucsc-gutenberg-blocks` plugin.

## Primary Target

- Plugin code: `public/wp-content/plugins/ucsc-gutenberg-blocks/`
- Shared development skills:
  `.claude/plugins/ucsc-wp-block-dev/skills/`
- Codex discovers those skills through `.agents/skills/`.

## Skill Routing

Use the matching skill whenever a request falls within its scope. Read the
skill's complete `SKILL.md` before acting.

| Skill | Use for |
| --- | --- |
| `map` | Identify the active app or block and route a new request. |
| `feature` | Add new block behavior through the preferred feature workflow. |
| `develop` | Add a Gutenberg block, feature, API, or editor workflow. |
| `fix` | Diagnose and repair a reported bug or regression. |
| `review` | Review a diff, branch, file, pull request, or Jira-scoped change. |
| `test` | Create or run focused PHP, Jest, or end-to-end tests. |
| `run` | Build, launch, watch, open, or interact with the local WordPress app. |
| `verify` | Confirm acceptance criteria in the running editor or frontend. |
| `documentation` | Regenerate Markdown guide and slide-deck artifacts for Google Docs or Confluence. |
| `blocks` | Apply domain guidance for the `ucsc-gutenberg-blocks` plugin. |
| `maintainer` | Maintain, validate, test, review contributions, promote candidates, or document the `ucsc-wp-block-dev` skill set itself. |

For block-specific work, resolve the target through
`develop/references/targets/index.md` and read only the selected target
reference.

## Working Rules

- Treat `.claude/plugins/ucsc-wp-block-dev/skills/` as the canonical skill
  source. Do not duplicate skill content in `AGENTS.md` or `.agents/`.
- Keep proposed and experimental skills under
  `.claude/plugins/ucsc-wp-block-dev/contrib/`; only maintainer promotion moves
  a candidate into the live `skills/` inventory.
- Follow WordPress, Gutenberg, PHP, and `@wordpress/scripts` conventions; this
  is not a Laravel application.
- Keep changes scoped to the requested block or workflow.
- Preserve unrelated user changes in a dirty worktree.
- Prefer focused validation first, then broaden testing when shared behavior or
  multiple blocks are affected.
- Use conventional commit wording when suggesting or creating commits.
- Never run `git push`, `git push --force`, `git push --force-with-lease`, or
  equivalent remote-write operations. Provide the exact command or PR URL for
  the user to run instead.
