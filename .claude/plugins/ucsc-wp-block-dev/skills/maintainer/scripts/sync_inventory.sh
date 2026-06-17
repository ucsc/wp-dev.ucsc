#!/bin/bash
# sync_inventory.sh — enforces inventory consistency by treating skills/*/ as the
# source of truth and checking (or updating) the README, hub listing, slide deck
# presentation table, and the python test suite skill expectations.
#
# Usage:
#   bash sync_inventory.sh [--check]    # Dry-run check for drift (default)
#   bash sync_inventory.sh --write      # Update the inventory lists in all files
#
# Exit code 0 if matching/updated, 1 if out of sync.

set -uo pipefail

export SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Execute inline Python script to handle inventory synchronization
python3 - "$@" <<'EOF'
import os
import sys
import re

# Determine directories
SCRIPT_DIR = os.environ.get("SCRIPT_DIR")
if not SCRIPT_DIR:
    # Fallback to current working directory structure
    SCRIPT_DIR = os.path.abspath(os.path.join(os.getcwd(), "skills", "maintainer", "scripts"))

PLUGIN_DIR = os.path.abspath(os.path.join(SCRIPT_DIR, "..", "..", ".."))
skills_dir = os.path.abspath(os.path.join(SCRIPT_DIR, "..", ".."))

# Parse arguments
write_mode = "--write" in sys.argv

# Define canonical metadata for all existing/known skills to match desired table layouts.
# If a new skill is added, it will fall back to using its frontmatter description.
METADATA = {
    "develop": {
        "readme": "Add or modify block code directly, or invoked by feature/fix after scope is defined",
        "hub": "Add or modify block code (PHP, template, JS editor, REST, build) — use directly or invoked by `feature`/`fix`.",
        "deck_trigger": "Block code changes",
        "deck_desc": "Adds or modifies PHP class, template, JS editor, REST, and build steps."
    },
    "feature": {
        "readme": "Add new behavior through the preferred feature workflow",
        "hub": "Define and implement new block behavior, blocks, or editor/frontend enhancements.",
        "deck_trigger": "New behavior",
        "deck_desc": "Preferred feature workflow."
    },
    "fix": {
        "readme": "Fix a described problem in a specified target block, GUI, or app",
        "hub": "Debug and fix a described defect in a specified block, GUI, or app.",
        "deck_trigger": "Bug or regression",
        "deck_desc": "Debugs JS, PHP, REST API, or transient caching bugs."
    },
    "hub": {
        "readme": "List every available skill and command (`:hub`) — enumeration only",
        "hub": None,  # Hub is not listed in its own public workflows table
        "deck_trigger": '"List the skills" (`:hub`)',
        "deck_desc": "Enumerates the available skills and commands; does not route (ADR-060)."
    },
    "maintainer": {
        "readme": None,
        "hub": "Maintain the plugin itself: validate, test, review/promote contrib skills, check references, generate docs, publish slides (ADR-046).",
        "deck_trigger": "Plugin maintenance",
        "deck_desc": "Validate, test, check references, generate docs, publish slides."
    },
    "retrospective": {
        "readme": None,
        "hub": "Capture session lessons into skill and script files. Offered at the end of fix, feature, review, and run sessions (ADR-059).",
        "deck_trigger": "Post-session capture",
        "deck_desc": "Capture session lessons into skill and script files."
    },
    "review": {
        "readme": "Review a diff, branch, file, block, or Jira-scoped change",
        "hub": "Review a diff, branch, file, PR, or Jira-scoped change for bugs, regressions, security, a11y, and missing tests.",
        "deck_trigger": "Review request",
        "deck_desc": "Reviews a diff, branch, file, or Jira-scoped change."
    },
    "run": {
        "readme": "Build, launch, and drive blocks via the wp-dev.ucsc Docker environment",
        "hub": "Build, launch, and drive the plugin in the wp-dev.ucsc Docker environment.",
        "deck_trigger": "Build or launch request",
        "deck_desc": "Records and executes the Docker setup, build, launch, and app-driving recipe."
    },
    "survey": {
        "readme": "Run and interpret the WordPress block survey to audit UCSC custom block usage across CampusPress sites",
        "hub": "Run and interpret the WordPress block survey to audit UCSC custom block usage across CampusPress sites.",
        "deck_trigger": '"survey"',
        "deck_desc": "Run and interpret the WordPress block survey to audit UCSC custom block usage across CampusPress sites."
    },
    "test": {
        "readme": "Create or run focused PHP, Jest, or end-to-end tests",
        "hub": "Create or run automated PHP, Jest, or e2e tests.",
        "deck_trigger": "Test creation or execution",
        "deck_desc": "Creates or runs PHP, Jest, or end-to-end tests."
    },
    "verify": {
        "readme": "Live DOM test of a code change or acceptance criterion in the running WordPress editor or frontend",
        "hub": "Live DOM test of a change or acceptance criterion in the running WordPress editor or frontend.",
        "deck_trigger": "Acceptance verification",
        "deck_desc": "Live DOM test of a change in the running WordPress editor or frontend."
    }
}

