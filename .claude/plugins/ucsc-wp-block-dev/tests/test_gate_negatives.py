"""Negative-path tests for the maintainer gate scripts.

The structural suite only runs check-skill-references.sh and
check-adr-implements.py against the real (clean) tree, which proves they PASS but
not that they actually FAIL on a violation — a checker hard-wired to return PASS
would sail through. These tests plant a violation in a hermetic fixture tree and
assert the gate bites, then confirm the clean variant passes.

Both scripts resolve their target directories from their own location, so each
fixture copies the script into a throwaway skills/maintainer/scripts/ path and
runs it there.
"""

import shutil
import subprocess
from pathlib import Path

PLUGIN_ROOT = Path(__file__).resolve().parent.parent
SCRIPTS = PLUGIN_ROOT / "skills" / "maintainer" / "scripts"
REF_CHECKER = SCRIPTS / "check-skill-references.sh"
ADR_CHECKER = SCRIPTS / "check-adr-implements.py"


def _install_checker(src: Path, fixture_root: Path) -> Path:
    """Copy a gate script into <fixture>/skills/maintainer/scripts/, stripping any
    `implements:` marker so the script's own ADR reference can't pollute the
    fixture's resolution. Returns the installed script path."""
    dst_dir = fixture_root / "skills" / "maintainer" / "scripts"
    dst_dir.mkdir(parents=True, exist_ok=True)
    dst = dst_dir / src.name
    lines = [
        line
        for line in src.read_text().splitlines(keepends=True)
        if not line.lstrip().startswith("# implements:")
    ]
    dst.write_text("".join(lines))
    return dst


def _skill(fixture_root: Path, name: str, body: str = "") -> Path:
    sdir = fixture_root / "skills" / name
    sdir.mkdir(parents=True, exist_ok=True)
    (sdir / "SKILL.md").write_text(
        f"---\nname: {name}\ndescription: demo skill\n---\n\n# {name}\n\n{body}\n"
    )
    return sdir


def _adr(fixture_root: Path, number: str, slug: str, status: str = "Accepted") -> Path:
    adr_dir = fixture_root / "docs" / "adr"
    adr_dir.mkdir(parents=True, exist_ok=True)
    path = adr_dir / f"ADR-{number}-{slug}.md"
    path.write_text(
        f'---\ntitle: "ADR-{number}: Demo"\nstatus: {status}\ndate: 2026-01-01\n---\n\n'
        f"# ADR-{number}: Demo\n"
    )
    return path


# --------------------------------------------------------------------------- #
# check-skill-references.sh
# --------------------------------------------------------------------------- #

def test_reference_gate_fails_on_unreferenced_support_file(tmp_path):
    checker = _install_checker(REF_CHECKER, tmp_path)
    sdir = _skill(tmp_path, "demo", body="See nothing here.")
    (sdir / "references").mkdir()
    (sdir / "references" / "orphan.md").write_text("unreferenced\n")

    result = subprocess.run(
        ["bash", str(checker), "--quiet"], capture_output=True, text=True, timeout=20
    )
    assert result.returncode == 1, f"gate did not fail:\n{result.stdout}{result.stderr}"
    assert "orphan.md" in result.stdout
    assert "FAIL" in result.stdout


def test_reference_gate_passes_when_support_file_is_referenced(tmp_path):
    checker = _install_checker(REF_CHECKER, tmp_path)
    sdir = _skill(tmp_path, "demo", body="See [orphan](references/orphan.md).")
    (sdir / "references").mkdir()
    (sdir / "references" / "orphan.md").write_text("now referenced\n")

    result = subprocess.run(
        ["bash", str(checker), "--quiet"], capture_output=True, text=True, timeout=20
    )
    assert result.returncode == 0, f"clean tree failed:\n{result.stdout}{result.stderr}"
    assert "PASS" in result.stdout


# --------------------------------------------------------------------------- #
# check-adr-implements.py
# --------------------------------------------------------------------------- #

def test_implements_gate_fails_on_missing_adr(tmp_path):
    checker = _install_checker(ADR_CHECKER, tmp_path)
    _adr(tmp_path, "001", "demo_mode_thing", status="Accepted")
    _skill(tmp_path, "demo", body="implements: ADR-999-DOES-NOT-EXIST")

    result = subprocess.run(
        ["python3", str(checker)], capture_output=True, text=True, timeout=20
    )
    assert result.returncode == 1, f"gate did not fail:\n{result.stdout}{result.stderr}"
    assert "ADR-999" in result.stdout
    assert "no ADR file" in result.stdout


def test_implements_gate_fails_on_inactive_adr(tmp_path):
    checker = _install_checker(ADR_CHECKER, tmp_path)
    _adr(tmp_path, "001", "demo_mode_thing", status="Superseded")
    _skill(tmp_path, "demo", body="implements: ADR-001-DEMO-MODE")

    result = subprocess.run(
        ["python3", str(checker)], capture_output=True, text=True, timeout=20
    )
    assert result.returncode == 1, f"gate did not fail:\n{result.stdout}{result.stderr}"
    assert "ADR-001" in result.stdout
    assert "not active" in result.stdout


def test_implements_gate_passes_on_active_resolved_reference(tmp_path):
    checker = _install_checker(ADR_CHECKER, tmp_path)
    _adr(tmp_path, "001", "demo_mode_thing", status="Accepted")
    _skill(tmp_path, "demo", body="implements: ADR-001-DEMO-MODE")

    # No --strict, so unimplemented-ADR forward coverage stays advisory.
    result = subprocess.run(
        ["python3", str(checker)], capture_output=True, text=True, timeout=20
    )
    assert result.returncode == 0, f"clean tree failed:\n{result.stdout}{result.stderr}"
    assert "RESULT: PASS" in result.stdout
