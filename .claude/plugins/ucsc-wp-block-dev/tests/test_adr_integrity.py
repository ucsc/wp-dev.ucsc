"""ADR reference and implements: integrity checks for skills and scripts."""

import re
import subprocess
from pathlib import Path

PLUGIN_ROOT = Path(__file__).resolve().parent.parent
ADR_DIR = PLUGIN_ROOT / "docs" / "adr"
SKILLS_DIR = PLUGIN_ROOT / "skills"
CHECKER = SKILLS_DIR / "maintainer" / "scripts" / "check_adr_implements.py"

ACTIVE_STATUSES = {"Accepted", "Proposed"}
INACTIVE_STATUSES = {"Superseded", "Deprecated", "Rejected"}
ADR_REF_RE = re.compile(r"\bADR-(\d{3,})(?:-[A-Z0-9][A-Z0-9-]*)?\b")
OBSOLETE_SHORT_FORM_RE = re.compile(r"\bADR-\d{3,}(?:/\d{3,})+\b")


def adr_status(path: Path) -> str:
    text = path.read_text(errors="ignore")
    match = re.match(r"^---\n(.+?)\n---", text, re.DOTALL)
    if not match:
        return "Unknown"
    for line in match.group(1).splitlines():
        if line.strip().lower().startswith("status:"):
            return line.split(":", 1)[1].strip().strip("\"'")
    return "Unknown"


def adr_index() -> dict[str, list[tuple[Path, str]]]:
    index: dict[str, list[tuple[Path, str]]] = {}
    for path in sorted(ADR_DIR.glob("ADR-*.md")):
        match = re.match(r"ADR-(\d{3,})", path.name)
        if not match:
            continue
        index.setdefault(match.group(1), []).append((path, adr_status(path)))
    return index


def scanned_skill_files() -> list[Path]:
    return sorted(
        path
        for path in SKILLS_DIR.rglob("*")
        if path.is_file()
        and path.suffix in {".md", ".py", ".sh"}
        and "__pycache__" not in path.parts
    )


def test_skill_and_script_adr_references_resolve_to_active_adrs():
    index = adr_index()
    violations = []
    for path in scanned_skill_files():
        for line_no, line in enumerate(path.read_text(errors="ignore").splitlines(), 1):
            if OBSOLETE_SHORT_FORM_RE.search(line):
                location = f"{path.relative_to(PLUGIN_ROOT)}:{line_no}"
                violations.append(
                    f"{location}: obsolete ADR shorthand {OBSOLETE_SHORT_FORM_RE.search(line).group(0)}"
                )
            for match in ADR_REF_RE.finditer(line):
                number = match.group(1)
                entries = index.get(number, [])
                location = f"{path.relative_to(PLUGIN_ROOT)}:{line_no}"
                if not entries:
                    violations.append(f"{location}: {match.group(0)} has no ADR file")
                    continue
                if len(entries) > 1:
                    files = ", ".join(entry[0].name for entry in entries)
                    violations.append(
                        f"{location}: {match.group(0)} resolves ambiguously to {files}"
                    )
                    continue
                _adr_path, status = entries[0]
                if status in INACTIVE_STATUSES or status not in ACTIVE_STATUSES:
                    violations.append(
                        f"{location}: {match.group(0)} resolves to status {status}"
                    )

    assert not violations, "Stale ADR references:\n" + "\n".join(
        f"  {violation}" for violation in violations
    )


def test_implements_coverage_is_strict():
    result = subprocess.run(
        ["python3", str(CHECKER), "--strict"],
        capture_output=True,
        text=True,
        cwd=str(PLUGIN_ROOT),
        timeout=20,
    )
    assert result.returncode == 0, result.stdout + result.stderr