def get_skill_description(skill_name, skill_md_path):
    try:
        content = open(skill_md_path).read()
        m = re.search(r'^description:\s*(.*?)(?=^[a-zA-Z_-]+:|^-)', content, re.MULTILINE | re.DOTALL)
        if m:
            desc = m.group(1).replace('\n', ' ').strip()
            desc = re.sub(r'\s+', ' ', desc)
            return desc
    except Exception:
        pass
    return f"Run the {skill_name} skill workflow."

# Get list of live skills on disk (directories containing SKILL.md)
live_skills = []
for d in sorted(os.listdir(skills_dir)):
    if os.path.isdir(os.path.join(skills_dir, d)) and os.path.exists(os.path.join(skills_dir, d, "SKILL.md")):
        live_skills.append(d)

print(f"Syncing skills: {', '.join(live_skills)}")

success = True

# 1. Sync README.md
readme_path = os.path.join(PLUGIN_DIR, "README.md")
if os.path.exists(readme_path):
    readme_content = open(readme_path).read()
    
    # Generate README table
    lines = [
        "| Skill | Purpose |",
        "|---|---|"
    ]
    for s in live_skills:
        if s in ["maintainer", "retrospective"]:
            continue
        desc = METADATA.get(s, {}).get("readme") or get_skill_description(s, os.path.join(skills_dir, s, "SKILL.md"))
        lines.append(f"| `{s}` | {desc} |")
    
    pattern = r"(\| Skill \| Purpose \|\s*\n\|---\|---\|\s*\n)(.*?)(?=\n\n|\n[^|]|\Z)"
    match = re.search(pattern, readme_content, re.DOTALL)
    if match:
        current_body = match.group(2).strip()
        expected_body = "\n".join(lines[2:]).strip()
        if current_body != expected_body:
            if write_mode:
                new_table = match.group(1) + expected_body
                new_content = readme_content[:match.start()] + new_table + readme_content[match.end():]
                with open(readme_path, "w") as f:
                    f.write(new_content)
                print("  [ OK ] README.md skills table updated")
            else:
                print("  [FAIL] README.md skills table is out of sync")
                success = False
        else:
            print("  [ OK ] README.md skills table is in sync")
    else:
        print("  [FAIL] README.md: skills table not found")
        success = False
else:
    print(f"  [FAIL] README.md not found at {readme_path}")
    success = False

# 2. Sync skills/hub/SKILL.md
hub_path = os.path.join(skills_dir, "hub", "SKILL.md")
if os.path.exists(hub_path):
    hub_content = open(hub_path).read()
    
    # Public workflows table
    lines = [
        "| Skill | Purpose |",
        "|---|---|"
    ]
    for s in live_skills:
        if s in ["hub", "maintainer", "retrospective"]:
            continue
        desc = METADATA.get(s, {}).get("hub") or get_skill_description(s, os.path.join(skills_dir, s, "SKILL.md"))
        lines.append(f"| `{s}` | {desc} |")
        
    pattern_pub = r"(## Public workflows\s*\n\s*\| Skill \| Purpose \|\s*\n\|---\|---\|\s*\n)(.*?)(?=\n\n|\n[^|]|\Z)"
    match_pub = re.search(pattern_pub, hub_content, re.DOTALL)
    
    # Hidden manual skills list
    hidden_lines = []
    for s in live_skills:
        if s in ["maintainer", "retrospective"]:
            desc = METADATA.get(s, {}).get("hub") or get_skill_description(s, os.path.join(skills_dir, s, "SKILL.md"))
            hidden_lines.append(f"- `{s}` — {desc}")
            
    pattern_hid = r"(## Hidden manual skills\s*\n\s*Reachable by typing the name directly; omitted from the routed workflow list\.\s*\n\s*)(.*?)(?=\n\n|\n[^-\s]|\Z)"
    match_hid = re.search(pattern_hid, hub_content, re.DOTALL)
    
    pub_ok = False
    if match_pub:
        current_pub = match_pub.group(2).strip()
        expected_pub = "\n".join(lines[2:]).strip()
        pub_ok = current_pub == expected_pub
        
    hid_ok = False
    if match_hid:
        current_hid = match_hid.group(2).strip()
        expected_hid = "\n".join(hidden_lines).strip()
        hid_ok = current_hid == expected_hid
        
    if pub_ok and hid_ok:
        print("  [ OK ] skills/hub/SKILL.md is in sync")
    else:
        if write_mode:
            new_content = hub_content
            if not pub_ok and match_pub:
                new_pub = match_pub.group(1) + expected_pub
                new_content = new_content[:match_pub.start()] + new_pub + new_content[match_pub.end():]
                # Re-search hidden because index shifted
                match_hid = re.search(pattern_hid, new_content, re.DOTALL)
            if not hid_ok and match_hid:
                new_hid = match_hid.group(1) + expected_hid
                new_content = new_content[:match_hid.start()] + new_hid + new_content[match_hid.end():]
            with open(hub_path, "w") as f:
                f.write(new_content)
            print("  [ OK ] skills/hub/SKILL.md updated")
        else:
            if not pub_ok:
                print("  [FAIL] skills/hub/SKILL.md public workflows table is out of sync")
            if not hid_ok:
                print("  [FAIL] skills/hub/SKILL.md hidden manual skills list is out of sync")
            success = False
