"""Tests for ucsc-wp-block-dev plugin structural integrity.

Validates plugin.json, skill frontmatter, and ADR index consistency.
"""

import json
import re
from pathlib import Path

import pytest

PLUGIN_ROOT = Path(__file__).resolve().parent.parent
PROJECT_ROOT = PLUGIN_ROOT.parents[2]
SKILLS_DIR = PLUGIN_ROOT / "skills"
CONTRIB_DIR = PLUGIN_ROOT / "contrib"
ADR_DIR = PLUGIN_ROOT / "docs" / "adr"
SLIDE_DECK = SKILLS_DIR / "maintainer" / "assets" / "ucsc_wp_block_dev_presentation.md"
PUBLISHER = PROJECT_ROOT / ".claude" / "scripts" / "publish_to_gdoc.py"
PLUGIN_NAME = "ucsc-wp-block-dev"
FORBIDDEN_PLUGIN_NAME = "ucsc-" + "wordpress-block-dev"
EXPECTED_LIVE_SKILLS = {
    "develop",
    "feature",
    "fix",
    "maintainer",
    "map",
    "review",
    "run",
    "test",
    "verify",
}
EXPECTED_PUBLIC_WORKFLOW_SKILLS = EXPECTED_LIVE_SKILLS - {"maintainer"}


class TestPluginJson:
    def test_exists(self):
        assert (PLUGIN_ROOT / ".claude-plugin" / "plugin.json").exists()

    def test_valid_json(self):
        text = (PLUGIN_ROOT / ".claude-plugin" / "plugin.json").read_text()
        data = json.loads(text)
        assert isinstance(data, dict)

    def test_required_fields(self):
        data = json.loads((PLUGIN_ROOT / ".claude-plugin" / "plugin.json").read_text())
        assert "name" in data
        assert "version" in data
        assert "description" in data

    def test_name_is_wp_blocks(self):
        data = json.loads((PLUGIN_ROOT / ".claude-plugin" / "plugin.json").read_text())
        assert data["name"] == PLUGIN_NAME

    def test_version_is_semver(self):
        data = json.loads((PLUGIN_ROOT / ".claude-plugin" / "plugin.json").read_text())
        assert re.match(r"^\d+\.\d+\.\d+$", data["version"])

    def test_keywords_include_wordpress(self):
        data = json.loads((PLUGIN_ROOT / ".claude-plugin" / "plugin.json").read_text())
        keywords = data.get("keywords", [])
        assert any(k in keywords for k in ["wordpress", "gutenberg", "blocks"]), (
            "plugin.json keywords should include at least one of: wordpress, gutenberg, blocks"
        )

    def test_author_field_structure(self):
        data = json.loads((PLUGIN_ROOT / ".claude-plugin" / "plugin.json").read_text())
        assert "author" in data
        assert isinstance(data["author"], dict)
        assert "name" in data["author"]
        assert "email" in data["author"]


