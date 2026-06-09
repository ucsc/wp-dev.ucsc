"""Tests for the Codex wrapper adapter (.agents/codex.sh) and its configuration files."""

import json
import os
import subprocess
from pathlib import Path

# Paths relative to the plugin root
PLUGIN_ROOT = Path(__file__).resolve().parent.parent
PROJECT_ROOT = PLUGIN_ROOT.parents[2]
AGENTS_DIR = PROJECT_ROOT / ".agents"
CODEX_SH = AGENTS_DIR / "codex.sh"
MARKETPLACE_JSON = AGENTS_DIR / "plugins" / "marketplace.json"
CODEX_PLUGIN_DIR = AGENTS_DIR / "plugins" / "ucsc-wp-block-dev"
CODEX_MANIFEST = CODEX_PLUGIN_DIR / ".codex-plugin" / "plugin.json"
CLAUDE_MANIFEST = PLUGIN_ROOT / ".claude-plugin" / "plugin.json"

class TestCodexWrapper:
    def test_codex_sh_exists_and_is_executable(self):
        """Verify codex.sh exists and is executable."""
        assert CODEX_SH.exists(), f"codex.sh not found at {CODEX_SH}"
        assert os.access(CODEX_SH, os.X_OK), "codex.sh is not executable"
        
        # Check shebang
        content = CODEX_SH.read_text()
        assert content.startswith("#!/usr/bin/env bash") or content.startswith("#!/bin/bash")

    def test_marketplace_json_validity(self):
        """Verify marketplace.json contains valid configuration for Codex."""
        assert MARKETPLACE_JSON.exists(), f"marketplace.json not found at {MARKETPLACE_JSON}"
        
        data = json.loads(MARKETPLACE_JSON.read_text())
        assert "name" in data
        assert data["name"] == "ucsc-wordpress-local"
        assert "plugins" in data
        assert isinstance(data["plugins"], list)
        
        plugin_entry = next((p for p in data["plugins"] if p.get("name") == "ucsc-wp-block-dev"), None)
        assert plugin_entry is not None, "ucsc-wp-block-dev plugin missing from marketplace.json"
        assert plugin_entry.get("source", {}).get("path") == "./.agents/plugins/ucsc-wp-block-dev"

    def test_manifest_consistency(self):
        """Verify that the Codex manifest matches the Claude plugin manifest."""
        assert CLAUDE_MANIFEST.exists(), f"Claude manifest not found at {CLAUDE_MANIFEST}"
        assert CODEX_MANIFEST.exists(), f"Codex manifest not found at {CODEX_MANIFEST}"
        
        claude_data = json.loads(CLAUDE_MANIFEST.read_text())
        codex_data = json.loads(CODEX_MANIFEST.read_text())
        
        assert claude_data["name"] == codex_data["name"], "Plugin names do not match"
        
        # Codex version has +codex.timestamp suffix, check base version
        claude_ver = claude_data["version"]
        codex_ver = codex_data["version"].split("+", 1)[0]
        assert claude_ver == codex_ver, f"Claude version {claude_ver} does not match Codex base version {codex_ver}"
        
        assert "skills" in codex_data
        assert codex_data["skills"] == "./skills/"

    def test_codex_sh_run_execution(self):
        """Verify that running codex.sh returns exit code 0 and syncs successfully."""
        # Run without installation flag to perform a sync check
        res = subprocess.run([str(CODEX_SH)], capture_output=True, text=True, cwd=str(PROJECT_ROOT))
        assert res.returncode == 0, f"codex.sh execution failed:\nSTDOUT: {res.stdout}\nSTDERR: {res.stderr}"
        
        # Verify sync was successful by checking that files in the source skills are copied to Codex skills
        source_skills = list((PLUGIN_ROOT / "skills").rglob("SKILL.md"))
        assert len(source_skills) > 0, "No skills found in Claude plugin"
        
        for source_skill in source_skills:
            rel_path = source_skill.relative_to(PLUGIN_ROOT)
            target_skill = CODEX_PLUGIN_DIR / rel_path
            
            assert target_skill.exists(), f"Synced skill file missing: {target_skill}"
            assert target_skill.read_text() == source_skill.read_text(), f"Content mismatch for {rel_path}"
