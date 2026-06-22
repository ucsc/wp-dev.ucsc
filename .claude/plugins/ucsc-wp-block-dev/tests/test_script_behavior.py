"""Behavioral tests for maintainer helper scripts (beyond --help smoke tests).

These exercise the actual logic of the scripts, complementing the structural
checks in test_plugin_structure.py and the CLI-contract smoke tests in
test_script_cli_contracts.py.
"""

import os
import re
import subprocess
from pathlib import Path

PLUGIN_ROOT = Path(__file__).resolve().parent.parent
SCRIPTS = PLUGIN_ROOT / "skills" / "maintainer" / "scripts"


def _run_backlog(worklist: Path, cache_dir: Path) -> str:
    """Run backlog.py --print against an isolated worklist + cache, return stdout."""
    env = os.environ.copy()
    env["UCSC_WP_BLOCK_DEV_WORKLIST"] = str(worklist)
    env["UCSC_WP_BLOCK_DEV_CACHE"] = str(cache_dir)
    env["PYTHONDONTWRITEBYTECODE"] = "1"
    result = subprocess.run(
        ["python3", str(SCRIPTS / "backlog.py"), "--print"],
        capture_output=True,
        text=True,
        cwd=str(PLUGIN_ROOT),
        env=env,
        timeout=20,
    )
    assert result.returncode == 0, result.stdout + result.stderr
    return result.stdout


def _personal_section(stdout: str) -> str:
    """Extract the '## Personal backlog (from WORKLIST.md)' section body."""
    marker = "## Personal backlog (from WORKLIST.md)"
    assert marker in stdout, f"missing personal backlog section:\n{stdout}"
    return stdout.split(marker, 1)[1]


def test_backlog_personal_section_anchors_on_banner_not_inline_mention(tmp_path):
    """Regression: an inline 'STILL OPEN' reference in prose ABOVE the banner must
    not truncate the worklist mid-sentence (backlog.py personal_backlog).

    Reproduces the bug where text.find('STILL OPEN') matched a parenthetical
    '(see STILL OPEN)' instead of the real section banner, dropping the worklist
    header and wrongly swallowing the DONE-THIS-SESSION block.
    """
    worklist = tmp_path / "WORKLIST.md"
    worklist.write_text(
        "Personal work list — test\n"
        "Updated: 2026-01-01\n"
        "\n"
        "Standardize description style (see STILL OPEN).\n"  # inline lure, line-internal
        "\n"
        "DONE THIS SESSION\n"
        "- finished_marker_alpha\n"
        "\n"
        "STILL OPEN (next-session priorities)\n"
        "- open_marker_bravo\n"
    )

    section = _personal_section(_run_backlog(worklist, tmp_path / "cache"))

    # The section must start at the real banner, not the inline mention.
    assert "STILL OPEN (next-session priorities)" in section
    assert "open_marker_bravo" in section
    # Content BEFORE the banner must not leak into the personal backlog.
    assert "finished_marker_alpha" not in section, (
        "DONE-THIS-SESSION content leaked into the personal backlog — the inline "
        "'(see STILL OPEN)' mention truncated the worklist incorrectly"
    )
    assert "Standardize description style" not in section


def test_backlog_missing_worklist_is_reported_not_fatal(tmp_path):
    """A missing worklist degrades gracefully rather than crashing."""
    section = _personal_section(
        _run_backlog(tmp_path / "does_not_exist.md", tmp_path / "cache")
    )
    assert "not found" in section.lower()


def test_new_adr_filename_matches_structural_convention():
    """The new_adr.sh generator must emit the same 3-digit shape the structural
    test enforces — guards against generator/convention drift (e.g. %04d vs %03d).
    """
    script = (SCRIPTS / "new_adr.sh").read_text()
    width = re.search(r'printf "%0(\d)d"', script)
    assert width, "new_adr.sh no longer uses a zero-padded printf width"
    assert width.group(1) == "3", (
        f"new_adr.sh pads ADR numbers to {width.group(1)} digits, but the "
        "convention (test_adr_filenames_use_current_convention) expects 3"
    )