class TestSkillFrontmatter:
    """Every SKILL.md must have valid YAML frontmatter with name and description."""

    @pytest.fixture()
    def skill_files(self):
        return sorted(SKILLS_DIR.rglob("SKILL.md"))

    def test_skills_exist(self, skill_files):
        assert len(skill_files) > 0, "No SKILL.md files found"

    def test_all_have_frontmatter(self, skill_files):
        for path in skill_files:
            text = path.read_text()
            assert text.startswith("---"), f"{path.relative_to(PLUGIN_ROOT)} missing frontmatter"

    def test_all_have_name(self, skill_files):
        for path in skill_files:
            text = path.read_text()
            assert re.search(r"^name:\s*\S+", text, re.MULTILINE), (
                f"{path.relative_to(PLUGIN_ROOT)} missing 'name' in frontmatter"
            )

    def test_all_have_description(self, skill_files):
        for path in skill_files:
            text = path.read_text()
            assert re.search(r"^description:\s*\S+", text, re.MULTILINE), (
                f"{path.relative_to(PLUGIN_ROOT)} missing 'description' in frontmatter"
            )

    def test_skill_names_match_directory(self, skill_files):
        for path in skill_files:
            text = path.read_text()
            m = re.search(r"^name:\s*(.+)$", text, re.MULTILINE)
            if m:
                name = m.group(1).strip().strip("'\"")
                dir_name = path.parent.name
                assert name == dir_name, (
                    f"Skill name '{name}' does not match directory '{dir_name}'"
                )

    def test_core_skills_present(self):
        """The common workflow surface must exist."""
        for skill_name in sorted(EXPECTED_LIVE_SKILLS):
            skill_path = SKILLS_DIR / skill_name / "SKILL.md"
            assert skill_path.exists(), f"Core skill '{skill_name}' missing"

    def test_live_skill_inventory_is_exact(self):
        """Reference-only workflows must not drift back into exported skills."""
        actual = {
            path.name
            for path in SKILLS_DIR.iterdir()
            if path.is_dir() and (path / "SKILL.md").exists()
        }
        assert actual == EXPECTED_LIVE_SKILLS

    def test_public_workflow_inventory_hides_maintainer(self):
        """The public docs advertise product workflows, while maintainer remains manual."""
        readme = (PLUGIN_ROOT / "README.md").read_text()
        map_text = (SKILLS_DIR / "map" / "SKILL.md").read_text()

        for skill_name in sorted(EXPECTED_PUBLIC_WORKFLOW_SKILLS):
            assert f"| `{skill_name}` |" in readme
        for skill_name in sorted(EXPECTED_PUBLIC_WORKFLOW_SKILLS - {"map"}):
            assert f"| `{skill_name}` |" in map_text

        assert "| `maintainer` |" not in readme
        assert "| `maintainer` |" not in map_text
        assert "maintenance is intentionally hidden" in readme.lower()
        assert "`maintainer` directly" in readme.lower()
        assert "type `maintainer` directly" in map_text.lower()

    def test_blocks_guidance_is_hidden_reference(self):
        """Domain guidance should stay available without becoming a top-level skill."""
        assert not (SKILLS_DIR / "blocks" / "SKILL.md").exists()
        reference = SKILLS_DIR / "develop" / "references" / "domain" / "blocks.md"
        assert reference.exists()
        assert not reference.read_text().startswith("---"), (
            "blocks reference should not expose skill frontmatter"
        )

    def test_generate_docs_guidance_is_maintainer_reference(self):
        """Documentation generation stays available without becoming a top-level skill."""
        reference = SKILLS_DIR / "maintainer" / "references" / "generate-docs"
        assert not (SKILLS_DIR / "documentation" / "SKILL.md").exists()
        assert (reference / "generate-docs.md").exists()
        assert (reference / "scripts" / "regenerate.sh").exists()
        assert (reference / "assets" / "ucsc_wp_block_dev_main.md").exists()
        assert (reference / "assets" / "ucsc_wp_block_dev_presentation.md").exists()
        assert not (reference / "generate-docs.md").read_text().startswith("---"), (
            "generate-docs reference should not expose skill frontmatter"
        )

    def test_reference_directories_do_not_define_nested_skills(self):
        """Progressive references are markdown files, not nested plugin skills."""
        nested_skill_files = [
            path
            for skill_dir in SKILLS_DIR.iterdir()
            if skill_dir.is_dir()
            for path in (skill_dir / "references").rglob("SKILL.md")
            if (skill_dir / "references").exists()
        ]
        assert nested_skill_files == []

    def test_contrib_candidates_are_outside_live_skills(self):
        assert (CONTRIB_DIR / "README.md").exists()
        assert (CONTRIB_DIR / "proposals" / "TEMPLATE.md").exists()
        assert (CONTRIB_DIR / "incubator" / "TEMPLATE.md").exists()
        assert not (SKILLS_DIR / "contrib").exists()

    def test_maintainer_routes_contributed_skills(self):
        text = (SKILLS_DIR / "maintainer" / "SKILL.md").read_text().lower()
        for requirement in [
            "review-contrib",
            "promote-contrib",
            "contrib/proposals/",
            "contrib/incubator/",
            "do not place a candidate under `skills/` during review",
        ]:
            assert requirement in text

    def test_description_under_truncation_cap(self, skill_files):
        """description + when_to_use must fit within the 1,536-char listing cap."""
        for path in skill_files:
            text = path.read_text()
            fm_match = re.match(r"^---\n(.+?)\n---", text, re.DOTALL)
            if not fm_match:
                continue
            fm = {}
            for line in fm_match.group(1).splitlines():
                if ":" in line:
                    k, _, v = line.partition(":")
                    fm[k.strip()] = v.strip().strip('"').strip("'")
            combined = len(fm.get("description", "")) + len(fm.get("when_to_use", ""))
            assert combined <= 1536, (
                f"{path.parent.name} description+when_to_use is {combined} chars, "
                "exceeds 1,536-char truncation cap"
            )

    def test_frontmatter_uses_portable_agent_skills_fields(self, skill_files):
        """Canonical skills use only the portable Agent Skills core fields."""
        allowed = {"name", "description"}
        for path in skill_files:
            text = path.read_text()
            fm_match = re.match(r"^---\n(.+?)\n---", text, re.DOTALL)
            if fm_match:
                keys = []
                for line in fm_match.group(1).splitlines():
                    if ":" in line:
                        k, _, _ = line.partition(":")
                        keys.append(k.strip())
                extra_keys = set(keys) - allowed
                assert not extra_keys, (
                    f"{path.relative_to(PLUGIN_ROOT)} has unsupported frontmatter keys: {extra_keys}."
                )

    def test_workflow_skills_support_universal_input_resolution(self):
        routers = ["map"]
        handlers = [
            "develop",
            "feature",
            "fix",
            "maintainer",
            "review",
            "run",
            "test",
            "verify",
        ]

        for skill_name in routers:
            text = (SKILLS_DIR / skill_name / "SKILL.md").read_text().lower()
            assert "## universal input routing" in text
            assert "target" in text
            assert "natural-language request" in text
            assert "jira key/url" in text
            assert "preserve" in text

        for skill_name in handlers:
            text = (SKILLS_DIR / skill_name / "SKILL.md").read_text().lower()
            assert "## universal command intake" in text
            assert "target" in text
            assert "natural-language" in text
            assert "jira" in text
            assert "ask one concise question only" in text

    def test_issue_context_is_a_shared_develop_reference(self):
        reference = SKILLS_DIR / "develop" / "references" / "issue-context.md"
        assert reference.exists()
        assert not (SKILLS_DIR / "issue-context" / "SKILL.md").exists()

        for skill_name in ["develop", "feature", "fix"]:
            text = (SKILLS_DIR / skill_name / "SKILL.md").read_text()
            assert "issue-context.md" in text

    def test_block_targets_are_develop_references(self):
        targets = SKILLS_DIR / "develop" / "references" / "targets"
        expected = {
            "campus-directory.md",
            "class-schedule.md",
            "course-catalog.md",
        }
        assert expected <= {path.name for path in targets.glob("*.md")}

        for target in ["campus-directory", "class-schedule", "course-catalog"]:
            assert not (SKILLS_DIR / target / "SKILL.md").exists()

        develop = (SKILLS_DIR / "develop" / "SKILL.md").read_text().lower()
        assert "require the user to choose a target" in develop
        assert "references/targets/index.md" in develop
        assert "do not load all target references" in develop
        assert "references/domain/blocks.md" in develop

    def test_map_is_the_single_skill_entry_point(self):
        text = (SKILLS_DIR / "map" / "SKILL.md").read_text().lower()
        for skill_name in ["feature", "fix", "test", "review", "run", "verify"]:
            assert f"`{skill_name}`" in text
        assert "type `maintainer` directly" in text
        assert "references/generate-docs/generate-docs.md" in text
        assert "generate-docs` is intentionally a hidden reference" in text
        assert "portable entry point" in text
        assert "route by intent rather than command syntax" in text

    def test_maintainer_reference_regenerates_markdown_artifacts(self):
        """Maintainer owns Markdown outputs for Google Docs and Confluence."""
        reference = SKILLS_DIR / "maintainer" / "references" / "generate-docs"
        text = (reference / "generate-docs.md").read_text().lower()

        for requirement in [
            "assets/ucsc_wp_block_dev_main.md",
            "assets/ucsc_wp_block_dev_presentation.md",
            "scripts/regenerate.sh",
            "docs/adr/index.md",
            "adr-derived content",
            "future roadmap slide",
            "does not publish",
            "google docs",
            "confluence",
        ]:
            assert requirement in text

        assert (reference / "scripts" / "regenerate.sh").exists()

    def test_generate_docs_draws_from_adrs(self):
        """ADR-048 requires generated docs to be reconciled with ADR context."""
        text = (
            SKILLS_DIR
            / "maintainer"
            / "references"
            / "generate-docs"
            / "generate-docs.md"
        ).read_text().lower()
        assert "docs/adr/index.md" in text
        assert "referenced adrs" in text
        assert "accepted decisions" in text
        assert "superseded adr behavior" in text
        assert "future roadmap slide" in text

    def test_maintainer_documents_generate_docs_operation(self):
        """Documentation regeneration is an operation on maintainer, not its own skill."""
        text = (SKILLS_DIR / "maintainer" / "SKILL.md").read_text().lower()
        assert "## generate-docs" in text
        assert "references/generate-docs/generate-docs.md" in text
        assert "references/generate-docs/scripts/regenerate.sh" in text
        assert "generate-docs` operation" in text

    def test_documentation_generator_writes_to_maintainer_reference(self):
        """The regenerate script must not recreate the removed documentation skill."""
        script = (
            SKILLS_DIR
            / "maintainer"
            / "references"
            / "generate-docs"
            / "scripts"
            / "regenerate.sh"
        ).read_text()
        assert 'plugin_root="$(cd "$skill_dir/../../../.." && pwd)"' in script
        assert 'out_dir="$skill_dir/assets"' in script
        assert "skills/documentation" not in script

    def test_run_records_the_wp_dev_launch_recipe(self):
        """Run must capture nonstandard setup instead of rediscovering it."""
        text = (SKILLS_DIR / "run" / "SKILL.md").read_text().lower()
        for requirement in [
            ".env.example.txt",
            "/etc/hosts",
            "./setup.sh",
            "docker-compose-install.yml",
            "wordpress_install",
            "https://wp-dev.ucsc/wp-admin/",
            "use the available browser tool",
        ]:
            assert requirement in text
        assert "do not repeat clean setup" in text
        assert "local node is not required" in text

    def test_verify_requires_live_runtime_evidence(self):
        """Verify must prove behavior in the app rather than report test success."""
        text = (SKILLS_DIR / "verify" / "SKILL.md").read_text().lower()
        assert "recorded launch recipe" in text
        assert "`run` skill" in text
        assert "https://wp-dev.ucsc/wp-admin/" in text
        assert "use the available browser tool" in text
        assert "do not use jest, php tests, lint, type checks" in text
        assert "pass or fail for each acceptance criterion" in text
        assert "do not claim success from automated tests alone" in text

    def test_test_skill_confirms_type_and_operation_before_tools(self):
        """ADR-031 requires explicit test layer and create/run intent."""
        text = (SKILLS_DIR / "test" / "SKILL.md").read_text().lower()
        assert "**type**" in text
        assert "`php`, `jest`, or `e2e`" in text
        assert "**operation**" in text
        assert "`create` tests or `run` existing tests" in text
        assert "always ask one concise question only" in text
        assert "wait for the answer before using tools" in text
        assert "references/create.md" in text
        assert "references/run.md" in text

    def test_test_operations_are_progressive_references(self):
        create_ref = SKILLS_DIR / "test" / "references" / "create.md"
        run_ref = SKILLS_DIR / "test" / "references" / "run.md"
        assert create_ref.exists()
        assert run_ref.exists()
        assert "check-in text" in create_ref.read_text().lower()
        assert "do not emit check-in text" in run_ref.read_text().lower()

    def test_fix_requires_user_provided_concrete_problem_before_investigation(self):
        """ADR-007's clarification gate must remain explicit in the fix skill."""
        text = (SKILLS_DIR / "fix" / "SKILL.md").read_text().lower()
        gate_start = text.index("## 1. secure the target and fix description")
        reproduce_start = text.index("## 2. reproduce first")
        gate = text[gate_start:reproduce_start]

        assert "from the user" in gate
        assert "plain-language description is sufficient" in gate
        assert "ask one concise question" in gate
        assert "do not inspect source files" in gate

    def test_fix_and_develop_prefer_but_do_not_require_jira(self):
        """ADR-008 must remain explicit in both implementation workflows."""
        for skill_name in ["fix", "develop"]:
            text = (SKILLS_DIR / skill_name / "SKILL.md").read_text().lower()
            assert "jira id" in text
            assert "preferred, not required" in text

        fix_text = (SKILLS_DIR / "fix" / "SKILL.md").read_text().lower()
        assert "same clarification" in fix_text

    def test_fix_and_develop_require_target_and_work_description(self):
        """ADR-009's two-part intake gate must remain explicit."""
        expectations = {
            "fix": "fix description",
            "develop": "feature description",
        }
        for skill_name, description_label in expectations.items():
            text = (SKILLS_DIR / skill_name / "SKILL.md").read_text().lower()
            intake = text.split("## 2.", 1)[0]

            assert "**target**" in intake
            assert "block, gui, or app" in intake
            assert description_label in intake
            assert "plain-language description is sufficient" in intake
            assert "before using tools" in intake
            assert "wait for the answer" in intake

    def test_jira_prompt_may_repeat_at_phase_completion(self):
        """ADR-010 must keep the completion prompt optional and non-blocking."""
        for skill_name in ["fix", "develop"]:
            text = (SKILLS_DIR / skill_name / "SKILL.md").read_text().lower()
            assert "completion summary may ask for it again" in text
            assert "do not repeat the prompt when an id is already known" in text
            assert "do not treat a missing id as incomplete work" in text

    def test_fix_feature_develop_and_review_offer_commit_syntax_without_git_operations(self):
        """ADR-029 offers Conventional Commit syntax while keeping Git operations manual."""
        for skill_name in ["fix", "feature", "develop", "review"]:
            text = (SKILLS_DIR / skill_name / "SKILL.md").read_text().lower()
            normalized = re.sub(r"\s+", " ", text)
            assert "offer to generate conventional commit syntax" in normalized
            assert "generate message text only if the user accepts" in normalized
            assert "manual check-in is the default" in normalized
            assert "`git add`, `git commit`, `git push`" in normalized
            assert "unless the user explicitly asks" in normalized

    def test_editing_workflows_warn_on_non_feature_branches(self):
        """ADR-047 requires a branch warning before code edits on shared branches."""
        for skill_name in ["fix", "feature", "develop", "review"]:
            text = (SKILLS_DIR / skill_name / "SKILL.md").read_text().lower()
            normalized = re.sub(r"\s+", " ", text)
            assert "current git branch" in normalized
            assert "`main`" in normalized
            assert "`master`" in normalized
            assert "`develop`" in normalized
            assert "dev/developer_name/issue-1234_short_desc" in normalized
            assert "do not create or switch branches unless the user explicitly asks" in normalized

    def test_atlassian_mcp_reminder_is_optional_and_requires_approval(self):
        """ADR-025 must keep Atlassian setup reminders restrained and user-controlled."""
        texts = [
            (
                SKILLS_DIR
                / "develop"
                / "references"
                / "issue-context.md"
            ).read_text().lower(),
            (SKILLS_DIR / "review" / "SKILL.md").read_text().lower(),
        ]
        for text in texts:
            assert "atlassian mcp tools are unavailable" in text
            assert "mention once" in text
            assert "non-blocking" in text
            assert "continue with available context" in text
            assert "do not repeat it later" in text
            assert "without explicit user approval" in text

    def test_code_blocks_specify_language(self, skill_files):
        """Every fenced code block in SKILL.md must specify a language for syntax highlighting."""
        for path in skill_files:
            text = path.read_text()
            lines = text.splitlines()
            in_code_block = False
            for idx, line in enumerate(lines, 1):
                if line.startswith("```"):
                    if not in_code_block:
                        lang = line[3:].strip()
                        assert lang != "", (
                            f"{path.relative_to(PLUGIN_ROOT)}:L{idx} code block has no language specified"
                        )
                        in_code_block = True
                    else:
                        in_code_block = False


