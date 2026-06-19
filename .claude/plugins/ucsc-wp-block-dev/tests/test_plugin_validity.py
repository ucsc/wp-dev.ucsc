"""Tests for ucsc-wp-block-dev as a Claude Code plugin.

Validates the plugin from Claude Code's perspective:
- Does `claude plugin validate` pass?
- Does `claude plugin details` report the expected inventory?
- Are skill descriptions consistent and within token budget?
- Does the plugin load cleanly via --plugin-dir?
"""

import os
import re
import subprocess
from pathlib import Path

import pytest

PLUGIN_ROOT = Path(__file__).resolve().parent.parent
SKILLS_DIR = PLUGIN_ROOT / "skills"
# The plugin is installed at *project* scope, so the claude CLI only resolves it
# (e.g. `claude plugin details`) when run from the project root — the directory
# that owns the `.claude/` registering it, three levels up from PLUGIN_ROOT
# (<project>/.claude/plugins/ucsc-wp-block-dev). Running from inside the plugin
# subdir makes `plugin details` report "not found" even though it loads fine.
PROJECT_ROOT = PLUGIN_ROOT.parents[2]


def plugin_details() -> subprocess.CompletedProcess:
    """Run `claude plugin details` from the project root so the project-scoped
    install resolves by name."""
    return subprocess.run(
        ["claude", "plugin", "details", "ucsc-wp-block-dev"],
        capture_output=True, text=True, timeout=30, cwd=str(PROJECT_ROOT),
    )


# ---------------------------------------------------------------------------
# claude CLI availability
# ---------------------------------------------------------------------------

def claude_available() -> bool:
    try:
        r = subprocess.run(["claude", "--version"], capture_output=True, text=True, timeout=10)
        return r.returncode == 0
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return False


HAVE_CLAUDE = claude_available()
requires_claude = pytest.mark.skipif(os.environ.get("CLAUDE_AVAILABLE") != "1" or not HAVE_CLAUDE, reason="claude CLI not available or CLAUDE_AVAILABLE not set")


def wp_blocks_installed() -> bool:
    if not HAVE_CLAUDE:
        return False
    try:
        r = subprocess.run(
            ["claude", "plugin", "list"],
            capture_output=True, text=True, timeout=10, cwd=str(PROJECT_ROOT),
        )
        return "ucsc-wp-block-dev" in r.stdout
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return False


WP_BLOCKS_INSTALLED = wp_blocks_installed()
requires_installed = pytest.mark.skipif(
    not WP_BLOCKS_INSTALLED,
    reason="ucsc-wp-block-dev not installed — run `claude plugin install` first",
)


# ---------------------------------------------------------------------------
# Plugin validation via claude CLI
# ---------------------------------------------------------------------------

class TestPluginValidate:
    @requires_claude
    def test_validate_passes(self):
        r = subprocess.run(
            ["claude", "plugin", "validate", str(PLUGIN_ROOT)],
            capture_output=True, text=True, timeout=30,
        )
        assert r.returncode == 0
        assert "passed" in r.stdout.lower()

    @requires_claude
    def test_validate_strict_passes(self):
        r = subprocess.run(
            ["claude", "plugin", "validate", "--strict", str(PLUGIN_ROOT)],
            capture_output=True, text=True, timeout=30,
        )
        assert r.returncode == 0
        assert "passed" in r.stdout.lower()


class TestPluginDetails:
    @requires_installed
    def test_details_shows_skills(self):
        r = plugin_details()
        assert r.returncode == 0
        assert "Skills" in r.stdout

    @requires_installed
    def test_expected_skill_count(self):
        r = plugin_details()
        m = re.search(r"Skills\s+\((\d+)\)", r.stdout)
        assert m, "Could not find skill count in details output"
        count = int(m.group(1))
        actual = sum(1 for s in SKILLS_DIR.iterdir() if s.is_dir() and (s / "SKILL.md").exists())
        assert count == actual, (
            f"claude plugin details reports {count} skills but {actual} SKILL.md files exist"
        )

    @requires_installed
    def test_core_skills_present(self):
        r = plugin_details()
        for skill in ["hub", "develop", "test", "review", "run", "verify", "maintainer"]:
            assert skill in r.stdout, f"Core skill '{skill}' missing from plugin details"

    @requires_installed
    def test_no_mcp_or_lsp(self):
        r = plugin_details()
        assert "MCP servers (0)" in r.stdout
        assert "LSP servers (0)" in r.stdout


# ---------------------------------------------------------------------------
# Token budget
# ---------------------------------------------------------------------------

