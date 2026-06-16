# ADR Index — ucsc-wp-block-dev

Architecture decisions for the `ucsc-wp-block-dev` Claude Code plugin.

## Decisions

| ADR | Title | Status | Date |
|---|---|---|---|
| [ADR-001](ADR-001-ucsc-wp-block-dev-plugin-scope.md) | ucsc-wp-block-dev plugin scope — ucsc-gutenberg-blocks is the target | Accepted | 2026-06-08 |
| [ADR-002](ADR-002-wp-dev-ucsc-local-environment.md) | wp-dev.ucsc is the local dev environment for block work | Accepted | 2026-06-08 |
| [ADR-003](ADR-003-low-token-use.md) | Always prefer low token use | Accepted | 2026-06-09 |
| [ADR-004](ADR-004-plugin-validation-workflow.md) | Plugin maintenance and validation via plugin-dev:plugin-validator | Accepted | 2026-06-09 |
| [ADR-005](ADR-005-skill-frontmatter-convention.md) | Skill frontmatter uses supported skill and command fields | Superseded | 2026-06-09 |
| [ADR-006](ADR-006-block-development-examples.md) | Referencing official WordPress Block Development Examples | Accepted | 2026-06-09 |
| [ADR-007](ADR-007-fix-requires-user-provided-problem.md) | Fix requires a user-provided concrete problem | Accepted | 2026-06-09 |
| [ADR-008](ADR-008-prefer-jira-id-for-fix-and-develop.md) | Prompt for a Jira ID up front for fix and feature work | Accepted | 2026-06-09 |
| [ADR-009](ADR-009-fix-and-develop-require-target-and-description.md) | Fix and develop require a target and work description | Accepted | 2026-06-09 |
| [ADR-010](ADR-010-jira-prompt-may-repeat-at-phase-completion.md) | Jira prompt may repeat at phase completion | Accepted | 2026-06-09 |
| [ADR-011](ADR-011-universal-command-intake.md) | Every workflow resolves target, natural-language request, and optional Jira context | Superseded | 2026-06-09 |
| [ADR-012](ADR-012-setup-capability-summary.md) | Setup provides a simple capability summary | Superseded | 2026-06-09 |
| [ADR-013](ADR-013-readme-is-first-time-user-reference.md) | README is the canonical first-time user reference | Accepted | 2026-06-10 |
| [ADR-014](ADR-014-slide-deck-documents-all-skills.md) | Slide deck documents all top-level skills | Superseded | 2026-06-10 |
| [ADR-015](ADR-015-slide-deck-generated-date.md) | Slide deck always includes a generated date | Accepted | 2026-06-10 |
| [ADR-016](ADR-016-avoid-bundling-python-in-plugin.md) | Avoid bundling Python dependencies in the plugin | Accepted | 2026-06-10 |
| [ADR-017](ADR-017-agents-uses-symlinks-not-copies.md) | .agents uses symlinks to .claude, not file copies | Accepted | 2026-06-10 |
| [ADR-018](ADR-018-maintainer-owns-slide-deck.md) | Maintainer skill owns the canonical slide deck | Accepted | 2026-06-10 |
| [ADR-019](ADR-019-test-emits-conventional-commit-checkin-text.md) | Test mode emits a Jira title and conventional-commit description for check-in | Accepted | 2026-06-10 |
| [ADR-020](ADR-020-maintainer-prompts-for-operation.md) | Maintainer mode prompts for the operation instead of auto-running | Accepted | 2026-06-10 |
| [ADR-021](ADR-021-accept-jira-id-or-url-in-arguments.md) | Command handlers accept a Jira ID or a full Jira URL in arguments | Accepted | 2026-06-10 |
| [ADR-022](ADR-022-accept-github-and-bitbucket-pr-references.md) | Command handlers accept a GitHub or Bitbucket pull-request reference | Accepted | 2026-06-10 |
| [ADR-023](ADR-023-always-favor-conventional-commits.md) | Always favor Conventional Commits for commit messages | Accepted | 2026-06-10 |
| [ADR-024](ADR-024-block-target-registry.md) | Command arguments may name a block target, resolved against a block registry | Superseded | 2026-06-10 |
| [ADR-025](ADR-025-suggest-atlassian-mcp-for-atlassian-references.md) | Suggest Atlassian MCP when Atlassian references are in use | Accepted | 2026-06-10 |
| [ADR-026](ADR-026-study-multi-pronged-fix-token-reduction.md) | Study multi-pronged token reduction for fix mode | Accepted | 2026-06-10 |
| [ADR-027](ADR-027-study-github-atlassian-mcp-token-cost.md) | Study GitHub and Atlassian MCP token cost | Accepted | 2026-06-10 |
| [ADR-028](ADR-028-start-mcp-just-in-time-when-token-efficient.md) | Start MCP just in time when token-efficient | Accepted | 2026-06-10 |
| [ADR-029](ADR-029-fix-and-develop-offer-conventional-commit-message.md) | Offer Conventional Commit syntax after fixes, features, and reviews | Superseded | 2026-06-10 |
| [ADR-030](ADR-030-separate-run-verify-test-and-plugin-validation.md) | Separate run, verify, test, and plugin validation | Accepted | 2026-06-11 |
| [ADR-031](ADR-031-test-clarifies-type-and-operation.md) | Test clarifies type and operation | Superseded | 2026-06-11 |
| [ADR-032](ADR-032-skill-support-files-referenced-from-skill-md.md) | Skill support files must be referenced from SKILL.md | Accepted | 2026-06-10 |
| [ADR-033](ADR-033-work-list-state-in-claude-config-dir.md) | Store work-list state under CLAUDE_CONFIG_DIR | Accepted | 2026-06-10 |
| [ADR-034](ADR-034-defer-github-atlassian-mcp-login-until-needed.md) | Defer GitHub and Atlassian MCP login until needed | Accepted | 2026-06-12 |
| [ADR-035](ADR-035-warn-on-preexisting-uncommitted-code-once.md) | Warn once about pre-existing uncommitted code | Accepted | 2026-06-12 |
| [ADR-036](ADR-036-separate-fix-and-feature-workflows.md) | Separate fix and feature workflows | Accepted | 2026-06-12 |
| [ADR-037](ADR-037-wrap-anthropic-skills-with-context-and-guardrails.md) | Wrap Anthropic skills with UCSC context and guardrails | Accepted | 2026-06-12 |
| [ADR-038](ADR-038-contributed-skill-incubation.md) | Contributed skills use proposal and incubator tiers | Accepted | 2026-06-15 |
| [ADR-039](ADR-039-skills-first-map-entry-point.md) | Use a skills-first surface with map as the entry point | Accepted | 2026-06-15 |
| [ADR-040](ADR-040-shared-issue-context-reference.md) | Issue context is a shared develop reference | Accepted | 2026-06-15 |
| [ADR-041](ADR-041-block-targets-are-develop-references.md) | Block targets are develop references | Accepted | 2026-06-15 |
| [ADR-042](ADR-042-test-operations-are-references.md) | Test operations are references under test | Accepted | 2026-06-15 |
| [ADR-043](ADR-043-documentation-skill-generates-markdown-artifacts.md) | Documentation skill generates portable Markdown artifacts | Superseded | 2026-06-15 |
| [ADR-044](ADR-044-domain-guidance-is-a-develop-reference.md) | Domain guidance is a develop reference | Accepted | 2026-06-15 |
| [ADR-045](ADR-045-documentation-is-a-maintainer-reference.md) | Generate docs is a maintainer reference | Accepted | 2026-06-15 |
| [ADR-046](ADR-046-maintainer-is-a-hidden-manual-skill.md) | Maintainer is a hidden manual skill | Accepted | 2026-06-15 |
| [ADR-047](ADR-047-warn-before-editing-on-non-feature-branches.md) | Warn before editing on non-feature branches | Accepted | 2026-06-16 |
| [ADR-048](ADR-048-generate-docs-uses-adrs-and-roadmap.md) | Generate docs uses ADRs and includes a roadmap | Accepted | 2026-06-16 |
| [ADR-049](ADR-049-perform-retrospective-after-tasks.md) | Perform a retrospective after tasks to save lessons learned | Accepted | 2026-06-15 |
| [ADR-050](ADR-050-no-local-php-python-dependency.md) | No local PHP or Python dependency | Accepted | 2026-06-15 |
| [ADR-051](ADR-051-offer-automatic-commit.md) | Offer to automatically commit in addition to providing message text | Accepted | 2026-06-15 |
| [ADR-052](ADR-052-allow-co-authored-by-ai.md) | Allow Co-authored-by AI in commit messages | Accepted | 2026-06-15 |
| [ADR-053](ADR-053-tag-commits-with-skillset.md) | Tag commits with ucsc-wp-block-dev skillset use | Accepted | 2026-06-15 |
| [ADR-054](ADR-054-offer-to-create-pull-requests.md) | Offer to create pull requests | Accepted | 2026-06-15 |
| [ADR-055](ADR-055-do-not-push-without-checking.md) | Generally do not push to Git, never push without checking | Accepted | 2026-06-15 |
| [ADR-056](ADR-056-github-only-operations.md) | Do not offer operations on non-GitHub repositories | Accepted | 2026-06-15 |
| [ADR-057](ADR-057-do-not-inspect-parent-git-repos.md) | Do not inspect parent Git repos | Accepted | 2026-06-15 |
| [ADR-058](ADR-058-optimize-for-low-token-use.md) | Optimize for low token use, prefer single agent | Accepted | 2026-06-15 |
