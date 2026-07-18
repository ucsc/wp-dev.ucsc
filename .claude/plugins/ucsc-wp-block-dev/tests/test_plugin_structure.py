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
SLIDE_DECK = SKILLS_DIR / "maintainer" / "assets" / "ucsc-wp-block-dev-presentation.md"
PUBLISHER = PROJECT_ROOT / ".claude" / "scripts" / "publish_to_gdoc.py"
PLUGIN_NAME = "ucsc-wp-block-dev"
FORBIDDEN_PLUGIN_NAME = "ucsc-" + "wordpress-block-dev"
EXPECTED_LIVE_SKILLS = {
    "audit",
    "develop",
    "feedback",
    "hub",
    "maintainer",
    "review",
    "run",
    "validate",
    "verify",
    "wp7-pattern-lock",
   }
EXPECTED_DEVELOP_MODES = {"feature", "fix"}
EXPECTED_MAINTAINER_SUB_SKILLS = {"retrospective"}
EXPECTED_PUBLIC_WORKFLOW_SKILLS = EXPECTED_LIVE_SKILLS
SKILL_TREE_PATH = SKILLS_DIR / "hub" / "references" / "skill-tree.json"
SKILL_TREE = json.loads(SKILL_TREE_PATH.read_text())


def tree_skill(name: str) -> dict:
    return next(node for node in SKILL_TREE["skills"] if node["name"] == name)


def flatten_tree(nodes):
    for node in nodes:
        yield node
        yield from flatten_tree(node.get("modes", []))


