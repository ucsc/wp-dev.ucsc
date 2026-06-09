#!/usr/bin/env python3
"""
Monitor API changes (skills, version, names, commands) for the ucsc-wp-block-dev plugin.
Checks if the current plugin API surface matches a saved signature file, detects changes,
and checks if the generated slide deck is in sync.
"""

import json
import os
import re
import sys
from pathlib import Path

# Paths
AGENT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = AGENT_DIR.parent
PLUGIN_DIR = PROJECT_ROOT / ".claude" / "plugins" / "ucsc-wp-block-dev"
MANIFEST_PATH = PLUGIN_DIR / ".claude-plugin" / "plugin.json"
SKILLS_DIR = PLUGIN_DIR / "skills"
SIGNATURE_FILE = AGENT_DIR / "api_signature.json"
SLIDES_PATH = PROJECT_ROOT / "ucsc_wp_block_dev_presentation.md"

def get_plugin_manifest():
    if not MANIFEST_PATH.exists():
        return None
    try:
        return json.loads(MANIFEST_PATH.read_text())
    except Exception as e:
        print(f"[ERROR] Failed to read/parse manifest: {e}", file=sys.stderr)
        return None

def parse_skill_file(skill_md_path):
    content = skill_md_path.read_text()
    
    # Parse frontmatter
    name = None
    description = ""
    fm_match = re.match(r"^---\s*\n(.*?)\n---\s*\n", content, re.DOTALL)
    if fm_match:
        fm_content = fm_match.group(1)
        name_match = re.search(r"^name:\s*(.+)$", fm_content, re.MULTILINE)
        desc_match = re.search(r"^description:\s*(.+)$", fm_content, re.MULTILINE)
        if name_match:
            name = name_match.group(1).strip().strip("'\"")
        if desc_match:
            description = desc_match.group(1).strip().strip("'\"")
            
    # Find commands/usages
    usages = []
    # Search for lines like: Usage: `/ucsc-wp-block-dev:develop [args]`
    usage_matches = re.findall(r"Usage:\s*`(/ucsc-wp-block-dev:[^`]+)`", content, re.IGNORECASE)
    for u in usage_matches:
        usages.append(u.strip())
        
    return {
        "name": name or skill_md_path.parent.name,
        "description": description,
        "usages": usages
    }

def get_current_signature():
    manifest = get_plugin_manifest()
    if not manifest:
        print("[ERROR] Could not load plugin manifest.", file=sys.stderr)
        sys.exit(1)
        
    skills = {}
    if SKILLS_DIR.exists():
        for skill_dir in sorted(SKILLS_DIR.iterdir()):
            if skill_dir.is_dir():
                skill_file = skill_dir / "SKILL.md"
                if skill_file.exists():
                    skills[skill_dir.name] = parse_skill_file(skill_file)
                    
    return {
        "plugin_name": manifest.get("name"),
        "version": manifest.get("version"),
        "description": manifest.get("description"),
        "skills": skills
    }

def verify_slides_in_sync(signature):
    if not SLIDES_PATH.exists():
        print(f"[WARNING] Slide file not found at {SLIDES_PATH}")
        return False
        
    slides_content = SLIDES_PATH.read_text()
    
    # Check if all skills are mentioned in the slides
    mismatches = []
    for skill_name, skill_data in signature["skills"].items():
        # Skill name should be in the slides content (case-insensitive check)
        if skill_name.lower() not in slides_content.lower():
            mismatches.append(f"Skill '{skill_name}' is not mentioned in slides.")
            
        for usage in skill_data["usages"]:
            # Command should be in the slides content
            if usage.lower() not in slides_content.lower():
                mismatches.append(f"Command '{usage}' is not mentioned in slides.")
                
    if mismatches:
        print("\n=== SLIDE OUT-OF-SYNC WARNING ===")
        for m in mismatches:
            print(f"- {m}")
        print("=================================\n")
        return False
    else:
        print("[OK] All skills and commands from plugin are referenced in the slides.")
        return True

def main():
    print("Scanning plugin API surface...")
    current = get_current_signature()
    
    # Check if saved signature exists
    if not SIGNATURE_FILE.exists():
        print(f"Creating initial API signature cache at {SIGNATURE_FILE.relative_to(PROJECT_ROOT)}")
        SIGNATURE_FILE.write_text(json.dumps(current, indent=2))
        verify_slides_in_sync(current)
        return
        
    try:
        saved = json.loads(SIGNATURE_FILE.read_text())
    except Exception as e:
        print(f"[ERROR] Failed to parse saved signature: {e}", file=sys.stderr)
        sys.exit(1)
        
    # Compare
    changed = False
    
    if current["plugin_name"] != saved.get("plugin_name"):
        print(f"[CHANGE] Plugin name: {saved.get('plugin_name')} -> {current['plugin_name']}")
        changed = True
        
    if current["version"] != saved.get("version"):
        print(f"[CHANGE] Plugin version: {saved.get('version')} -> {current['version']}")
        changed = True
        
    # Compare skills
    curr_skills = set(current["skills"].keys())
    saved_skills = set(saved.get("skills", {}).keys())
    
    added_skills = curr_skills - saved_skills
    removed_skills = saved_skills - curr_skills
    
    if added_skills:
        print(f"[CHANGE] Skills added: {', '.join(added_skills)}")
        changed = True
        
    if removed_skills:
        print(f"[CHANGE] Skills removed: {', '.join(removed_skills)}")
        changed = True
        
    for skill in curr_skills & saved_skills:
        curr_s = current["skills"][skill]
        saved_s = saved["skills"][skill]
        
        if curr_s["description"] != saved_s.get("description"):
            print(f"[CHANGE] Skill '{skill}' description changed.")
            changed = True
            
        if curr_s["usages"] != saved_s.get("usages"):
            print(f"[CHANGE] Skill '{skill}' commands changed: {saved_s.get('usages')} -> {curr_s['usages']}")
            changed = True
            
    if changed:
        print("\n[ALERT] API changes detected! Updating signature cache...")
        SIGNATURE_FILE.write_text(json.dumps(current, indent=2))
    else:
        print("[OK] No API changes detected since last scan.")
        
    verify_slides_in_sync(current)

if __name__ == "__main__":
    main()