class TestMaintainerSlideDeck:
    def test_canonical_deck_is_maintainer_owned(self):
        assert SLIDE_DECK.exists()
        assert not (PROJECT_ROOT / "ucsc_wp_block_dev_presentation.md").exists()

    def test_deck_lists_every_top_level_skill(self):
        text = SLIDE_DECK.read_text()
        skill_names = sorted(path.name for path in SKILLS_DIR.iterdir() if path.is_dir())
        for skill_name in skill_names:
            assert f"`{skill_name}`" in text, f"Slide deck is missing skill '{skill_name}'"

    def test_deck_has_current_generated_date_format(self):
        text = SLIDE_DECK.read_text()
        assert re.search(r"\*\*Generated:\*\* \d{4}-\d{2}-\d{2}<br />", text)

    def test_deck_has_adr_backed_future_roadmap(self):
        text = SLIDE_DECK.read_text()
        assert "## **Future Roadmap**" in text
        for adr in ["ADR-026", "ADR-027", "ADR-028", "ADR-047"]:
            assert adr in text
        assert "Roadmap themes are drawn from accepted and study-oriented ADRs" in text

    def test_publisher_uses_maintainer_deck(self):
        text = PUBLISHER.read_text()
        for path_part in [
            '"ucsc-wp-block-dev"',
            '"skills"',
            '"maintainer"',
            '"assets"',
            '"ucsc_wp_block_dev_presentation.md"',
        ]:
            assert path_part in text


