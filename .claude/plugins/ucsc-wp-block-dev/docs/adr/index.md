# ADR Index — ucsc-wp-block-dev

Architecture decisions for the `ucsc-wp-block-dev` Claude Code plugin.

## Decisions

Retired (superseded/deprecated/rejected) ADRs are listed in [adrs_retired.md](adrs_retired.md).

| ADR | Title | Status | Date |
|---|---|---|---|
| [ADR-001](ADR-001_ucsc_wp_block_dev_plugin_scope.md) | ucsc-wp-block-dev plugin scope — ucsc-gutenberg-blocks is the target | Accepted | 2026-06-08 |
| [ADR-002](ADR-002_wp_dev_ucsc_local_environment.md) | wp-dev.ucsc is the local dev environment for block work | Accepted | 2026-06-08 |
| [ADR-003](ADR-003_low_token_use.md) | Always prefer low token use | Accepted | 2026-06-09 |
| [ADR-004](ADR-004_plugin_validation_workflow.md) | Plugin maintenance and validation via plugin-dev:plugin-validator | Accepted | 2026-06-09 |
| [ADR-006](ADR-006_block_development_examples.md) | Referencing official WordPress Block Development Examples | Accepted | 2026-06-09 |
| [ADR-007](ADR-007_fix_requires_user_provided_problem.md) | Fix requires a user-provided concrete problem | Accepted | 2026-06-09 |
| [ADR-008](ADR-008_prefer_jira_id_for_fix_and_develop.md) | Prompt for a Jira ID up front for fix and feature work | Accepted | 2026-06-09 |
| [ADR-009](ADR-009_fix_and_develop_require_target_and_description.md) | Fix and develop require a target and work description | Accepted | 2026-06-09 |
| [ADR-010](ADR-010_jira_prompt_may_repeat_at_phase_completion.md) | Jira prompt may repeat at phase completion | Accepted | 2026-06-09 |
| [ADR-013](ADR-013_readme_is_first_time_user_reference.md) | README is the canonical first-time user reference | Accepted | 2026-06-10 |
| [ADR-015](ADR-015_slide_deck_generated_date.md) | Slide deck always includes a generated date | Accepted | 2026-06-10 |
| [ADR-016](ADR-016_avoid_bundling_python_in_plugin.md) | Avoid bundling Python dependencies in the plugin | Accepted | 2026-06-10 |
| [ADR-017](ADR-017_agents_uses_symlinks_not_copies.md) | .agents uses symlinks to .claude, not file copies | Accepted | 2026-06-10 |
| [ADR-018](ADR-018_maintainer_owns_slide_deck.md) | Maintainer skill owns the canonical slide deck | Accepted | 2026-06-10 |
| [ADR-019](ADR-019_test_emits_conventional_commit_checkin_text.md) | Test mode emits a Jira title and conventional-commit description for check-in | Accepted | 2026-06-10 |
| [ADR-020](ADR-020_maintainer_prompts_for_operation.md) | Maintainer mode prompts for the operation instead of auto-running | Accepted | 2026-06-10 |
| [ADR-021](ADR-021_accept_jira_id_or_url_in_arguments.md) | Command handlers accept a Jira ID or a full Jira URL in arguments | Accepted | 2026-06-10 |
| [ADR-022](ADR-022_accept_github_and_bitbucket_pr_references.md) | Command handlers accept a GitHub or Bitbucket pull-request reference | Accepted | 2026-06-10 |
| [ADR-023](ADR-023_always_favor_conventional_commits.md) | Always favor Conventional Commits for commit messages | Accepted | 2026-06-10 |
| [ADR-025](ADR-025_suggest_atlassian_mcp_for_atlassian_references.md) | Suggest Atlassian MCP when Atlassian references are in use | Accepted | 2026-06-10 |
| [ADR-026](ADR-026_study_multi_pronged_fix_token_reduction.md) | Study multi-pronged token reduction for fix mode | Accepted | 2026-06-10 |
| [ADR-027](ADR-027_study_github_atlassian_mcp_token_cost.md) | Study GitHub and Atlassian MCP token cost | Accepted | 2026-06-10 |
| [ADR-028](ADR-028_start_mcp_just_in_time_when_token_efficient.md) | Start MCP just in time when token-efficient | Accepted | 2026-06-10 |
| [ADR-030](ADR-030_separate_run_verify_test_and_plugin_validation.md) | Separate run, verify, test, and plugin validation | Accepted | 2026-06-11 |
| [ADR-032](ADR-032_skill_support_files_referenced_from_skill_md.md) | Skill support files must be referenced from SKILL.md | Accepted | 2026-06-10 |
| [ADR-033](ADR-033_work_list_state_in_claude_config_dir.md) | Store work-list state under CLAUDE_CONFIG_DIR | Accepted | 2026-06-10 |
| [ADR-034](ADR-034_defer_github_atlassian_mcp_login_until_needed.md) | Defer GitHub and Atlassian MCP login until needed | Accepted | 2026-06-12 |
| [ADR-035](ADR-035_warn_on_preexisting_uncommitted_code_once.md) | Warn once about pre-existing uncommitted code | Accepted | 2026-06-12 |
| [ADR-036](ADR-036_separate_fix_and_feature_workflows.md) | Separate fix and feature workflows | Accepted | 2026-06-12 |
| [ADR-037](ADR-037_wrap_anthropic_skills_with_context_and_guardrails.md) | Wrap Anthropic skills with UCSC context and guardrails | Accepted | 2026-06-12 |
| [ADR-038](ADR-038_contributed_skill_incubation.md) | Contributed skills use proposal and incubator tiers | Accepted | 2026-06-15 |
| [ADR-040](ADR-040_shared_issue_context_reference.md) | Issue context is a shared develop reference | Accepted | 2026-06-15 |
| [ADR-041](ADR-041_block_targets_are_develop_references.md) | Block targets are develop references | Accepted | 2026-06-15 |
| [ADR-042](ADR-042_test_operations_are_references.md) | Test operations are references under test | Accepted | 2026-06-15 |
| [ADR-044](ADR-044_domain_guidance_is_a_develop_reference.md) | Domain guidance is a develop reference | Accepted | 2026-06-15 |
| [ADR-045](ADR-045_documentation_is_a_maintainer_reference.md) | Generate docs is a maintainer reference | Accepted | 2026-06-15 |
| [ADR-047](ADR-047_warn_before_editing_on_non_feature_branches.md) | Warn before editing on non-feature branches | Accepted | 2026-06-16 |
| [ADR-048](ADR-048_generate_docs_uses_adrs_and_roadmap.md) | Generate docs uses ADRs and includes a roadmap | Accepted | 2026-06-16 |
| [ADR-050](ADR-050_no_local_php_python_dependency.md) | No local PHP or Python dependency | Accepted | 2026-06-15 |
| [ADR-051](ADR-051_offer_automatic_commit.md) | Offer to automatically commit in addition to providing message text | Accepted | 2026-06-15 |
| [ADR-052](ADR-052_allow_co_authored_by_ai.md) | Allow Co-authored-by AI in commit messages | Accepted | 2026-06-15 |
| [ADR-053](ADR-053_tag_commits_with_skillset.md) | Tag commits with ucsc-wp-block-dev skillset use | Accepted | 2026-06-15 |
| [ADR-054](ADR-054_offer_to_create_pull_requests.md) | Offer to create pull requests | Accepted | 2026-06-15 |
| [ADR-055](ADR-055_do_not_push_without_checking.md) | Do not push to Git remotes | Accepted | 2026-06-15 |
| [ADR-056](ADR-056_github_only_operations.md) | Do not offer operations on non-GitHub repositories | Accepted | 2026-06-15 |
| [ADR-057](ADR-057_do_not_inspect_parent_git_repos.md) | Do not inspect parent Git repos | Accepted | 2026-06-15 |
| [ADR-058](ADR-058_optimize_for_low_token_use.md) | Optimize for low token use, single-agent mode by default | Accepted | 2026-06-15 |
| [ADR-059](ADR-059_offer_retrospective_for_skill_and_script_enrichment.md) | Offer a retrospective for skill and script enrichment | Accepted | 2026-06-16 |
| [ADR-060](ADR-060_support_hub_to_list_skills.md) | Support :hub to list plugin skills | Accepted | 2026-06-16 |
| [ADR-061](ADR-061_remove_map_rely_on_native_discovery.md) | Remove map, rely on native skill discovery | Accepted | 2026-06-16 |
| [ADR-062](ADR-062_github_operations_tool_fallbacks.md) | GitHub operations may use CLI, MCP, or REST | Accepted | 2026-06-16 |
| [ADR-063](ADR-063_unified_publish_operation.md) | Unify publishing into a publish operation with slides/docs/all targets | Accepted | 2026-06-16 |
| [ADR-064](ADR-064_agent_backed_checks_are_opt_in.md) | Agent-backed maintainer checks are opt-in, not default | Accepted | 2026-06-16 |
| [ADR-065](ADR-065_new_adr_script.md) | Introduce automated ADR creation script new_adr.sh | Accepted | 2026-06-16 |
| [ADR-066](ADR-066_test_driver.md) | Introduce test/driver.sh script for automated test suites | Accepted | 2026-06-16 |
| [ADR-067](ADR-067_sync_inventory.md) | Introduce sync_inventory.sh script to enforce skill inventory consistency | Accepted | 2026-06-16 |
| [ADR-068](ADR-068_shared_scripts_and_skills.md) | Allow establishing shared scripts in a shared skill folder | Accepted | 2026-06-16 |
| [ADR-069](ADR-069_full_paths_for_generated_files.md) | Offer full path for code review results and context summaries | Accepted | 2026-06-16 |
| [ADR-070](ADR-070_align_frontmatter_allowlist_with_official_skills_spec.md) | Align frontmatter allowlist with official Claude Code skills specification | Accepted | 2026-06-16 |
| [ADR-071](ADR-071_skill_details_developer_view.md) | Add skill-details operation to show per-skill frontmatter and invocation settings | Accepted | 2026-06-16 |
| [ADR-072](ADR-072_skill_display_format.md) | Standardized detailed skill display format for maintainers | Accepted | 2026-06-16 |
| [ADR-073](ADR-073_use_claude_for_plugin_operations.md) | Always use .claude for plugin operations; ignore .agents config | Accepted | 2026-06-17 |
| [ADR-074](ADR-074_verify_skill_block_coverage_scope.md) | verify skill block coverage scope — start with ucsc-gutenberg-blocks, extend to ucsc-blocks on onboarding | Accepted | 2026-06-17 |
| [ADR-075](ADR-075_prefer_single_agent_mode.md) | prefer single-agent mode — avoid multi-agent pipelines unless the task requires parallelism | Accepted | 2026-06-17 |
| [ADR-076](ADR-076_token_burn_log.md) | track token-heavy operations in a usage log for retrospective review | Accepted | 2026-06-17 |
| [ADR-077](ADR-077_lessons_learned_to_scripts_and_skills.md) | always consider lessons learned and token-reduction opportunities via scripts and skill improvements | Accepted | 2026-06-17 |
| [ADR-078](ADR-078_cli_validate_as_primary_check.md) | use claude plugin validate ./path as the primary structural check before the plugin-dev agent | Accepted | 2026-06-17 |
| [ADR-079](ADR-079_plugin_dev_companion_plugin.md) | Anthropic plugin-dev is the upstream reference and optional Tier 2 companion | Accepted | 2026-06-17 |
| [ADR-080](ADR-080_agents_md_skill_inventory.md) | Keep AGENTS.md synchronized with live skill inventory | Accepted | 2026-06-17 |
| [ADR-081](ADR-081_sub_skill_directories_under_skill.md) | Sub-skill directories nested under a parent skill are permitted | Accepted | 2026-06-18 |
| [ADR-083](ADR-083_move_retrospective_under_maintainer.md) | Retrospective is a maintainer sub-skill | Accepted | 2026-06-18 |
| [ADR-084](ADR-084_select_block_target_workflow.md) | Make selecting a block target the primary workflow | Accepted | 2026-06-18 |
| [ADR-085](ADR-085_maintainer_target_plugin.md) | Treat maintainer mode target as the plugin itself | Accepted | 2026-06-18 |
| [ADR-086](ADR-086_maintainer_conventions.md) | ADR and skill conventions (filename, combine-default, implements, launcher) | Accepted | 2026-06-18 |
| [ADR-087](ADR-087_rename_test_skill_to_validate.md) | Rename test skill to validate | Accepted | 2026-06-18 |
| [ADR-088](ADR-088_skill_modes_in_public_menu.md) | Skill modes appear as public menu lines | Accepted | 2026-06-22 |
| [ADR-089](ADR-089_maintainer_public_slash.md) | Maintainer is a user-only slash skill with modes | Accepted | 2026-06-22 |
| [ADR-090](ADR-090_develop_fix_infer_block_target_from_cwd.md) | Infer block target from CWD | Accepted | 2026-06-22 |
| [ADR-091](ADR-091_run_target_identify_the_run_target_before_invoking_the_driver.md) | Identify the run target before invoking the driver | Accepted | 2026-06-23 |
| [ADR-092](ADR-092_shell_safety.md) | Detect the shell and emit zsh-safe terminal commands on macOS | Accepted | 2026-06-23 |
| [ADR-093](ADR-093_session_block_target.md) | Persist the resolved block target across the session for all block skills | Accepted | 2026-06-23 |
| [ADR-094](ADR-094_develop_scripts_expand_harness_path_variables_when_issuing_script_commands_to_claude.md) | Expand harness path variables when issuing script commands to Claude | Accepted | 2026-06-23 |
| [ADR-095](ADR-095_develop_source_base_resolve_a_source_base_and_use_reusable_inspection_scripts_instead_of_hardcoded_paths_and_ad_hoc_find.md) | Resolve a source base and use reusable inspection scripts instead of hardcoded paths and ad-hoc find | Accepted | 2026-06-23 |
