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
| `develop` | Add or modify block code (PHP, template, JS editor, REST, build).<br>- `develop feature` - Defining and implementing new behavior<br>- `develop fix` - Reproducing and repairing defects |
| `hub` | List all available skills and commands. Use when unsure which skill applies. |
| `maintainer` | Maintain the plugin itself. Invoke as `/ucsc-wp-block-dev:maintainer` for validation, skill upkeep, ADRs, docs, and release readiness; sub-workflow `maintainer/retrospective` captures session lessons. |
| `review` | Review a diff, branch, file, PR, or Jira-scoped change for bugs, regressions, security, a11y, and missing tests. |
| `run` | Build, launch, and drive the plugin in the wp-dev.ucsc Docker environment. |
| `validate` | Create or run automated PHP, Jest, or e2e tests.<br>- `validate create` - Create automated PHP, Jest, or e2e tests<br>- `validate run` - Run existing automated PHP, Jest, or e2e tests |
| `verify` | Live DOM test of a change or acceptance criterion in the running WordPress editor or frontend. |

For block-specific work, resolve the target through
`develop/references/targets.md` and read only the selected target reference.

## Working Rules

- Treat `.claude/plugins/ucsc-wp-block-dev/skills/` as the canonical skill
  source. Do not duplicate skill content in `AGENTS.md` or `.agents/`.
- Keep proposed and experimental skills under
  `.claude/plugins/ucsc-wp-block-dev/contrib/`; only maintainer promotion moves
  a candidate into the live `skills/` inventory.
- Follow WordPress, Gutenberg, PHP, and `@wordpress/scripts` conventions; this
  is not a Laravel application.
- Keep changes scoped to the requested block or workflow.
- Shell safety (macOS zsh, ADR-092): the developer shell is zsh and system bash
  is 3.2. Run scripts via `bash <script>` rather than relying on the interactive
  shell, never put inline `#` comments in commands handed to the user, and avoid
  bash-4-only constructs (`${var,,}`, `declare -A`, `&>>`, `|&`).
- Preserve unrelated user changes in a dirty worktree.
- Prefer focused validation first, then broaden testing when shared behavior or
  multiple blocks are affected.
- Use conventional commit wording when suggesting or creating commits.
- Never run `git push`, `git push --force`, `git push --force-with-lease`, or
  equivalent remote-write operations. Provide the exact command or PR URL for
  the user to run instead.
