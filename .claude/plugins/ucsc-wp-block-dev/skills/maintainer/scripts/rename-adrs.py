#!/usr/bin/env python3
# implements: ADR-065-MAINTAINER-NEW-ADR, ADR-099-MAINTAINER-RETRO-MODE-ORCHESTRATION-WRAPPER-SCRIPTS
"""rename-adrs.py — Bulk rename ADR files and update their references.

Usage:
  python3 rename-adrs.py [--help]
"""

import sys
import os
import re
from pathlib import Path

PLUGIN_ROOT = Path(__file__).resolve().parents[3]
ADR_DIR = PLUGIN_ROOT / "docs" / "adr"
RETIRED_DIR = ADR_DIR / "retired"

# Every ADR must start with one of the 7 skill names:
# maintainer, develop, run, verify, validate, review, hub
ADR_CLASSIFICATION = {
    "001": "maintainer-ucsc-wp-block-dev-plugin-scope",
    "002": "maintainer-wp-dev-ucsc-local-environment",
    "003": "maintainer-low-token-use",
    "004": "maintainer-plugin-validation-workflow",
    "005": "maintainer-skill-frontmatter-convention",
    "006": "develop-block-development-examples",
    "007": "develop-fix-mode-requires-user-provided-problem",
    "008": "develop-prefer-jira-id-for-fix-and-develop",
    "009": "develop-fix-and-develop-require-target-and-description",
    "010": "develop-jira-prompt-may-repeat-at-phase-completion",
    "011": "maintainer-universal-command-intake",
    "012": "maintainer-setup-capability-summary",
    "013": "maintainer-readme-is-first-time-user-reference",
    "014": "maintainer-slide-deck-documents-all-skills",
    "015": "maintainer-slide-deck-generated-date",
    "016": "maintainer-avoid-bundling-python-in-plugin",
    "017": "maintainer-agents-uses-symlinks-not-copies",
    "018": "maintainer-owns-slide-deck",
    "019": "validate-emits-conventional-commit-checkin-text",
    "020": "maintainer-prompts-for-operation",
    "021": "maintainer-accept-jira-id-or-url-in-arguments",
    "022": "maintainer-accept-github-and-bitbucket-pr-references",
    "023": "maintainer-always-favor-conventional-commits",
    "024": "develop-block-target-registry",
    "025": "maintainer-suggest-atlassian-mcp-for-atlassian-references",
    "026": "develop-fix-mode-token-reduction",
    "027": "maintainer-study-github-atlassian-mcp-token-cost",
    "028": "maintainer-start-mcp-just-in-time-when-token-efficient",
    "029": "develop-fix-and-develop-offer-conventional-commit-message",
    "030": "maintainer-separate-run-verify-test-and-plugin-validation",
    "031": "validate-test-clarifies-type-and-operation",
    "032": "maintainer-skill-support-files-referenced-from-skill-md",
    "033": "maintainer-work-list-state-in-claude-config-dir",
    "034": "maintainer-defer-github-atlassian-mcp-login-until-needed",
    "035": "maintainer-warn-on-preexisting-uncommitted-code-once",
    "036": "develop-separate-fix-and-feature-workflows",
    "037": "maintainer-wrap-anthropic-skills-with-context-and-guardrails",
    "038": "maintainer-skill-mode-contributed-skill-incubation",
    "039": "maintainer-skills-first-map-entry-point",
    "040": "develop-shared-issue-context-reference",
    "041": "develop-block-targets-are-develop-references",
    "042": "validate-test-operations-are-references",
    "043": "maintainer-documentation-skill-generates-markdown-artifacts",
    "044": "develop-domain-guidance-is-a-develop-reference",
    "045": "maintainer-generate-docs-mode-documentation-reference",
    "046": "maintainer-is-a-hidden-manual-skill",
    "047": "develop-warn-before-editing-on-non-feature-branches",
    "048": "maintainer-generate-docs-mode-uses-adrs-and-roadmap",
    "049": "maintainer-retro-mode-perform-retrospective-after-tasks",
    "050": "maintainer-no-local-php-python-dependency",
    "051": "maintainer-offer-automatic-commit",
    "052": "maintainer-allow-co-authored-by-ai",
    "053": "maintainer-tag-commits-with-skillset",
    "054": "maintainer-offer-to-create-pull-requests",
    "055": "maintainer-do-not-push-without-checking",
    "056": "maintainer-github-only-operations",
    "057": "maintainer-do-not-inspect-parent-git-repos",
    "058": "maintainer-optimize-for-low-token-use",
    "059": "maintainer-retro-mode-offer-retrospective",
    "060": "hub-support-hub-to-list-skills",
    "061": "maintainer-remove-map-rely-on-native-discovery",
    "062": "maintainer-github-operations-tool-fallbacks",
    "063": "maintainer-publish-mode-unified-operation",
    "064": "maintainer-agent-backed-checks-are-opt-in",
    "065": "maintainer-adr-mode-new-adr-script",
    "066": "validate-test-driver",
    "067": "maintainer-skill-mode-sync-inventory",
    "068": "maintainer-shared-scripts-and-skills",
    "069": "maintainer-full-paths-for-generated-files",
    "070": "maintainer-align-frontmatter-allowlist-with-official-skills-spec",
    "071": "maintainer-skill-mode-details-developer-view",
    "072": "maintainer-skill-display-format",
    "073": "maintainer-use-claude-for-plugin-operations",
    "074": "verify-verify-skill-block-coverage-scope",
    "075": "maintainer-prefer-single-agent-mode",
    "076": "maintainer-token-burn-log",
    "077": "maintainer-lessons-learned-to-scripts-and-skills",
    "078": "maintainer-validate-mode-cli-validate-as-primary-check",
    "079": "maintainer-plugin-dev-companion-plugin",
    "080": "maintainer-agents-md-skill-inventory",
    "081": "maintainer-sub-skill-directories-under-skill",
    "082": "develop-survey-mode-move-survey-under-develop",
    "083": "maintainer-retro-mode-move-retrospective-under-maintainer",
    "084": "develop-select-block-target-workflow",
    "085": "maintainer-target-plugin",
    "086": "maintainer-conventions",
    "087": "validate-rename-test-skill-to-validate",
    "088": "maintainer-skill-modes-in-public-menu",
    "089": "maintainer-public-slash",
    "090": "develop-fix-mode-infer-block-target-from-cwd",
    "091": "run-run-target-identify-the-run-target-before-invoking-the-driver",
    "092": "maintainer-shell-safety",
    "093": "develop-session-block-target",
    "094": "develop-scripts-expand-harness-path-variables-when-issuing-script-commands-to-claude",
    "095": "develop-source-base-resolve-a-source-base-and-use-reusable-inspection-scripts-instead-of-hardcoded-paths-and-ad-hoc-find",
    "096": "maintainer-sanity-check-plugin-matches-codebase-stack",
    "097": "run-drive-captures-console-errors-screenshot-opt-in",
    "098": "maintainer-adr-mode-naming-convention"
}

