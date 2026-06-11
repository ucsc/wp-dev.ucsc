"""Enforce ADR-032: every supporting file under a skill dir is referenced from its SKILL.md.

This shells out to the same scanner the maintainer `check-references` operation runs,
so the invariant is enforced in CI as well as by hand.
"""

import os
import subprocess
from pathlib import Path

PLUGIN_ROOT = Path(__file__).resolve().parent.parent
CHECKER = PLUGIN_ROOT / "skills" / "maintainer" / "scripts" / "check_skill_references.sh"


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