class TestAdrIndex:
    """ADR index must reference files that exist, and all ADR files must be indexed."""

    def test_index_exists(self):
        assert (ADR_DIR / "index.md").exists()

    def test_referenced_files_exist(self):
        index_text = (ADR_DIR / "index.md").read_text()
        links = re.findall(r"\[ADR-[^\]]+\]\(([^)]+)\)", index_text)
        for link in links:
            assert (ADR_DIR / link).exists(), f"ADR index references missing file: {link}"

    def test_all_adr_files_indexed(self):
        index_text = (ADR_DIR / "index.md").read_text()
        adr_files = sorted(ADR_DIR.glob("ADR-*.md"))
        for adr_file in adr_files:
            assert adr_file.name in index_text, (
                f"{adr_file.name} exists but is not referenced in index.md"
            )

    def test_adr_files_have_valid_frontmatter(self):
        """All ADR files must have valid frontmatter containing title, status, and date."""
        adr_files = sorted(ADR_DIR.glob("ADR-*.md"))
        for adr_file in adr_files:
            text = adr_file.read_text()
            fm_match = re.match(r"^---\n(.+?)\n---", text, re.DOTALL)
            assert fm_match, f"{adr_file.name} missing frontmatter"
            fm = {}
            for line in fm_match.group(1).splitlines():
                if ":" in line:
                    k, _, v = line.partition(":")
                    fm[k.strip()] = v.strip().strip('"').strip("'")
            assert "title" in fm, f"{adr_file.name} missing 'title' in frontmatter"
            assert "status" in fm, f"{adr_file.name} missing 'status' in frontmatter"
            assert "date" in fm, f"{adr_file.name} missing 'date' in frontmatter"
            assert fm["status"] in ["Proposed", "Accepted", "Rejected", "Deprecated", "Superseded"], (
                f"{adr_file.name} has invalid status: '{fm['status']}'"
            )

    def test_fix_token_study_is_multi_pronged_and_measured(self):
        """ADR-026 must optimize full fix sessions without weakening correctness gates."""
        text = (ADR_DIR / "ADR-026-study-multi-pronged-fix-token-reduction.md").read_text().lower()
        for workstream in [
            "loaded instruction size",
            "intake and routing",
            "evidence funnel",
            "progressive file reading",
            "risk-based validation",
            "output and tool-result discipline",
        ]:
            assert workstream in text
        assert "establish a baseline" in text
        assert "benchmark set" in text
        assert "median token use" in text
        assert "do not weaken the required target-and-description intake gate" in text

    def test_mcp_token_study_compares_startup_strategies(self):
        """ADR-027 must measure MCP savings against startup and unused-session cost."""
        text = (ADR_DIR / "ADR-027-study-github-atlassian-mcp-token-cost.md").read_text().lower()
        for configuration in ["fallback only", "on demand", "always on"]:
            assert configuration in text
        assert "measure github and atlassian independently" in text
        assert "local-only fix" in text
        assert "fixed session-start cost" in text
        assert "number of relevant tasks needed to recover" in text
        assert "without explicit user approval" in text

    def test_mcp_activation_is_just_in_time_and_token_driven(self):
        """ADR-028 must keep the multi-purpose plugin light and activation controlled."""
        text = (ADR_DIR / "ADR-028-start-mcp-just-in-time-when-token-efficient.md").read_text().lower()
        assert "multi-purpose plugin" in text
        assert "do not start github or atlassian mcp by default" in text
        assert "activate only the relevant mcp just in time" in text
        assert "start both only" in text
        assert "local-only development" in text
        assert "total task tokens" in text
        assert "obtain explicit approval" in text
        assert "continue with available fallbacks" in text