def get_adr_files():
    files = []
    # Active ADRs
    for p in ADR_DIR.glob("ADR-*.md"):
        files.append((p, False))
    # Retired ADRs
    if RETIRED_DIR.exists():
        for p in RETIRED_DIR.glob("ADR-*.md"):
            files.append((p, True))
    return files

def print_help():
    print(__doc__.strip())

def main():
    if len(sys.argv) > 1 and sys.argv[1] in ("--help", "-h"):
        print_help()
        return 0

    adr_files = get_adr_files()
    rename_map = {}
    
    # First, build rename map and perform renaming
    for path, is_retired in adr_files:
        filename = path.name
        # Match number
        m = re.match(r"^ADR-(\d{3,})", filename)
        if not m:
            continue
        num = m.group(1)
        if num in ADR_CLASSIFICATION:
            new_name = f"ADR-{num}-{ADR_CLASSIFICATION[num]}.md"
        else:
            # Fallback (replace underscores with hyphens)
            new_name = filename.replace("_", "-")
            
        rename_map[filename] = new_name
        
        target_dir = RETIRED_DIR if is_retired else ADR_DIR
        new_path = target_dir / new_name
        if path != new_path:
            print(f"Renaming {path.relative_to(PLUGIN_ROOT)} -> {new_name}")
            path.rename(new_path)
            
    # Now, find and replace old names with new names in all files under PLUGIN_ROOT
    for root, dirs, files in os.walk(str(PLUGIN_ROOT)):
        # Skip git, pytest cache, etc.
        dirs[:] = [d for d in dirs if d not in (".git", ".pytest_cache", "__pycache__", "node_modules")]
        for file in files:
            file_path = Path(root) / file
            if file_path.suffix not in (".md", ".py", ".sh", ".json", ".txt"):
                continue
            try:
                content = file_path.read_text(encoding="utf-8", errors="ignore")
            except Exception:
                continue
                
            replaced = False
            new_content = content
            
            # Match current filenames (underscore or previous hyphenated ones) to the new name
            for old_name, new_name in rename_map.items():
                # Replace with extension
                if old_name in new_content:
                    new_content = new_content.replace(old_name, new_name)
                    replaced = True
                # Construct historical underscore name to replace if it exists
                old_under = old_name.replace("-", "_")
                if old_under in new_content:
                    new_content = new_content.replace(old_under, new_name)
                    replaced = True
                
                # Also do without extension
                old_stem = Path(old_name).stem
                new_stem = Path(new_name).stem
                if old_stem in new_content:
                    new_content = new_content.replace(old_stem, new_stem)
                    replaced = True
                old_under_stem = old_stem.replace("-", "_")
                if old_under_stem in new_content:
                    new_content = new_content.replace(old_under_stem, new_stem)
                    replaced = True
                    
            if replaced:
                print(f"Updating references in {file_path.relative_to(PLUGIN_ROOT)}")
                file_path.write_text(new_content, encoding="utf-8")
    return 0

if __name__ == "__main__":
    sys.exit(main())
