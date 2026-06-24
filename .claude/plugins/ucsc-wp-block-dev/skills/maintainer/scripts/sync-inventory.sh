#!/bin/bash
# sync-inventory.sh — enforces inventory consistency by treating skills/*/ as the
# source of truth and checking (or updating) the README, root AGENTS.md, hub
# listing, slide deck presentation table, and the python test suite skill
# expectations.
#
# Usage:
#   bash sync-inventory.sh [--check]    # Dry-run check for drift (default)
#   bash sync-inventory.sh --write      # Update the inventory lists in all files
#
# Exit code 0 if matching/updated, 1 if out of sync.

set -uo pipefail

usage() {
  sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'
}

case "${1:-}" in
  --help|-h)
    usage
    exit 0
    ;;
esac

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
PROJECT_ROOT = os.path.abspath(os.path.join(PLUGIN_DIR, "..", "..", ".."))
skills_dir = os.path.abspath(os.path.join(SCRIPT_DIR, "..", ".."))

# Parse arguments
write_mode = "--write" in sys.argv

# Define canonical metadata for all existing/known skills to match desired table layouts.
# If a new skill is added, it will fall back to using its frontmatter description.
METADATA = {
    "develop": {
        "readme": "Add or modify block code directly",
        "hub": "Add or modify block code (PHP, template, JS editor, REST, build).",
        "agents_md": "Add or modify block code (PHP, template, JS editor, REST, build).",
        "deck_trigger": "Block code changes, new behavior, or bug repair",
        "deck_desc": "Adds or modifies PHP class, template, JS editor, REST, and build steps."
    },
    "develop feature": {
        "readme": "Mode of `develop` for defining and implementing new behavior",
        "hub": "Define and implement new behavior: a new block, editor control, or frontend output.",
        "agents_md": "Defining and implementing new behavior",
        "deck_trigger": "New behavior",
        "deck_desc": "Defines requirements and implements a feature, editor enhancement, or new block."
    },
    "develop fix": {
        "readme": "Mode of `develop` for reproducing and repairing defects",
        "hub": "Reproduce and repair a described defect in a specified target.",
        "agents_md": "Reproducing and repairing defects",
        "deck_trigger": "Bug repair",
        "deck_desc": "Reproduces, diagnoses, and repairs a described block defect."
    },
    "feedback": {
        "readme": "Report a bug or suggestion about the plugin's skills (the `/bug` analog)",
        "hub": "Report a bug or suggestion about the plugin's skills (the `/bug` analog); delivers to a configured endpoint/email or saves a local copy.",
        "agents_md": "Report a bug or suggestion about the plugin's own skills. Collects a note plus session context and delivers it to a configured endpoint/email or saves locally; not for the WordPress feedback block.",
        "deck_trigger": '"Submit feedback" / report a bug about a skill',
        "deck_desc": "Collects a feedback note plus session context and delivers it to a configured endpoint/email (else saves locally)."
    },
    "hub": {
        "readme": "List every available skill and command (`:hub`) — enumeration only",
        "hub": None,  # Hub is not listed in its own public workflows table
        "agents_md": "List all available skills and commands. Use when unsure which skill applies.",
        "deck_trigger": '"List the skills" (`:hub`)',
        "deck_desc": "Enumerates the available skills and commands; does not route (ADR-060)."
    },
    "maintainer": {
        "readme": "Maintain this plugin for validation, skill upkeep, ADRs, docs, and release readiness",
        "hub": "Maintain the plugin itself for validation, skill upkeep, ADRs, docs, and release readiness.",
        "agents_md": "Maintain the plugin itself. Invoke as `/ucsc-wp-block-dev:maintainer` for validation, skill upkeep, ADRs, docs, and release readiness; sub-workflow `maintainer/retrospective` captures session lessons.",
        "deck_trigger": "Plugin maintenance",
        "deck_desc": "User-invocable as `/ucsc-wp-block-dev:maintainer`; validates and improves the plugin, skills, ADRs, docs, and release readiness."
    },
    "review": {
        "readme": "Review a diff, branch, file, block, or Jira-scoped change",
        "hub": "Review a diff, branch, file, PR, or Jira-scoped change for bugs, regressions, security, a11y, and missing tests.",
        "agents_md": "Review a diff, branch, file, PR, or Jira-scoped change for bugs, regressions, security, a11y, and missing tests.",
        "deck_trigger": "Review request",
        "deck_desc": "Reviews a diff, branch, file, or Jira-scoped change."
    },
    "run": {
        "readme": "Launch and drive wp-dev.ucsc to see a change working",
        "hub": "Launch and drive the app to see a change working.",
        "agents_md": "Launch and drive the plugin in wp-dev.ucsc to see a change working.",
        "deck_trigger": "Run request",
        "deck_desc": "Launches and drives wp-dev.ucsc to see a change working."
    },
    "validate": {
        "readme": "Create or run automated PHP, Jest, or e2e tests",
        "hub": "Create or run automated PHP, Jest, or e2e tests.",
        "agents_md": "Create or run automated PHP, Jest, or e2e tests.",
        "deck_trigger": "Validation / test creation or execution",
        "deck_desc": "Creates or runs PHP, Jest, or end-to-end tests."
    },
    "validate php": {
        "readme": "Mode of `validate` for PHP tests",
        "hub": "Render callbacks, sanitization, REST routes, and transient/cache behavior.",
        "agents_md": "Create or run PHP tests.",
        "deck_trigger": "PHP test request",
        "deck_desc": "Creates or runs PHP tests."
    },
    "validate jest": {
        "readme": "Mode of `validate` for Jest tests",
        "hub": "Block registration, attributes, editor controls, and client behavior.",
        "agents_md": "Create or run Jest tests.",
        "deck_trigger": "Jest test request",
        "deck_desc": "Creates or runs JavaScript tests."
    },
    "validate e2e": {
        "readme": "Mode of `validate` for end-to-end tests",
        "hub": "Editor insertion and frontend rendering driven through a real browser.",
        "agents_md": "Create or run end-to-end tests.",
        "deck_trigger": "Browser test request",
        "deck_desc": "Creates or runs end-to-end tests."
    },
    "validate all": {
        "readme": "Mode of `validate` for the full sequential battery (PHP -> Jest -> E2E)",
        "hub": "Run every suite sequentially (PHP -> Jest -> E2E) in one agent (ADR-101).",
        "agents_md": "Run all test suites sequentially in one battery, single-agent.",
        "deck_trigger": "Full-suite validation",
        "deck_desc": "Runs PHP, Jest, and end-to-end suites sequentially in a single agent."
    },
    "verify": {
        "readme": "Build and run the app to confirm a specific change without substituting tests or type checks",
        "hub": "Build and run the app to confirm a specific change without substituting tests or type checks.",
        "agents_md": "Build and run the app to confirm a specific change in the editor or frontend without substituting tests.",
        "deck_trigger": "Change verification",
        "deck_desc": "Builds/runs the app and confirms a specific change without substituting tests."
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


def get_argument_hint(skill_md_path):
    try:
        content = open(skill_md_path).read()
        m = re.search(r'^argument-hint:\s*["\']?(.+?)["\']?\s*$', content, re.MULTILINE)
        if m:
            return m.group(1).replace("|", "\\|")
    except Exception:
        pass
    return "—"


MODE_HINTS = {
    "develop feature": "[block] [feature description] [Jira or GitHub URL/ID]",
    "develop fix": "[block] [problem description] [Jira or GitHub URL/ID]",
    "validate php": "[create|run] [block|feature|Jira]",
    "validate jest": "[create|run] [block|feature|Jira]",
    "validate e2e": "[create|run] [block|feature|Jira]",
    "validate all": "[block]",
}

# Get list of live skills on disk (directories containing SKILL.md)
live_skills = []
for d in sorted(os.listdir(skills_dir)):
    if os.path.isdir(os.path.join(skills_dir, d)) and os.path.exists(os.path.join(skills_dir, d, "SKILL.md")):
        live_skills.append(d)

print(f"Syncing skills: {', '.join(live_skills)}")

# Modes are grouped inside their parent skill's table cell (on new lines) rather
# than as separate peer rows.
MODES = {
    "develop": ["develop feature", "develop fix"],
    "validate": ["validate php", "validate jest", "validate e2e", "validate all"],
}


def fold_modes(skill, key):
    """Return a '<br>- `mode` - desc' suffix listing a skill's modes inside its
    parent cell, or '' when the skill has no modes (or no text for this table)."""
    out = ""
    for mode in MODES.get(skill, []):
        desc = METADATA.get(mode, {}).get(key)
        if not desc:
            continue
        desc = re.sub(r"^Mode of `[^`]+` for ", "", desc).rstrip(".")
        out += f"<br>- `{mode}` - {desc}"
    return out


success = True

# 1. Sync README.md
readme_path = os.path.join(PLUGIN_DIR, "README.md")
if os.path.exists(readme_path):
    readme_content = open(readme_path).read()
    
    # Generate README table
    lines = [
        "| Skill or mode | Purpose |",
        "|---|---|"
    ]
    for s in live_skills:
        if s in ["retrospective"]:
            continue
        desc = METADATA.get(s, {}).get("readme") or get_skill_description(s, os.path.join(skills_dir, s, "SKILL.md"))
        desc += fold_modes(s, "readme")
        lines.append(f"| `{s}` | {desc} |")
    
    pattern = r"(\| Skill or mode \| Purpose \|\s*\n\|---\|---\|\s*\n)(.*?)(?=\n\n|\n[^|]|\Z)"
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

# 2. Sync root AGENTS.md
agents_path = os.path.join(PROJECT_ROOT, "AGENTS.md")
if os.path.exists(agents_path):
    agents_content = open(agents_path).read()

    lines = [
        "| Skill | Use for |",
        "| --- | --- |"
    ]
    for s in live_skills:
        desc = METADATA.get(s, {}).get("agents_md") or get_skill_description(s, os.path.join(skills_dir, s, "SKILL.md"))
        desc += fold_modes(s, "agents_md")
        lines.append(f"| `{s}` | {desc} |")

    pattern = r"(\| Skill \| Use for \|\s*\n\| --- \| --- \|\s*\n)(.*?)(?=\n\n|\n[^|]|\Z)"
    match = re.search(pattern, agents_content, re.DOTALL)
    if match:
        current_body = match.group(2).strip()
        expected_body = "\n".join(lines[2:]).strip()
        if current_body != expected_body:
            if write_mode:
                new_table = match.group(1) + expected_body
                new_content = agents_content[:match.start()] + new_table + agents_content[match.end():]
                with open(agents_path, "w") as f:
                    f.write(new_content)
                print("  [ OK ] AGENTS.md skill routing table updated")
            else:
                print("  [FAIL] AGENTS.md skill routing table is out of sync")
                success = False
        else:
            print("  [ OK ] AGENTS.md skill routing table is in sync")
    else:
        print("  [FAIL] AGENTS.md: skill routing table not found")
        success = False
else:
    print(f"  [FAIL] AGENTS.md not found at {agents_path}")
    success = False

# 3. Sync skills/hub/SKILL.md
hub_path = os.path.join(skills_dir, "hub", "SKILL.md")
if os.path.exists(hub_path):
    hub_content = open(hub_path).read()
    
    # Public workflows — a nested list (ADR-088): each skill on its own line with
    # its argument hint and purpose; its modes indented beneath it. This is a
    # list, not a table, so pipes inside the `code spans` are not escaped.
    list_lines = []
    for s in live_skills:
        if s in ["hub", "maintainer", "retrospective"]:
            continue
        desc = METADATA.get(s, {}).get("hub") or get_skill_description(s, os.path.join(skills_dir, s, "SKILL.md"))
        if not desc:
            continue
        hint = get_argument_hint(os.path.join(skills_dir, s, "SKILL.md")).replace("\\|", "|")
        list_lines.append(f"- **`{s}`** — `{hint}` — {desc}")
        for mode in MODES.get(s, []):
            mode_desc = METADATA.get(mode, {}).get("hub")
            if not mode_desc:
                continue
            mode_desc = re.sub(r"^Mode of `[^`]+` for ", "", mode_desc).rstrip(".")
            mode_label = mode.split()[-1]
            mode_hint = MODE_HINTS.get(mode, "—")
            list_lines.append(f"  - **`{mode_label}`** — `{mode_hint}` — {mode_desc}.")

    pattern_pub = r"(## Public workflows\s*\n\nEach skill is listed with its argument hint and purpose; a skill's modes are\nindented beneath it\.\n\n)(.*?)(?=\n\n)"
    match_pub = re.search(pattern_pub, hub_content, re.DOTALL)

    pub_ok = False
    if match_pub:
        current_pub = match_pub.group(2).strip()
        expected_pub = "\n".join(list_lines).strip()
        pub_ok = current_pub == expected_pub
        
    if pub_ok:
        print("  [ OK ] skills/hub/SKILL.md is in sync")
    else:
        if write_mode:
            new_content = hub_content
            if match_pub:
                new_pub = match_pub.group(1) + expected_pub
                new_content = new_content[:match_pub.start()] + new_pub + new_content[match_pub.end():]
            with open(hub_path, "w") as f:
                f.write(new_content)
            print("  [ OK ] skills/hub/SKILL.md updated")
        else:
            if not pub_ok:
                print("  [FAIL] skills/hub/SKILL.md public workflows table is out of sync")
            success = False
else:
    print(f"  [FAIL] skills/hub/SKILL.md not found")
    success = False

# 4. Sync Presentation Deck
deck_path = os.path.join(skills_dir, "maintainer", "assets", "ucsc-wp-block-dev-presentation.md")
if os.path.exists(deck_path):
    deck_content = open(deck_path).read()
    
    lines = [
        "| Skill or mode | Trigger | Purpose |",
        "| :--- | :--- | :--- |"
    ]
    for s in live_skills:
        if s in ["retrospective"]:
            continue
        trigger = METADATA.get(s, {}).get("deck_trigger") or f'"{s}"'
        desc = METADATA.get(s, {}).get("deck_desc") or get_skill_description(s, os.path.join(skills_dir, s, "SKILL.md"))
        if desc:
            lines.append(f"| **`{s}`** | {trigger} | {desc} |")
        if s == "develop":
            for mode in ["develop feature", "develop fix"]:
                lines.append(f"| **`{mode}`** | {METADATA[mode]['deck_trigger']} | {METADATA[mode]['deck_desc']} |")
        if s == "validate":
            for mode in ["validate php", "validate jest", "validate e2e", "validate all"]:
                lines.append(f"| **`{mode}`** | {METADATA[mode]['deck_trigger']} | {METADATA[mode]['deck_desc']} |")
        
    pattern = r"(\| Skill or mode \| Trigger \| Purpose \|\s*\n\| :---\ \| :---\ \| :---\ \|\s*\n)(.*?)(?=\n\n|\n[^|]|\Z)"
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

# 5. Sync tests/test_plugin_structure.py
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