class TestTokenBudget:
    @requires_installed
    def test_always_on_under_threshold(self):
        r = plugin_details()
        m = re.search(r"Always-on:\s+~([\d,]+)\s+tok", r.stdout)
        assert m, "Could not find always-on token count"
        tokens = int(m.group(1).replace(",", ""))
        assert tokens < 3000, (
            f"Always-on token cost is {tokens}, should be under 3000"
        )

    @requires_installed
    def test_no_skill_exceeds_invoke_threshold(self):
        r = plugin_details()
        matches = list(re.finditer(r"^\s+(\S+)\s+~[\d.]+k?\s+~([\d.,]+)(k?)\s*$", r.stdout, re.MULTILINE))
        assert matches, "Could not parse skill cost table from plugin details output"
        for m in matches:
            skill_name = m.group(1)
            raw = float(m.group(2).replace(",", ""))
            cost = raw * 1000 if m.group(3) == "k" else raw
            assert cost < 10000, (
                f"Skill '{skill_name}' on-invoke cost is ~{cost:.0f} tokens, should be under 10k"
            )


# ---------------------------------------------------------------------------
# Skill routing and descriptions
# ---------------------------------------------------------------------------

class TestSkillRouting:
    """Validate that skill descriptions are consistent and well-formed."""

    def _read_frontmatter(self, skill_dir: Path) -> dict:
        text = (skill_dir / "SKILL.md").read_text()
        fm_match = re.match(r"^---\n(.+?)\n---", text, re.DOTALL)
        if not fm_match:
            return {}
        fm = {}
        for line in fm_match.group(1).splitlines():
            if ":" in line:
                key, _, val = line.partition(":")
                fm[key.strip()] = val.strip().strip('"').strip("'")
        return fm

    def test_all_skills_have_description(self):
        for skill_dir in sorted(SKILLS_DIR.iterdir()):
            if not (skill_dir / "SKILL.md").exists():
                continue
            fm = self._read_frontmatter(skill_dir)
            assert fm.get("description"), f"{skill_dir.name} has empty description"
            assert len(fm["description"]) > 20, (
                f"{skill_dir.name} description too short: '{fm['description']}'"
            )

    def test_no_duplicate_skill_names(self):
        names = []
        for skill_dir in sorted(SKILLS_DIR.iterdir()):
            if not (skill_dir / "SKILL.md").exists():
                continue
            fm = self._read_frontmatter(skill_dir)
            name = fm.get("name", skill_dir.name)
            assert name not in names, f"Duplicate skill name: {name}"
            names.append(name)

    def test_frontmatter_is_portable(self):
        """Skills use only official Claude Code skills frontmatter fields (ADR-070)."""
        allowed = {
            "name", "description", "when_to_use", "argument-hint", "arguments",
            "disable-model-invocation", "user-invocable", "allowed-tools",
            "disallowed-tools", "model", "effort", "context", "agent",
            "hooks", "paths", "shell",
        }
        for skill_dir in sorted(SKILLS_DIR.iterdir()):
            if not (skill_dir / "SKILL.md").exists():
                continue
            fm = self._read_frontmatter(skill_dir)
            extra = set(fm) - allowed
            assert not extra, (
                f"{skill_dir.name} has unrecognized frontmatter keys: {extra}"
            )

    def test_wp_keywords_in_descriptions(self):
        """Each skill description should reference at least one WordPress/block concept."""
        wp_terms = {"block", "wordpress", "gutenberg", "php", "wp-scripts", "jest", "docker", "build"}
        for skill_dir in sorted(SKILLS_DIR.iterdir()):
            if not (skill_dir / "SKILL.md").exists():
                continue
            fm = self._read_frontmatter(skill_dir)
            desc = fm.get("description", "").lower()
            assert any(term in desc for term in wp_terms), (
                f"{skill_dir.name} description has no WordPress/block keywords: '{desc[:80]}'"
            )


# ---------------------------------------------------------------------------
# Plugin loading smoke test
# ---------------------------------------------------------------------------

class TestPluginDirLoading:
    """Verify the plugin loads cleanly via --plugin-dir."""

    @requires_claude
    @pytest.mark.skip(reason="Skipping claude CLI smoke test to avoid external tokens during local runs")
    def test_plugin_dir_loads_without_error(self):
        r = subprocess.run(
            [
                "claude", "--plugin-dir", str(PLUGIN_ROOT),
                "-p", "list your ucsc-wp-block-dev skills as a comma-separated list",
                "--output-format", "text",
            ],
            capture_output=True, text=True, timeout=60,
        )
        assert r.returncode == 0, f"Plugin failed to load: {r.stderr}"
        out = r.stdout.lower()
        assert any(skill in out for skill in ["develop", "fix", "maintainer", "run"]), (
            f"Plugin loaded but skills not visible in response: {r.stdout[:200]}"
        )
