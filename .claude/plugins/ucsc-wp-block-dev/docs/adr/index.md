# ADR Index — ucsc-wp-block-dev

Architecture decisions for the `ucsc-wp-block-dev` Claude Code plugin.

## Decisions

Retired (superseded/deprecated/rejected) ADRs are listed in [adrs_retired.md](adrs_retired.md).

| ADR | Title | Status | Date |
|---|---|---|---|
| [ADR-001](ADR-001-maintainer-ucsc-wp-block-dev-plugin-scope.md) | ucsc-wp-block-dev plugin scope — ucsc-gutenberg-blocks is the target | Accepted | 2026-06-08 |
| [ADR-002](ADR-002-maintainer-wp-dev-ucsc-local-environment.md) | wp-dev.ucsc is the local dev environment for block work | Accepted | 2026-06-08 |
| [ADR-003](ADR-003-maintainer-low-token-use.md) | Always prefer low token use | Accepted | 2026-06-09 |
| [ADR-004](ADR-004-maintainer-plugin-validation-workflow.md) | Plugin maintenance and validation via plugin-dev:plugin-validator | Accepted | 2026-06-09 |
| [ADR-006](ADR-006-develop-block-development-examples.md) | Referencing official WordPress Block Development Examples | Accepted | 2026-06-09 |
| [ADR-009](ADR-009-develop-fix-and-develop-require-target-and-description.md) | Fix and develop require a target and work description | Accepted | 2026-06-09 |
| [ADR-013](ADR-013-maintainer-readme-is-first-time-user-reference.md) | README is the canonical first-time user reference | Accepted | 2026-06-10 |
| [ADR-015](ADR-015-maintainer-slide-deck-generated-date.md) | Slide deck always includes a generated date | Accepted | 2026-06-10 |
| [ADR-016](ADR-016-maintainer-avoid-bundling-python-in-plugin.md) | Avoid bundling Python dependencies in the plugin | Accepted | 2026-06-10 |
| [ADR-017](ADR-017-maintainer-agents-uses-symlinks-not-copies.md) | .agents uses symlinks to .claude, not file copies | Accepted | 2026-06-10 |
| [ADR-018](ADR-018-maintainer-owns-slide-deck.md) | Maintainer skill owns the canonical slide deck | Accepted | 2026-06-10 |
| [ADR-019](ADR-019-validate-emits-conventional-commit-checkin-text.md) | Test mode emits a Jira title and conventional-commit description for check-in | Accepted | 2026-06-10 |
| [ADR-020](ADR-020-maintainer-prompts-for-operation.md) | Maintainer mode prompts for the operation instead of auto-running | Accepted | 2026-06-10 |
| [ADR-021](ADR-021-maintainer-accept-jira-id-or-url-in-arguments.md) | Command handlers accept a Jira ID or a full Jira URL in arguments | Accepted | 2026-06-10 |
| [ADR-023](ADR-023-maintainer-always-favor-conventional-commits.md) | Always favor Conventional Commits for commit messages | Accepted | 2026-06-10 |
| [ADR-026](ADR-026-develop-fix-mode-token-reduction.md) | Study multi-pronged token reduction for fix mode | Accepted | 2026-06-10 |
| [ADR-028](ADR-028-maintainer-start-mcp-just-in-time-when-token-efficient.md) | Start MCP just in time when token-efficient | Accepted | 2026-06-10 |
| [ADR-030](ADR-030-maintainer-separate-run-verify-test-and-plugin-validation.md) | Separate run, verify, test, and plugin validation | Accepted | 2026-06-11 |
| [ADR-032](ADR-032-maintainer-skill-support-files-referenced-from-skill-md.md) | Skill support files must be referenced from SKILL.md | Accepted | 2026-06-10 |
| [ADR-033](ADR-033-maintainer-work-list-state-in-claude-config-dir.md) | Store work-list state under CLAUDE_CONFIG_DIR | Accepted | 2026-06-10 |
| [ADR-035](ADR-035-maintainer-warn-on-preexisting-uncommitted-code-once.md) | Warn once about pre-existing uncommitted code | Accepted | 2026-06-12 |
| [ADR-036](ADR-036-develop-separate-fix-and-feature-workflows.md) | Separate fix and feature workflows | Accepted | 2026-06-12 |
| [ADR-037](ADR-037-maintainer-wrap-anthropic-skills-with-context-and-guardrails.md) | Wrap Anthropic skills with UCSC context and guardrails | Accepted | 2026-06-12 |
| [ADR-038](ADR-038-maintainer-skill-mode-contributed-skill-incubation.md) | Contributed skills use proposal and incubator tiers | Accepted | 2026-06-15 |
| [ADR-040](ADR-040-develop-shared-issue-context-reference.md) | Issue context is a shared develop reference | Accepted | 2026-06-15 |
| [ADR-041](ADR-041-develop-block-targets-are-develop-references.md) | Block targets are develop references | Accepted | 2026-06-15 |
| [ADR-042](ADR-042-validate-test-operations-are-references.md) | Test operations are references under test | Accepted | 2026-06-15 |
| [ADR-044](ADR-044-develop-domain-guidance-is-a-develop-reference.md) | Domain guidance is a develop reference | Accepted | 2026-06-15 |
| [ADR-045](ADR-045-maintainer-generate-docs-mode-documentation-reference.md) | Generate docs is a maintainer reference | Accepted | 2026-06-15 |
| [ADR-047](ADR-047-develop-warn-before-editing-on-non-feature-branches.md) | Warn before editing on non-feature branches | Accepted | 2026-06-16 |
| [ADR-048](ADR-048-maintainer-generate-docs-mode-uses-adrs-and-roadmap.md) | Generate docs uses ADRs and includes a roadmap | Accepted | 2026-06-16 |
| [ADR-050](ADR-050-maintainer-no-local-php-python-dependency.md) | No local PHP or Python dependency | Accepted | 2026-06-15 |
| [ADR-055](ADR-055-maintainer-do-not-push-without-checking.md) | Do not push to Git remotes | Accepted | 2026-06-15 |
| [ADR-060](ADR-060-hub-support-hub-to-list-skills.md) | Support :hub to list plugin skills | Accepted | 2026-06-16 |
| [ADR-061](ADR-061-maintainer-remove-map-rely-on-native-discovery.md) | Remove map, rely on native skill discovery | Accepted | 2026-06-16 |
| [ADR-062](ADR-062-maintainer-github-operations-tool-fallbacks.md) | GitHub operations may use CLI, MCP, or REST | Accepted | 2026-06-16 |
| [ADR-063](ADR-063-maintainer-publish-mode-unified-operation.md) | Unify publishing into a publish operation with slides/docs/all targets | Accepted | 2026-06-16 |
| [ADR-066](ADR-066-validate-test-driver.md) | Introduce test/driver.sh script for automated test suites | Accepted | 2026-06-16 |
| [ADR-067](ADR-067-maintainer-skill-mode-sync-inventory.md) | Introduce sync-inventory.sh script to enforce skill inventory consistency | Accepted | 2026-06-16 |
| [ADR-068](ADR-068-maintainer-shared-scripts-and-skills.md) | Allow establishing shared scripts in a shared skill folder | Accepted | 2026-06-16 |
| [ADR-069](ADR-069-maintainer-full-paths-for-generated-files.md) | Offer full path for code review results and context summaries | Accepted | 2026-06-16 |
| [ADR-070](ADR-070-maintainer-align-frontmatter-allowlist-with-official-skills-spec.md) | Align frontmatter allowlist with official Claude Code skills specification | Accepted | 2026-06-16 |
| [ADR-071](ADR-071-maintainer-skill-mode-details-developer-view.md) | Add skill-details operation to show per-skill frontmatter and invocation settings | Accepted | 2026-06-16 |
| [ADR-072](ADR-072-maintainer-skill-display-format.md) | Standardized detailed skill display format for maintainers | Accepted | 2026-06-16 |
| [ADR-073](ADR-073-maintainer-use-claude-for-plugin-operations.md) | Always use .claude for plugin operations; ignore .agents config | Accepted | 2026-06-17 |
| [ADR-074](ADR-074-verify-verify-skill-block-coverage-scope.md) | verify skill block coverage scope — start with ucsc-gutenberg-blocks, extend to ucsc-blocks on onboarding | Accepted | 2026-06-17 |
| [ADR-076](ADR-076-maintainer-token-burn-log.md) | track token-heavy operations in a usage log for retrospective review | Accepted | 2026-06-17 |
| [ADR-078](ADR-078-maintainer-validate-mode-cli-validate-as-primary-check.md) | use claude plugin validate ./path as the primary structural check before the plugin-dev agent | Accepted | 2026-06-17 |
| [ADR-081](ADR-081-maintainer-sub-skill-directories-under-skill.md) | Sub-skill directories nested under a parent skill are permitted | Accepted | 2026-06-18 |
| [ADR-083](ADR-083-maintainer-retro-mode-move-retrospective-under-maintainer.md) | Retrospective is a maintainer sub-skill | Accepted | 2026-06-18 |
| [ADR-084](ADR-084-develop-select-block-target-workflow.md) | Make selecting a block target the primary workflow | Accepted | 2026-06-18 |
| [ADR-085](ADR-085-maintainer-target-plugin.md) | Treat maintainer mode target as the plugin itself | Accepted | 2026-06-18 |
| [ADR-086](ADR-086-maintainer-conventions.md) | ADR and skill conventions (filename, combine-default, implements, launcher) | Accepted | 2026-06-18 |
| [ADR-087](ADR-087-validate-rename-test-skill-to-validate.md) | Rename test skill to validate | Accepted | 2026-06-18 |
| [ADR-088](ADR-088-maintainer-skill-modes-in-public-menu.md) | Skill modes appear as public menu lines | Accepted | 2026-06-22 |
| [ADR-089](ADR-089-maintainer-public-slash.md) | Maintainer is a user-only slash skill with modes | Accepted | 2026-06-22 |
| [ADR-090](ADR-090-develop-fix-mode-infer-block-target-from-cwd.md) | Infer block target from CWD | Accepted | 2026-06-22 |
| [ADR-091](ADR-091-run-run-target-identify-the-run-target-before-invoking-the-driver.md) | Identify the run target before invoking the driver | Accepted | 2026-06-23 |
| [ADR-092](ADR-092-maintainer-shell-safety.md) | Detect the shell and emit zsh-safe terminal commands on macOS | Accepted | 2026-06-23 |
| [ADR-093](ADR-093-develop-session-block-target.md) | Persist the resolved block target across the session for all block skills | Accepted | 2026-06-23 |
| [ADR-094](ADR-094-develop-scripts-expand-harness-path-variables-when-issuing-script-commands-to-claude.md) | Expand harness path variables when issuing script commands to Claude | Accepted | 2026-06-23 |
| [ADR-095](ADR-095-develop-source-base-resolve-a-source-base-and-use-reusable-inspection-scripts-instead-of-hardcoded-paths-and-ad-hoc-find.md) | Resolve a source base and use reusable inspection scripts instead of hardcoded paths and ad-hoc find | Accepted | 2026-06-23 |
| [ADR-096](ADR-096-maintainer-sanity-check-plugin-matches-codebase-stack.md) | Sanity-check that the active plugin matches the codebase stack | Accepted | 2026-06-24 |
| [ADR-097](ADR-097-run-drive-captures-console-errors-screenshot-opt-in.md) | Drive captures DOM and console errors; screenshot is opt-in | Accepted | 2026-06-24 |
| [ADR-099](ADR-099-maintainer-retro-mode-orchestration-wrapper-scripts.md) | Use orchestrating wrapper scripts to minimize system/tool calls | Accepted | 2026-06-24 |