def read_frontmatter(skill_dir: Path) -> dict:
    path = skill_dir / "SKILL.md"
    if not path.exists():
        return {}
    text = path.read_text()
    m = re.match(r"^---\n(.+?)\n---", text, re.DOTALL)
    if not m:
        return {}
    fm = {}
    for line in m.group(1).splitlines():
        if ":" in line and not line.strip().startswith("-"):
            k, _, v = line.partition(":")
            fm[k.strip()] = v.strip().strip('"').strip("'")
    return fm


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
        assert data["author"]["name"]


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

    def test_develop_modes_present(self):
        """feature and fix are modes nested under develop/."""
        for skill_name in sorted(EXPECTED_DEVELOP_MODES):
            skill_path = SKILLS_DIR / "develop" / skill_name / "SKILL.md"
            assert skill_path.exists(), f"develop mode '{skill_name}' missing"

    def test_maintainer_sub_skills_present(self):
        """retrospective is a sub-skill nested under maintainer/ (ADR-081, ADR-083)."""
        for skill_name in sorted(EXPECTED_MAINTAINER_SUB_SKILLS):
            skill_path = SKILLS_DIR / "maintainer" / skill_name / "SKILL.md"
            assert skill_path.exists(), f"maintainer sub-skill '{skill_name}' missing"

    def test_live_skill_inventory_is_exact(self):
        """Reference-only workflows must not drift back into exported skills."""
        actual = {
            path.name
            for path in SKILLS_DIR.iterdir()
            if path.is_dir() and (path / "SKILL.md").exists()
        }
        assert actual == EXPECTED_LIVE_SKILLS

    def test_public_workflow_inventory_lists_maintainer(self):
        """The public docs advertise product workflows and the guarded maintainer skill."""
        readme = (PLUGIN_ROOT / "README.md").read_text()

        for skill_name in sorted(EXPECTED_PUBLIC_WORKFLOW_SKILLS):
            assert re.search(rf"^[├└]─ {re.escape(skill_name)}\s", readme, re.MULTILINE)

        assert not re.search(r"^[├└]─ retrospective\s", readme, re.MULTILINE)
        assert not re.search(r"^[├└]─ survey\s", readme, re.MULTILINE)
        assert re.search(r"^[├└]─ maintainer\s", readme, re.MULTILINE)
        assert "user-invocable only" in readme.lower()
        assert "model auto-invocation is disabled" in readme.lower()
        # retrospective is a hidden maintainer sub-skill (ADR-083).
        assert "maintainer/retrospective" in readme.lower()
        assert "develop/survey" not in readme.lower()

    def test_hub_lists_public_product_workflows(self):
        """:hub keeps maintainer out of the public workflow table unless maintainer is active."""
        hub = (SKILLS_DIR / "hub" / "SKILL.md").read_text()
        public = re.search(
            r"## Public workflows\s*\n(.*?)(?=\n## Maintainer Workflows)",
            hub,
            re.DOTALL,
        ).group(1)
        public_nodes = [
            node for node in SKILL_TREE["skills"] if "public" in node["contexts"]
        ]
        for skill_name in [node["name"] for node in public_nodes]:
            assert re.search(
                rf"^[├└]─ {re.escape(skill_name)}\s",
                public,
                re.MULTILINE,
            ), f"hub is missing skill '{skill_name}'"
        for node in public_nodes:
            for mode in flatten_tree(node.get("modes", [])):
                assert re.search(
                    rf"^[│ ]+[├└]─ {re.escape(mode['name'])}\s",
                    public,
                    re.MULTILINE,
                ), f"hub is missing mode '{node['name']} {mode['name']}'"
        assert not re.search(r"^[│ ]+[├└]─ test\s", public, re.MULTILINE)
        assert "develop/survey" not in public
        assert not re.search(r"^[├└]─ maintainer\s", public, re.MULTILINE)
        assert "maintainer/retrospective" not in public
        # hub enumerates; it does not route (ADR-061).
        assert "invoke the specific skill directly" in hub.lower()

    def test_hub_has_maintainer_context_section(self):
        """:hub shows maintainer details only from an active maintainer workflow (ADR-089)."""
        hub = (SKILLS_DIR / "hub" / "SKILL.md").read_text().lower()
        assert "when `:hub` is shown while the `maintainer` skill is already active" in hub
        assert "## maintainer workflows" in hub
        assert "print this section only when `:hub` is shown from an active `maintainer`" in hub
        maintainer = tree_skill("maintainer")
        assert "public" not in maintainer["contexts"]
        assert "maintainer" in maintainer["contexts"]
        for mode in flatten_tree(maintainer["modes"]):
            assert re.search(
                rf"^[│ ]*[├└]─ {re.escape(mode['name'])}\s",
                hub,
                re.MULTILINE,
            )
        assert "tier 2 is opt-in" in hub

    def test_hub_argument_hints_match_frontmatter(self):
        """Hub tree includes compact basic argument hints for top-level skills."""
        hub = (SKILLS_DIR / "hub" / "SKILL.md").read_text()
        public = re.search(
            r"## Public workflows\s*\n(.*?)(?=\n## Block target)",
            hub,
            re.DOTALL,
        ).group(1)
        maintainer = re.search(
            r"## Maintainer Workflows\s*\n(.*?)(?=\n## Routing)",
            hub,
            re.DOTALL,
        ).group(1)

        public_nodes = [
            node for node in SKILL_TREE["skills"] if "public" in node["contexts"]
        ]
        for node in public_nodes:
            name = node["name"]
            hint = node["argument_hint"]
            assert read_frontmatter(SKILLS_DIR / name).get("argument-hint")
            assert re.search(
                rf"^[├└]─ {name}\s+{re.escape(hint)}\s+—",
                public,
                re.MULTILINE,
            ), f"hub tree missing compact hint for {name}"

        maintainer_node = tree_skill("maintainer")
        assert re.search(
            rf"^maintainer\s+{re.escape(maintainer_node['argument_hint'])}\s+—",
            maintainer,
            re.MULTILINE,
        )

    def test_skill_tree_data_contract(self):
        """The tree model owns skills, modes, hints, descriptions, and visibility."""
        assert SKILL_TREE["version"] == 1
        assert {node["name"] for node in SKILL_TREE["skills"]} == EXPECTED_LIVE_SKILLS
        for node in flatten_tree(SKILL_TREE["skills"]):
            assert node["argument_hint"]
            assert node["short_description"]
            assert "\n" not in node["short_description"]
            assert len(node["short_description"]) <= 88

        maintainer = tree_skill("maintainer")
        assert "public" not in maintainer["contexts"]
        assert {"readme", "maintainer"} <= set(maintainer["contexts"])

    def test_mode_hints_match_skill_menus(self):
        """ADR-088 (2026-06-25): every mode-bearing skill's bare menu is the
        hub-style subtree for that skill — the skill as the root line and each
        mode (and sub-mode) as a tree branch — rendered from skill-tree.json.
        This replaced the old per-skill Markdown tables."""
        mode_bearing = [
            node["name"] for node in SKILL_TREE["skills"] if node.get("modes")
        ]
        # develop, validate, and maintainer all carry modes.
        assert {"develop", "validate", "maintainer"} <= set(mode_bearing)

        for name in mode_bearing:
            node = tree_skill(name)
            menu = (SKILLS_DIR / name / "skill-menu-mode.md").read_text()
            # The menu carries exactly one ```text``` tree block (the subtree).
            assert "```text" in menu, f"{name} menu must render its modes as a text tree"
            # Root line: the skill with its argument hint, hub-style.
            assert f"{name}  {node['argument_hint']}" in menu, (
                f"{name} menu must show the hub-style root line for the skill"
            )
            # Every mode (and nested sub-mode) appears as a tree branch.
            for mode in flatten_tree(node["modes"]):
                assert re.search(
                    rf"^[│ ]*[├└]─ {re.escape(mode['name'])}\s",
                    menu,
                    re.MULTILINE,
                ), f"{name} menu missing tree branch for mode '{mode['name']}'"

    def test_skill_menus_match_sync_inventory(self):
        """ADR-088: the rendered per-skill menu trees (and all other inventory
        surfaces) must not drift from skill-tree.json — sync-inventory --check
        is the single source of truth and is run here as a hard gate."""
        import subprocess

        script = (
            SKILLS_DIR / "maintainer" / "scripts" / "sync-inventory.sh"
        )
        result = subprocess.run(
            ["bash", str(script), "--check"],
            capture_output=True,
            text=True,
            cwd=str(PLUGIN_ROOT),
            timeout=30,
        )
        assert result.returncode == 0, (
            "sync-inventory.sh --check reported drift "
            "(run sync-inventory.sh --write to regenerate):\n"
            + result.stdout
            + result.stderr
        )

    def test_blocks_guidance_is_hidden_reference(self):
        """Domain guidance should stay available without becoming a top-level skill (flat per AgentSkills spec)."""
        assert not (SKILLS_DIR / "blocks" / "SKILL.md").exists()
        reference = SKILLS_DIR / "develop" / "references" / "domain-blocks.md"
        assert reference.exists()
        assert not reference.read_text().startswith("---"), (
            "blocks reference should not expose skill frontmatter"
        )

    def test_generate_docs_guidance_is_maintainer_reference(self):
        """Documentation generation stays available without becoming a top-level skill (flat per AgentSkills spec)."""
        refs = SKILLS_DIR / "maintainer" / "references"
        scripts = SKILLS_DIR / "maintainer" / "scripts"
        assert not (SKILLS_DIR / "documentation" / "SKILL.md").exists()
        assert (refs / "generate-docs.md").exists()
        assert (scripts / "regenerate-docs.sh").exists()
        assert (refs / "generate-docs-main.md").exists()
        assert (refs / "generate-docs-presentation.md").exists()
        assert not (refs / "generate-docs.md").read_text().startswith("---"), (
            "generate-docs reference should not expose skill frontmatter"
        )

    def test_reference_directories_do_not_define_nested_skills(self):
        """Progressive references are markdown files, not nested plugin skills (ADR-032).
        Exception: declared sub-skill directories under develop/ are permitted (ADR-081)."""
        nested_skill_files = [
            path
            for skill_dir in SKILLS_DIR.iterdir()
            if skill_dir.is_dir()
            for path in (skill_dir / "references").rglob("SKILL.md")
            if (skill_dir / "references").exists()
        ]
        assert nested_skill_files == []

    def test_develop_modes_are_referenced_from_develop(self):
        """Develop modes nested under develop/ must be referenced from develop/SKILL.md."""
        develop_text = (SKILLS_DIR / "develop" / "SKILL.md").read_text()
        for skill_name in sorted(EXPECTED_DEVELOP_MODES):
            assert f"{skill_name}/SKILL.md" in develop_text, (
                f"develop/SKILL.md does not reference mode '{skill_name}/SKILL.md'"
            )
        assert "survey/SKILL.md" not in develop_text

    def test_maintainer_sub_skills_are_referenced_from_maintainer(self):
        """ADR-081/ADR-083: sub-skills nested under maintainer/ must be referenced from maintainer/SKILL.md."""
        maintainer_text = (SKILLS_DIR / "maintainer" / "SKILL.md").read_text()
        for skill_name in sorted(EXPECTED_MAINTAINER_SUB_SKILLS):
            assert f"{skill_name}/SKILL.md" in maintainer_text, (
                f"maintainer/SKILL.md does not reference sub-skill '{skill_name}/SKILL.md'"
            )

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
                if ":" in line and not line.strip().startswith("-"):
                    k, _, v = line.partition(":")
                    fm[k.strip()] = v.strip().strip('"').strip("'")
            combined = len(fm.get("description", "")) + len(fm.get("when_to_use", ""))
            assert combined <= 1536, (
                f"{path.parent.name} description+when_to_use is {combined} chars, "
                "exceeds 1,536-char truncation cap"
            )

    def test_frontmatter_uses_portable_agent_skills_fields(self, skill_files):
        """Canonical skills use only official Claude Code skills frontmatter fields (ADR-070)."""
        allowed = {
            "name", "description", "when_to_use", "argument-hint", "arguments",
            "disable-model-invocation", "user-invocable", "allowed-tools",
            "disallowed-tools", "model", "effort", "context", "agent",
            "hooks", "paths", "shell", "version",
        }
        for path in skill_files:
            text = path.read_text()
            fm_match = re.match(r"^---\n(.+?)\n---", text, re.DOTALL)
            if fm_match:
                keys = []
                for line in fm_match.group(1).splitlines():
                    if ":" in line and not line.strip().startswith("-"):
                        k, _, _ = line.partition(":")
                        keys.append(k.strip())
                extra_keys = set(keys) - allowed
                assert not extra_keys, (
                    f"{path.relative_to(PLUGIN_ROOT)} has unsupported frontmatter keys: {extra_keys}."
                )

    def test_sensitive_skills_have_tool_controls(self):
        """Sensitive skills should declare either allowed-tools (whitelist) or disallowed-tools."""
        sensitive = [
            "maintainer",
            "run",
            "validate",
            "verify",
        ]
        violations = []
        for name in sensitive:
            fm = read_frontmatter(SKILLS_DIR / name)
            if "allowed-tools" not in fm and "disallowed-tools" not in fm:
                violations.append(name)
        assert not violations, f"Sensitive skills missing tool controls: {violations}"

    def test_workflow_skills_support_universal_input_resolution(self):
        handler_paths = [
            SKILLS_DIR / "develop" / "SKILL.md",
            SKILLS_DIR / "develop" / "feature" / "SKILL.md",
            SKILLS_DIR / "develop" / "fix" / "SKILL.md",
            SKILLS_DIR / "maintainer" / "SKILL.md",
            SKILLS_DIR / "review" / "SKILL.md",
            SKILLS_DIR / "run" / "SKILL.md",
            SKILLS_DIR / "validate" / "SKILL.md",
            SKILLS_DIR / "verify" / "SKILL.md",
        ]

        for path in handler_paths:
            text = path.read_text().lower()
            assert "## universal command intake" in text
            assert "target" in text
            assert "natural-language" in text
            assert "jira" in text
            assert "ask one concise question only" in text

    def test_issue_context_is_a_shared_develop_reference(self):
        reference = SKILLS_DIR / "develop" / "references" / "issue-context.md"
        assert reference.exists()
        assert not (SKILLS_DIR / "issue-context" / "SKILL.md").exists()

        skill_paths = {
            "develop": SKILLS_DIR / "develop" / "SKILL.md",
            "feature": SKILLS_DIR / "develop" / "feature" / "SKILL.md",
            "fix": SKILLS_DIR / "develop" / "fix" / "SKILL.md",
        }
        for skill_name, path in skill_paths.items():
            text = path.read_text()
            assert "issue-context.md" in text

    def test_block_targets_are_develop_references(self):
        refs = SKILLS_DIR / "develop" / "references"
        expected = {
            "target-calendar-feed.md",
            "target-campus-directory.md",
            "target-class-schedule.md",
            "target-course-catalog.md",
            "target-news.md",
        }
        assert expected <= {path.name for path in refs.glob("target-*.md")}

        for target in [
            "calendar-feed",
            "campus-directory",
            "class-schedule",
            "course-catalog",
            "news",
        ]:
            assert not (SKILLS_DIR / target / "SKILL.md").exists()

        develop = (SKILLS_DIR / "develop" / "SKILL.md").read_text().lower()
        assert "require the user to choose a target" in develop
        assert "references/targets.md" in develop
        assert "do not load all target references" in develop
        assert "references/domain-blocks.md" in develop

        targets = (refs / "targets.md").read_text()
        for target in [
            "calendar-feed",
            "campus-directory",
            "class-schedule",
            "course-catalog",
            "news",
        ]:
            assert f"| `{target}` |" in targets
            assert f"(target-{target}.md)" in targets

    def test_target_references_are_bidirectional(self):
        """Every slug linked in targets.md has a target-*.md file, and vice versa."""
        refs = SKILLS_DIR / "develop" / "references"
        targets_text = (refs / "targets.md").read_text()

        # slugs linked from the index (target-foo.md links)
        linked = set(re.findall(r"\(target-([^)]+)\.md\)", targets_text))
        # target-*.md files that actually exist on disk
        on_disk = {p.stem[len("target-"):] for p in refs.glob("target-*.md")}

        missing_files = linked - on_disk
        unlinked_files = on_disk - linked
        assert not missing_files, (
            f"targets.md links to target files that don't exist: {sorted(missing_files)}"
        )
        assert not unlinked_files, (
            f"target-*.md files exist but are not listed in targets.md: {sorted(unlinked_files)}"
        )

    def test_retrospective_has_adr077_closing_checklist(self):
        """ADR-077 requires the retrospective to prompt for script/skill/test improvements."""
        text = (SKILLS_DIR / "maintainer" / "retrospective" / "SKILL.md").read_text().lower()
        assert "script candidate" in text, "retrospective missing 'script candidate' question (ADR-077)"
        assert "skill improvement candidate" in text, (
            "retrospective missing 'skill improvement candidate' question (ADR-077)"
        )
        assert "token-reduction candidate" in text, (
            "retrospective missing 'token-reduction candidate' question (ADR-077)"
        )

    def test_maintainer_reference_regenerates_markdown_artifacts(self):
        """Maintainer owns Markdown outputs for Google Docs and Confluence (flat per AgentSkills spec)."""
        refs = SKILLS_DIR / "maintainer" / "references"
        scripts = SKILLS_DIR / "maintainer" / "scripts"
        text = (refs / "generate-docs.md").read_text().lower()

        for requirement in [
            "generate-docs-main.md",
            "generate-docs-presentation.md",
            "regenerate-docs.sh",
            "docs/adr/index.md",
            "adr-derived content",
            "future roadmap slide",
            "does not publish",
            "google docs",
            "confluence",
        ]:
            assert requirement in text

        assert (scripts / "regenerate-docs.sh").exists()

    def test_generate_docs_draws_from_adrs(self):
        """ADR-048 requires generated docs to be reconciled with ADR context."""
        text = (
            SKILLS_DIR / "maintainer" / "references" / "generate-docs.md"
        ).read_text().lower()
        assert "docs/adr/index.md" in text
        assert "referenced adrs" in text
        assert "accepted decisions" in text
        assert "superseded adr behavior" in text
        assert "future roadmap slide" in text

    def test_docs_mode_has_staleness_detection(self):
        """ADR-107: the regenerate script stamps a source hash and offers a
        report-only --check mode; the reference documents the staleness signal."""
        script = (
            SKILLS_DIR / "maintainer" / "scripts" / "regenerate-docs.sh"
        ).read_text()
        assert "--check" in script
        assert "source-hash" in script
        assert "git hash-object" in script
        ref = (
            SKILLS_DIR / "maintainer" / "references" / "generate-docs.md"
        ).read_text().lower()
        assert "--check" in ref
        assert "source hash" in ref or "source-hash" in ref
        assert "docs publish" in ref

    def test_docs_publish_defaults_to_both_outputs(self):
        """Bare docs publish has an explicit, stable two-output dispatch."""
        launcher = (SKILLS_DIR / "maintainer" / "launcher.md").read_text().lower()
        publish_ref = (
            SKILLS_DIR / "maintainer" / "references" / "publish.md"
        ).read_text().lower()
        tree = json.loads(
            (SKILLS_DIR / "hub" / "references" / "skill-tree.json").read_text()
        )
        docs_mode = next(
            mode
            for mode in next(
                skill for skill in tree["skills"] if skill["name"] == "maintainer"
            )["modes"]
            if mode["name"] == "docs"
        )
        publish_mode = next(
            mode for mode in docs_mode["modes"] if mode["name"] == "publish"
        )

        assert "default to publishing both outputs" in launcher
        assert "scripts/publish-docs.sh --target both --confirm" in launcher
        assert "slides, then guide" in publish_ref
        assert publish_mode["argument_hint"] == "[guide|slides]"
        assert "publish both by default" in publish_mode["short_description"]

    def test_hardened_docs_publisher_contract(self):
        script_path = (
            SKILLS_DIR / "maintainer" / "scripts" / "publish-docs.sh"
        )
        assert script_path.exists()
        script = script_path.read_text()
        for requirement in [
            "set -euo pipefail",
            "--target both|slides|guide",
            "--confirm",
            "--dry-run",
            "UCSC_WP_BLOCK_DEV_SLIDES_DOC_URL",
            "UCSC_WP_BLOCK_DEV_GUIDE_DOC_URL",
            "publish-env.sh",
            "refresh-and-publish-slides.sh",
            "refresh-and-publish-docs.sh",
            "check-skill-references.sh",
            "regenerate-docs.sh",
            "BLOCKED",
        ]:
            assert requirement in script

    def test_generated_guide_has_visible_release_metadata(self):
        """The published guide exposes its date, plugin version, and Git commit
        at the top instead of hiding all provenance in stripped frontmatter."""
        script = (
            SKILLS_DIR / "maintainer" / "scripts" / "regenerate-docs.sh"
        ).read_text()
        for marker in [
            "manifest_source",
            "plugin_version",
            "git_commit",
            "**Generated:**",
            "**Plugin version:**",
            "**Git commit:**",
        ]:
            assert marker in script

        guide = (
            SKILLS_DIR / "maintainer" / "references" / "generate-docs-main.md"
        ).read_text()
        assert re.search(r"^generated: \d{4}-\d{2}-\d{2}$", guide, re.MULTILINE)
        assert re.search(r"^version: \d+\.\d+\.\d+", guide, re.MULTILINE)
        assert re.search(r"^git-commit: [0-9a-f]{40}$", guide, re.MULTILINE)
        assert re.search(
            r"^\*\*Generated:\*\* \d{4}-\d{2}-\d{2} · "
            r"\*\*Plugin version:\*\* \d+\.\d+\.\d+ · "
            r"\*\*Git commit:\*\* `[0-9a-f]{12}`$",
            guide,
            re.MULTILINE,
        )

    def test_generated_guide_ends_with_post_install_hub_list(self):
        """ADR-107: the guide closes with the brief `:hub` skill list so a reader
        knows what to do after installing. Harvested from skill-tree.json."""
        guide = (
            SKILLS_DIR / "maintainer" / "references" / "generate-docs-main.md"
        ).read_text()
        assert "## After installing — what you can do" in guide
        assert "`hub`" in guide
        for skill_name in sorted(
            p.name for p in SKILLS_DIR.iterdir() if p.is_dir()
        ):
            assert f"`{skill_name}`" in guide, (
                f"guide post-install list is missing skill '{skill_name}'"
            )

    def test_maintainer_documents_docs_operation(self):
        """Documentation regeneration is the `docs` operation on maintainer, not its
        own skill (flat per AgentSkills spec). `generate-docs` is a legacy alias
        (ADR-107)."""
        text = (SKILLS_DIR / "maintainer" / "SKILL.md").read_text().lower()
        assert "## docs" in text
        assert "references/generate-docs.md" in text
        assert "scripts/regenerate-docs.sh" in text
        assert "`docs` operation" in text
        # publish is folded in as the optional final step of docs (ADR-107).
        assert "docs publish" in text
        # staleness detection via --check / source hash (ADR-107).
        assert "--check" in text
        # generate-docs remains an accepted legacy alias.
        assert "generate-docs` = `docs" in text or "legacy alias" in text

    def test_every_maintainer_mode_has_a_skill_section(self):
        """Every top-level maintainer mode in skill-tree.json must have a matching
        `## <mode>` section in maintainer/SKILL.md. Guards the recurring add/rename/
        fold-a-mode task (ADR-107 retro): a mode added to the tree but left
        undocumented in SKILL.md fails here, not in review."""
        maintainer_node = tree_skill("maintainer")
        skill_text = (SKILLS_DIR / "maintainer" / "SKILL.md").read_text()
        for mode in maintainer_node["modes"]:
            assert re.search(rf"^## {re.escape(mode['name'])}\b", skill_text, re.M), (
                f"maintainer/SKILL.md has no '## {mode['name']}' section for the "
                f"mode declared in skill-tree.json"
            )

    def test_maintainer_documents_adr_mode(self):
        """ADR work is a maintainer mode; new-adr remains a legacy alias."""
        text = (SKILLS_DIR / "maintainer" / "SKILL.md").read_text().lower()
        assert "## adr" in text
        assert "`adr`" in text
        assert "`new-adr` remains a legacy alias" in text
        assert "one adr per skill" in text
        assert "default to updating the existing adr" in text

    def test_maintainer_self_test_includes_best_practice_checks(self):
        """ADR-079 folds deterministic upstream guidance into self-test."""
        maintainer = (SKILLS_DIR / "maintainer" / "SKILL.md").read_text()
        external = (
            SKILLS_DIR / "maintainer" / "references" / "external-references.md"
        ).read_text()
        profile = (
            SKILLS_DIR / "maintainer" / "references" / "self-test.md"
        ).read_text()
        runner = (
            SKILLS_DIR / "maintainer" / "scripts" / "run-all-plugin-tests.sh"
        ).read_text()
        upstream = "https://github.com/anthropics/claude-code/tree/main/plugins/plugin-dev"

        assert "## plugin-dev-audit" not in maintainer
        assert "scripts/run-self-test.sh" in maintainer
        assert "check-plugin-best-practices.py" in profile
        assert upstream in external
        assert upstream in profile
        assert "plugin-dev@claude-code-marketplace" in profile
        assert 'run_step "self-test"' in runner
        assert "plugin-dev-audit" not in runner

    def test_maintainer_links_upstream_plugin_pattern_library(self):
        """Maintainers can compare against focused production plugin examples."""
        maintainer = (SKILLS_DIR / "maintainer" / "SKILL.md").read_text()
        external = (
            SKILLS_DIR / "maintainer" / "references" / "external-references.md"
        ).read_text()
        patterns = (
            SKILLS_DIR / "maintainer" / "references" / "upstream-plugin-patterns.md"
        ).read_text()
        collection = "https://github.com/anthropics/claude-code/tree/main/plugins"

        assert "references/upstream-plugin-patterns.md" in maintainer
        assert collection in external
        assert collection in patterns
        for plugin in [
            "feature-dev",
            "hookify",
            "security-guidance",
            "code-review",
            "pr-review-toolkit",
            "commit-commands",
        ]:
            assert f"plugins/{plugin}" in patterns
        assert "preserve this repository's no-push rule" in patterns.lower()

    def test_maintainer_training_is_a_first_class_mode(self):
        """ADR-079 routes focused upstream study through maintainer training."""
        maintainer = (SKILLS_DIR / "maintainer" / "SKILL.md").read_text()
        menu = (SKILLS_DIR / "maintainer" / "skill-menu-mode.md").read_text()
        training = (
            SKILLS_DIR / "maintainer" / "references" / "training.md"
        ).read_text()
        hub = (SKILLS_DIR / "hub" / "SKILL.md").read_text()

        assert "## training" in maintainer
        assert "`training`" in maintainer.split("## Universal Command Intake", 1)[0]
        assert "references/training.md" in maintainer
        assert re.search(r"^[│ ]*[├└]─ training\s", menu, re.MULTILINE)
        assert re.search(r"^[│ ]*[├└]─ training\s", hub, re.MULTILINE)
        normalized = re.sub(r"\s+", " ", training.lower())
        for requirement in [
            "not model fine-tuning",
            "do not scan every upstream plugin",
            "one or two analogous upstream plugins",
            "record the local git commit or public review date",
            "do not run upstream scripts",
            "run `maintainer all`",
        ]:
            assert requirement in normalized

    def test_maintainer_has_durable_core_modes(self):
        """The maintainer menu leads with backlog, ADR, skill, training, and retro."""
        maintainer = (SKILLS_DIR / "maintainer" / "SKILL.md").read_text()
        menu = (SKILLS_DIR / "maintainer" / "skill-menu-mode.md").read_text()
        launcher = (SKILLS_DIR / "maintainer" / "launcher.md").read_text()

        for mode in ["backlog", "adr", "skill", "training", "retro"]:
            assert f"`{mode}`" in maintainer
            assert re.search(rf"^[│ ]*[├└]─ {mode}\s", menu, re.MULTILINE)

        top_modes = [
            re.search(r"^[├└]─ (\S+)", line).group(1)
            for line in menu.splitlines()
            if re.search(r"^[├└]─ \S+", line)
        ]
        assert top_modes[:5] == [
            "backlog",
            "adr",
            "skill",
            "training",
            "retro",
        ]
        assert "## skill" in maintainer
        assert "skill details [name]" in maintainer
        assert "skill review [name\\|all]" in maintainer
        assert "skill review-contrib <candidate>" in maintainer
        assert "skill promote <candidate>" in maintainer
        assert "skill sync" in maintainer
        assert "## retro" in maintainer
        assert "retrospective/SKILL.md" in maintainer
        assert "route `retro` to `retrospective/skill.md`" in launcher.lower()

    def test_documentation_generator_writes_to_maintainer_reference(self):
        """The regenerate script uses flat paths per AgentSkills spec (no nested generate-docs/ dir)."""
        script = (
            SKILLS_DIR / "maintainer" / "scripts" / "regenerate-docs.sh"
        ).read_text()
        assert 'plugin_root="$(cd "$maintainer_dir/../.." && pwd)"' in script
        assert 'out_dir="$maintainer_dir/references"' in script
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
        ]:
            assert requirement in text
        assert "do not repeat clean setup" in text
        assert "local node is not required" in text
        assert "do not stop at container health" in text
        assert "launch and drive" in text

    def test_verify_requires_live_runtime_evidence(self):
        """Verify confirms requested behavior in the running app."""
        text = (SKILLS_DIR / "verify" / "SKILL.md").read_text().lower()
        assert "recorded launch recipe" in text
        assert "`run` skill" in text
        assert "https://wp-dev.ucsc/wp-admin/" in text
        assert "use the available browser tool" in text
        assert "do not use jest, php tests, lint, type checks" in text
        assert "pass or fail for each acceptance criterion" in text
        assert "target and behavior checked" in text
        assert "do not claim success from automated tests alone" in text

    def test_validate_skill_confirms_type_and_mode_before_tools(self):
        """ADR-031 requires explicit test layer and create/run intent (test skill retired -> validate)."""
        text = (SKILLS_DIR / "validate" / "SKILL.md").read_text().lower()
        assert "**type**" in text
        assert "`php`, `jest`, or `e2e`" in text
        assert "**mode**" in text
        assert "`create` tests or `run` existing tests" in text
        assert "always ask one concise question only" in text
        assert "wait for the answer before using tools" in text
        assert "references/create.md" in text
        assert "references/run.md" in text

    def test_validate_operations_are_progressive_references(self):
        create_ref = SKILLS_DIR / "validate" / "references" / "create.md"
        run_ref = SKILLS_DIR / "validate" / "references" / "run.md"
        assert create_ref.exists()
        assert run_ref.exists()
        assert "check-in text" in create_ref.read_text().lower()
        assert "do not emit check-in text" in run_ref.read_text().lower()

    def test_fix_requires_user_provided_concrete_problem_before_investigation(self):
        """ADR-007's clarification gate must remain explicit in the fix skill."""
        text = (SKILLS_DIR / "develop" / "fix" / "SKILL.md").read_text().lower()
        gate_start = text.index("## 1. secure the target and fix description")
        reproduce_start = text.index("## 2. reproduce first")
        gate = text[gate_start:reproduce_start]

        assert "from the user" in gate
        assert "plain-language description is sufficient" in gate
        assert "ask one concise question" in gate
        assert "do not inspect source files" in gate

    def test_fix_feature_and_develop_prompt_for_jira_up_front(self):
        """ADR-008 prompts for Jira early while keeping it non-blocking."""
        skill_paths = {
            "develop": SKILLS_DIR / "develop" / "SKILL.md",
            "feature": SKILLS_DIR / "develop" / "feature" / "SKILL.md",
            "fix": SKILLS_DIR / "develop" / "fix" / "SKILL.md",
        }
        for skill_name, path in skill_paths.items():
            text = path.read_text().lower()
            normalized = re.sub(r"\s+", " ", text)
            assert "jira id" in normalized
            assert "up front" in normalized
            assert "preferred, not required" in normalized
            assert "atlassian mcp tools are available" in normalized
            assert "fetch the jira record" in normalized
            assert "atlassian mcp tools are unavailable" in normalized
            assert "paste the ticket details" in normalized

        fix_text = (SKILLS_DIR / "develop" / "fix" / "SKILL.md").read_text().lower()
        assert "same clarification" in fix_text

    def test_issue_context_fetches_jira_or_requests_pasted_details(self):
        """Shared issue context owns Atlassian MCP and pasted-ticket fallback."""
        text = (SKILLS_DIR / "develop" / "references" / "issue-context.md").read_text().lower()
        normalized = re.sub(r"\s+", " ", text)
        assert "fetch the jira record" in normalized
        assert "merge its summary" in normalized
        assert "paste the ticket details" in normalized
        assert "preferred, not required" in normalized

    def test_fix_and_develop_require_target_and_work_description(self):
        """ADR-009's two-part intake gate must remain explicit."""
        expectations = {
            SKILLS_DIR / "develop" / "fix" / "SKILL.md": "fix description",
            SKILLS_DIR / "develop" / "SKILL.md": "feature description",
        }
        for path, description_label in expectations.items():
            text = path.read_text().lower()
            intake = text.split("## 2.", 1)[0]

            assert "**target**" in intake
            assert "block, gui, or app" in intake
            assert description_label in intake
            assert "plain-language description is sufficient" in intake
            assert "before using tools" in intake
            assert "wait for the answer" in intake

    def test_jira_prompt_may_repeat_at_phase_completion(self):
        """ADR-010 must keep the completion prompt optional and non-blocking."""
        skill_paths = [
            SKILLS_DIR / "develop" / "fix" / "SKILL.md",
            SKILLS_DIR / "develop" / "SKILL.md",
        ]
        for path in skill_paths:
            text = path.read_text().lower()
            assert "completion summary may ask for it again" in text
            assert "do not repeat the prompt when an id is already known" in text
            assert "do not treat a missing id as incomplete work" in text

    def test_fix_feature_develop_and_review_offer_commit_syntax_without_git_operations(self):
        """Commit syntax is offered while staging/commit stays manual and push is forbidden (ADR-051, ADR-055)."""
        skill_paths = [
            SKILLS_DIR / "develop" / "fix" / "SKILL.md",
            SKILLS_DIR / "develop" / "feature" / "SKILL.md",
            SKILLS_DIR / "develop" / "SKILL.md",
            SKILLS_DIR / "review" / "SKILL.md",
        ]
        for path in skill_paths:
            text = path.read_text().lower()
            normalized = re.sub(r"\s+", " ", text)
            assert "offer to generate conventional commit syntax" in normalized
            assert "generate message text only if the user accepts" in normalized
            assert "manual check-in is the default" in normalized
            # Staging/commit stays manual; pushing is forbidden outright (ADR-055).
            assert "do not run `git add`, `git commit`" in normalized
            assert "never run `git push`" in normalized
            assert "unless the user explicitly asks" in normalized

    def test_editing_workflows_warn_on_non_feature_branches(self):
        """ADR-047 requires a branch warning before code edits on shared branches."""
        skill_paths = [
            SKILLS_DIR / "develop" / "fix" / "SKILL.md",
            SKILLS_DIR / "develop" / "feature" / "SKILL.md",
            SKILLS_DIR / "develop" / "SKILL.md",
            SKILLS_DIR / "review" / "SKILL.md",
        ]
        for path in skill_paths:
            text = path.read_text().lower()
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
        assert not (PROJECT_ROOT / "ucsc-wp-block-dev-presentation.md").exists()

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
        # The roadmap is now harvested from Proposed ADRs (ADR-106), not a
        # hand-maintained list. Assert the harvested region and heading exist.
        assert "## **Roadmap — Proposed ADRs**" in text
        assert "<!-- BEGIN AUTO:roadmap -->" in text
        assert "<!-- END AUTO:roadmap -->" in text

    def test_deck_auto_regions_are_current(self):
        """The harvested AUTO regions must match the live skills + ADR roadmap
        (ADR-106): build-slides.py --check exits 0 when fresh."""
        import subprocess
        import sys

        result = subprocess.run(
            [
                sys.executable,
                str(SKILLS_DIR / "maintainer" / "scripts" / "build-slides.py"),
                "--check",
            ],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0, (
            "deck AUTO regions are stale — run build-slides.py:\n"
            f"{result.stdout}\n{result.stderr}"
        )

    def test_every_skill_has_a_doc_slide_landmark(self):
        """Each public skill carries a doc-slide: landmark for the harvester
        (ADR-106). Falls back to short_description, but we want them present."""
        for path in sorted(p for p in SKILLS_DIR.iterdir() if p.is_dir()):
            skill_md = path / "SKILL.md"
            if not skill_md.exists():
                continue
            assert "doc-slide:" in skill_md.read_text(), (
                f"{path.name}/SKILL.md is missing a <!-- doc-slide: ... --> landmark"
            )

    def test_publisher_uses_maintainer_deck(self):
        text = PUBLISHER.read_text()
        for path_part in [
            '"ucsc-wp-block-dev"',
            '"skills"',
            '"maintainer"',
            '"assets"',
            '"ucsc-wp-block-dev-presentation.md"',
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

    def test_adr_filenames_use_current_convention(self):
        """ADR filenames use ADR-NNN-skill-mode-mode-details.md shape."""
        adr_files = sorted(ADR_DIR.glob("ADR-*.md"))
        bad = [
            adr_file.name
            for adr_file in adr_files
            if not re.match(r"^ADR-\d{3}-[a-z0-9]+(?:-[a-z0-9]+)+\.md$", adr_file.name)
        ]
        assert not bad, "ADR filename convention violations:\n" + "\n".join(
            f"  {name}" for name in bad
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

    def test_adr_files_have_required_sections(self):
        """Every ADR must have ## Context and ## Decision sections."""
        adr_files = sorted(ADR_DIR.glob("ADR-*.md"))
        missing = []
        for adr_file in adr_files:
            text = adr_file.read_text()
            headings = re.findall(r"^## (.+)", text, re.MULTILINE)
            if "Context" not in headings:
                missing.append(f"{adr_file.name}: missing '## Context'")
            if "Decision" not in headings:
                missing.append(f"{adr_file.name}: missing '## Decision'")
        assert not missing, "ADR template violations:\n" + "\n".join(f"  {m}" for m in missing)

    def test_fix_token_study_is_multi_pronged_and_measured(self):
        """ADR-026 must optimize full fix sessions without weakening correctness gates."""
        text = (ADR_DIR / "ADR-026-develop-fix-mode-token-reduction.md").read_text().lower()
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
        """ADR-027 (retired into ADR-028) must preserve its measurement methodology."""
        text = (ADR_DIR / "retired" / "ADR-027-maintainer-study-github-atlassian-mcp-token-cost.md").read_text().lower()
        for configuration in ["fallback only", "on demand", "always on"]:
            assert configuration in text
        assert "measure github and atlassian independently" in text
        assert "local-only fix" in text
        assert "fixed session-start cost" in text
        assert "number of relevant tasks needed to recover" in text
        assert "without explicit user approval" in text

    def test_mcp_activation_is_just_in_time_and_token_driven(self):
        """ADR-028 must keep the multi-purpose plugin light and activation controlled."""
        text = (ADR_DIR / "ADR-028-maintainer-start-mcp-just-in-time-when-token-efficient.md").read_text().lower()
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

    def test_public_artifacts_do_not_contain_private_identifiers(self):
        """Known personal and organization-private examples stay out of releases."""
        forbidden = [
            "hen" + "ryh",
            "ucsc-its" + ".atlassian.net",
            "WPM" + "-97",
            "ucscwebapps" + "/wdt-common",
            "wordpress-dev" + ".ucsc.edu",
            "1Qj8bnNorBnD_" + "ChbKD4BDLzBNFmTeqOArbrepNQh2Elw",
            "18Ozi1BJ60eH2_" + "-mX5rpA08YsLtFwUAHC0nMErhsCxwo",
        ]
        text_files = []
        for path in PLUGIN_ROOT.rglob("*"):
            if not path.is_file() or "__pycache__" in path.parts:
                continue
            content = path.read_bytes()
            if b"\0" not in content:
                text_files.append(content.decode(errors="ignore"))
        corpus = "\n".join(text_files)
        for identifier in forbidden:
            assert identifier not in corpus, f"private identifier is public: {identifier}"

    def test_feedback_payload_omits_local_path_and_branch(self):
        script = (SKILLS_DIR / "feedback" / "scripts" / "submit-feedback.sh").read_text()
        assert '"cwd"' not in script
        assert '"git_branch"' not in script
        assert "FB_" + "CWD" not in script
        assert "FB_" + "BRANCH" not in script

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

    def test_plugin_node_modules_not_committed(self):
        """ADR-108: plugin-root node_modules/ must never be tracked by git."""
        import subprocess
        node_modules = PLUGIN_ROOT / "node_modules"
        r = subprocess.run(
            ["git", "ls-files", str(node_modules)],
            capture_output=True, text=True,
            cwd=str(PLUGIN_ROOT),
        )
        assert r.stdout.strip() == "", (
            "Plugin-root node_modules/ is tracked by git — add it to .gitignore (ADR-108)"
        )

    def test_all_markdown_links_resolve(self):
        """All relative file links inside markdown files must resolve to existing files."""
        md_files = list(PLUGIN_ROOT.rglob("*.md"))
        assert len(md_files) > 0
        for path in md_files:
            text = path.read_text(errors="ignore")
            links = re.findall(r"\[[^\]]+\]\(([^)]+)\)", text)
            for link in links:
                if link.startswith(("http://", "https://", "mailto:", "file://", "#")):
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

    def test_skill_support_file_naming(self):
        """ADR-032: skill support filenames use lowercase kebab-case."""
        ignored = {"SKILL.md"}
        for path in SKILLS_DIR.rglob("*"):
            if not path.is_file() or path.name in ignored:
                continue
            if "__pycache__" in path.parts or path.suffix == ".pyc":
                continue
            assert re.match(r"^[a-z0-9]+(?:-[a-z0-9]+)*(?:\.[a-z0-9]+)?$", path.name), (
                f"Skill support file '{path.relative_to(PLUGIN_ROOT)}' is not kebab-case"
            )

    def test_token_usage_is_user_scoped(self):
        """ADR-076: token usage belongs in the user cache, not the repository."""
        assert not (PLUGIN_ROOT / "logs" / "token-usage.log").exists()
        assert (
            PLUGIN_ROOT
            / "skills"
            / "maintainer"
            / "scripts"
            / "token-usage.py"
        ).exists()

    def test_gitignore_ignores_venv_and_pycache(self):
        """Verify .gitignore includes rules to ignore python caches and virtual environment."""
        gitignore = PLUGIN_ROOT / ".gitignore"
        assert gitignore.exists()
        text = gitignore.read_text()
        assert ".venv/" in text or ".venv" in text
        assert "__pycache__/" in text or "__pycache__" in text
        assert ".pytest_cache/" in text or ".pytest_cache" in text

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
        offenders = []
        for path in PLUGIN_ROOT.rglob("*"):
            if "__pycache__" in path.parts or ".pytest_cache" in path.parts:
                continue
            if path.is_file() and FORBIDDEN_PLUGIN_NAME in path.read_text(errors="ignore"):
                offenders.append(str(path.relative_to(PLUGIN_ROOT)))
        assert offenders == [], (
            f"Use '{PLUGIN_NAME}' for machine-facing identifiers; found "
            f"'{FORBIDDEN_PLUGIN_NAME}' in: {offenders}"
        )


class TestAgentsMd:
    """AGENTS.md at the project root must stay in sync with live skills."""

    def test_agents_md_exists(self):
        assert (PROJECT_ROOT / "AGENTS.md").exists(), "AGENTS.md not found at repo root"

    def test_agents_md_lists_all_live_skills(self):
        """Every live skill must appear in the AGENTS.md skill routing table."""
        text = (PROJECT_ROOT / "AGENTS.md").read_text()
        actual_skills = {
            path.name
            for path in SKILLS_DIR.iterdir()
            if path.is_dir() and (path / "SKILL.md").exists()
        }
        for skill_name in sorted(actual_skills):
            assert f"`{skill_name}`" in text, (
                f"AGENTS.md missing live skill '{skill_name}' — "
                "run sync-inventory.sh --write to regenerate"
            )

    def test_agents_md_has_no_stale_skills(self):
        """No retired skill names should appear in the AGENTS.md routing table rows."""
        text = (PROJECT_ROOT / "AGENTS.md").read_text()
        actual_skills = {
            path.name
            for path in SKILLS_DIR.iterdir()
            if path.is_dir() and (path / "SKILL.md").exists()
        }
        allowed_modes = {
            "develop feature",
            "develop fix",
            "validate php",
            "validate jest",
            "validate e2e",
        }
        listed = set(re.findall(r"^\| `([^`]+)` \|", text, re.MULTILINE))
        stale = listed - actual_skills - allowed_modes
        assert not stale, (
            f"AGENTS.md routing table references retired skills: {sorted(stale)} — "
            "run sync-inventory.sh --write to regenerate"
        )