class TestFileLayout:
    def test_readme_exists(self):
        assert (PLUGIN_ROOT / "README.md").exists()

    def test_skills_each_have_skill_md(self):
        """Every directory under skills/ must have a SKILL.md."""
        for d in sorted(SKILLS_DIR.iterdir()):
            if d.is_dir():
                assert (d / "SKILL.md").exists(), (
                    f"Skill directory {d.name}/ has no SKILL.md"
                )

    def test_no_env_or_secrets_files(self):
        """Plugin must never contain .env, credential, or key files."""
        dangerous = (
            list(PLUGIN_ROOT.rglob(".env"))
            + list(PLUGIN_ROOT.rglob("*.key"))
            + list(PLUGIN_ROOT.rglob("credentials*"))
        )
        assert len(dangerous) == 0, (
            f"Plugin contains potentially sensitive files: {[str(f) for f in dangerous]}"
        )

    def test_no_stale_pycache_committed(self):
        """__pycache__ directories should not be tracked by git."""
        import subprocess
        pycache_dirs = list(PLUGIN_ROOT.rglob("__pycache__"))
        for d in pycache_dirs:
            r = subprocess.run(
                ["git", "ls-files", str(d)],
                capture_output=True, text=True,
                cwd=str(PLUGIN_ROOT),
            )
            assert r.stdout.strip() == "", (
                f"__pycache__ tracked by git: {d.relative_to(PLUGIN_ROOT)}"
            )

    def test_all_markdown_links_resolve(self):
        """All relative file links inside markdown files must resolve to existing files."""
        md_files = list(PLUGIN_ROOT.rglob("*.md"))
        assert len(md_files) > 0
        for path in md_files:
            text = path.read_text(errors="ignore")
            links = re.findall(r"\[[^\]]+\]\(([^)]+)\)", text)
            for link in links:
                if link.startswith(("http://", "https://", "mailto:", "#")):
                    continue
                link_path_str = link.split("#")[0]
                if not link_path_str:
                    continue
                resolved = (path.parent / link_path_str).resolve()
                assert resolved.exists(), (
                    f"Broken link '{link}' in {path.relative_to(PLUGIN_ROOT)}"
                )

    def test_license_exists(self):
        """LICENSE file must exist in the plugin root."""
        assert (PLUGIN_ROOT / "LICENSE").exists()

    def test_no_empty_files(self):
        """Ensure no markdown, json, python or shell files are completely empty."""
        for path in PLUGIN_ROOT.rglob("*"):
            if path.is_file() and path.suffix in [".md", ".json", ".py", ".sh"]:
                # skip files in virtual environment or python cache
                if ".venv" in path.parts or "__pycache__" in path.parts or ".pytest_cache" in path.parts:
                    continue
                assert path.stat().st_size > 0, f"Empty file found: {path.relative_to(PLUGIN_ROOT)}"

    def test_skill_directory_naming(self):
        """Skill subdirectories should only contain lowercase letters, numbers, and hyphens."""
        for d in SKILLS_DIR.iterdir():
            if d.is_dir():
                assert re.match(r"^[a-z0-9-]+$", d.name), (
                    f"Skill directory name '{d.name}' does not follow canonical lowercase pattern"
                )

    def test_gitignore_ignores_venv_and_pycache(self):
        """Verify .gitignore includes rules to ignore python caches and virtual environment."""
        gitignore = PLUGIN_ROOT / ".gitignore"
        assert gitignore.exists()
        text = gitignore.read_text()
        assert ".venv/" in text or ".venv" in text
        assert "__pycache__/" in text or "__pycache__" in text
        assert ".pytest_cache/" in text or ".pytest_cache" in text


