"""Enforce ADR-032: every supporting file under a skill dir is referenced from its SKILL.md.

This shells out to the same scanner the maintainer `check-references` operation runs,
so the invariant is enforced in CI as well as by hand.

Also enforces the AgentSkills spec rule: file references must be one level deep from
SKILL.md — i.e. no file may live more than one directory below a skill root.
"""

import os
import subprocess
from pathlib import Path

PLUGIN_ROOT = Path(__file__).resolve().parent.parent
CHECKER = PLUGIN_ROOT / "skills" / "maintainer" / "scripts" / "check_skill_references.sh"
SKILLS_DIR = PLUGIN_ROOT / "skills"


def test_checker_exists_and_executable():
    assert CHECKER.exists(), f"reference checker missing at {CHECKER}"
    assert os.access(CHECKER, os.X_OK), "check_skill_references.sh is not executable"


def test_all_skill_support_files_referenced():
    result = subprocess.run(
        ["bash", str(CHECKER)],
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, (
        "Unreferenced skill support files (ADR-032):\n" + result.stdout + result.stderr
    )


def test_all_skill_scripts_are_executable_with_shebang():
    """Every file under skills/*/scripts/ must be executable and start with a shebang."""
    violations = []
    for skill_dir in sorted(SKILLS_DIR.iterdir()):
        if not skill_dir.is_dir() or skill_dir.name.startswith("."):
            continue
        scripts_dir = skill_dir / "scripts"
        if not scripts_dir.exists():
            continue
        for script in sorted(scripts_dir.iterdir()):
            if not script.is_file():
                continue
            if not os.access(script, os.X_OK):
                violations.append(f"{script.relative_to(SKILLS_DIR)}: not executable")
            first_line = script.read_text(errors="ignore").splitlines()[:1]
            if not first_line or not first_line[0].startswith("#!"):
                violations.append(f"{script.relative_to(SKILLS_DIR)}: missing shebang (#!)")
    assert not violations, (
        "Script violations:\n" + "\n".join(f"  {v}" for v in violations)
    )


def test_no_deeply_nested_skill_support_files():
    """AgentSkills spec: keep file references one level deep from SKILL.md.

    Files at skill_root/subdir/file.md are fine (depth 1).
    Files at skill_root/subdir/nested/file.md are not (depth 2+).
    __pycache__ directories are excluded.
    """
    violations = []
    for skill_dir in sorted(SKILLS_DIR.iterdir()):
        if not skill_dir.is_dir() or skill_dir.name.startswith("."):
            continue
        skill_root = skill_dir
        for f in skill_root.rglob("*"):
            if not f.is_file():
                continue
            if any(part == "__pycache__" for part in f.parts):
                continue
            # Depth relative to skill root: SKILL.md is depth 0, subdir/file is depth 1
            relative = f.relative_to(skill_root)
            if len(relative.parts) > 2:  # depth 2+ means subdir/nested/file
                violations.append(str(relative) + f"  (in skill: {skill_dir.name})")
    assert not violations, (
        "AgentSkills spec violation — files more than one level deep under skill root:\n"
        + "\n".join(f"  {v}" for v in violations)
    )