else:
    print(f"  [FAIL] skills/hub/SKILL.md not found")
    success = False

# 3. Sync Presentation Deck
deck_path = os.path.join(skills_dir, "maintainer", "assets", "ucsc_wp_block_dev_presentation.md")
if os.path.exists(deck_path):
    deck_content = open(deck_path).read()
    
    lines = [
        "| Skill | Trigger | Purpose |",
        "| :--- | :--- | :--- |"
    ]
    for s in live_skills:
        if s in ["maintainer", "retrospective"]:
            continue
        trigger = METADATA.get(s, {}).get("deck_trigger") or f'"{s}"'
        desc = METADATA.get(s, {}).get("deck_desc") or get_skill_description(s, os.path.join(skills_dir, s, "SKILL.md"))
        lines.append(f"| **`{s}`** | {trigger} | {desc} |")
        
    pattern = r"(\| Skill \| Trigger \| Purpose \|\s*\n\| :---\ \| :---\ \| :---\ \|\s*\n)(.*?)(?=\n\n|\n[^|]|\Z)"
    match = re.search(pattern, deck_content, re.DOTALL)
    if match:
        current_body = match.group(2).strip()
        expected_body = "\n".join(lines[2:]).strip()
        if current_body != expected_body:
            if write_mode:
                new_table = match.group(1) + expected_body
                new_content = deck_content[:match.start()] + new_table + deck_content[match.end():]
                with open(deck_path, "w") as f:
                    f.write(new_content)
                print("  [ OK ] Presentation deck skills table updated")
            else:
                print("  [FAIL] Presentation deck skills table is out of sync")
                success = False
        else:
            print("  [ OK ] Presentation deck skills table is in sync")
    else:
        print("  [FAIL] Presentation deck skills table not found")
        success = False
else:
    print(f"  [FAIL] Presentation deck not found at {deck_path}")
    success = False

# 4. Sync tests/test_plugin_structure.py
tests_path = os.path.join(PLUGIN_DIR, "tests", "test_plugin_structure.py")
if os.path.exists(tests_path):
    tests_content = open(tests_path).read()
    
    pattern = r"(EXPECTED_LIVE_SKILLS = \{)(.*?)(\})"
    match = re.search(pattern, tests_content, re.DOTALL)
    if match:
        current_body = match.group(2).strip()
        expected_body = "\n" + "".join(f'    "{s}",\n' for s in live_skills) + "   "
        
        curr_norm = re.sub(r'\s+', ' ', current_body).strip()
        exp_norm = re.sub(r'\s+', ' ', expected_body).strip()
        
        if curr_norm != exp_norm:
            if write_mode:
                new_block = match.group(1) + expected_body + match.group(3)
                new_content = tests_content[:match.start()] + new_block + tests_content[match.end():]
                with open(tests_path, "w") as f:
                    f.write(new_content)
                print("  [ OK ] test_plugin_structure.py EXPECTED_LIVE_SKILLS updated")
            else:
                print("  [FAIL] test_plugin_structure.py EXPECTED_LIVE_SKILLS is out of sync")
                success = False
        else:
            print("  [ OK ] test_plugin_structure.py EXPECTED_LIVE_SKILLS is in sync")
    else:
        print("  [FAIL] test_plugin_structure.py EXPECTED_LIVE_SKILLS not found")
        success = False
else:
    print(f"  [FAIL] test_plugin_structure.py not found at {tests_path}")
    success = False

print("----")
if success:
    print("RESULT: PASS")
    sys.exit(0)
else:
    if write_mode:
        print("RESULT: FAIL (some files could not be updated)")
    else:
        print("RESULT: FAIL (out of sync — run with --write to regenerate)")
    sys.exit(1)
EOF