class TestCrossPlatformNaming:
    """Claude and Codex must expose the same canonical plugin ID."""

    @pytest.fixture()
    def codex_manifest(self):
        path = (
            PROJECT_ROOT
            / ".agents"
            / "plugins"
            / PLUGIN_NAME
            / ".codex-plugin"
            / "plugin.json"
        )
        return json.loads(path.read_text())

    @pytest.fixture()
    def marketplace(self):
        path = PROJECT_ROOT / ".agents" / "plugins" / "marketplace.json"
        return json.loads(path.read_text())

    def test_codex_manifest_uses_canonical_name(self, codex_manifest):
        assert codex_manifest["name"] == PLUGIN_NAME

    def test_version_consistency(self, codex_manifest):
        """The base semantic version (major.minor.patch) must be identical in both Claude and Codex manifests."""
        claude_manifest = json.loads((PLUGIN_ROOT / ".claude-plugin" / "plugin.json").read_text())
        claude_ver = claude_manifest["version"].split("+")[0]
        codex_ver = codex_manifest["version"].split("+")[0]
        assert claude_ver == codex_ver, (
            f"Claude version '{claude_ver}' does not match Codex version '{codex_ver}'"
        )

    def test_codex_marketplace_uses_canonical_name_and_path(self, marketplace):
        entry = next(plugin for plugin in marketplace["plugins"] if plugin["name"] == PLUGIN_NAME)
        assert entry["source"]["path"] == f"./.agents/plugins/{PLUGIN_NAME}"

    def test_codex_launcher_uses_canonical_name(self):
        launcher = (PROJECT_ROOT / ".agents" / "codex.sh").read_text()
        assert f'PLUGIN_NAME="{PLUGIN_NAME}"' in launcher

    def test_canonical_skills_do_not_embed_plugin_slash_commands(self):
        command_pattern = re.compile(r"/(ucsc-(?:wp|wordpress)-block-dev):[a-z-]+")
        files = [PLUGIN_ROOT / "README.md", *SKILLS_DIR.rglob("SKILL.md")]
        commands = [
            match.group(1)
            for path in files
            for match in command_pattern.finditer(path.read_text())
        ]
        assert commands == [], (
            "Canonical skills should be portable and must not embed "
            f"host-specific plugin slash commands: {commands}"
        )

    def test_forbidden_long_plugin_id_is_absent(self):
        roots = [PLUGIN_ROOT, PROJECT_ROOT / ".agents"]
        offenders = []
        for root in roots:
            for path in root.rglob("*"):
                if "__pycache__" in path.parts or ".pytest_cache" in path.parts:
                    continue
                if path.is_file() and FORBIDDEN_PLUGIN_NAME in path.read_text(errors="ignore"):
                    offenders.append(str(path.relative_to(PROJECT_ROOT)))
        assert offenders == [], (
            f"Use '{PLUGIN_NAME}' for machine-facing identifiers; found "
            f"'{FORBIDDEN_PLUGIN_NAME}' in: {offenders}"
        )