| [ADR-100](ADR-100-feedback-submit-mode-add-a-user-feedback-skill-for-the-plugin.md) | Add a user feedback skill for the plugin | Accepted | 2026-06-24 |
| [ADR-101](ADR-101-validate-single-agent-sequential-suites.md) | validate 'all' mode runs suites sequentially in a single agent | Accepted | 2026-06-24 |
| [ADR-102](ADR-102-validate-session-and-block-specific-test-output.md) | test results, logs, and artifacts must be session and block-target specific | Accepted | 2026-06-24 |
| [ADR-103](ADR-103-validate-verify-stack-dependency.md) | Validate and verify should invoke run skill if docker is down | Accepted | 2026-06-24 |
| [ADR-104](ADR-104-develop-companion-mode-claude-wordpress-skills-is-a-recommended-companion-skillset-for-wp-work.md) | claude-wordpress-skills is a recommended companion skillset for WP work | Accepted | 2026-06-25 |
| [ADR-105](ADR-105-run-runtime-mode-support-multiple-wp-local-runtimes-wp-env-local-wp-engine-beyond-home-rolled-wp-dev-ucsc.md) | Support multiple WP local runtimes (wp-env, Local, WP Engine) beyond home-rolled wp-dev.ucsc | Proposed | 2026-06-25 |
| [ADR-106](ADR-106-maintainer-generate-docs-mode-marker-driven-documentation-harvest-doc-landmarks-like-implements-markers.md) | Marker-driven documentation — harvest doc landmarks like implements: markers | Accepted | 2026-06-25 |
| [ADR-107](ADR-107-maintainer-docs-mode-docs-mode-consolidates-generate-docs-and-publish-with-staleness-detection.md) | docs mode consolidates generate-docs and publish with staleness detection | Accepted | 2026-06-25 |
| [ADR-108](ADR-108-maintainer-plugin-npm-packages.md) | Plugin-scoped npm packages for test and lint tooling without polluting block package.json | Proposed | 2026-06-26 |
| [ADR-109](ADR-109-maintainer-cross-link-guide-and-slides.md) | Cross-link guide and slides so readers can navigate between companion documents | Accepted | 2026-06-26 |
| [ADR-110](ADR-110-maintainer-adr-mode-strict-prefix-naming.md) | Strict ADR filename prefix and lightweight retirement | Accepted | 2026-06-29 |
