"""Retired-ADR layout contract.

Retired (Superseded/Deprecated/Rejected) ADRs live under docs/adr/retired/ and are
catalogued one-per-line in docs/adr/adrs_retired.md; the active index.md carries
only active ADRs. These tests enforce that split.
"""

import re
from pathlib import Path

PLUGIN_ROOT = Path(__file__).resolve().parent.parent
ADR_DIR = PLUGIN_ROOT / "docs" / "adr"
RETIRED_DIR = ADR_DIR / "retired"
RETIRED_INDEX = ADR_DIR / "adrs_retired.md"
INACTIVE = {"Superseded", "Deprecated", "Rejected"}
ACTIVE = {"Accepted", "Proposed"}


def _status(path: Path) -> str:
    m = re.match(r"^---\n(.+?)\n---", path.read_text(), re.DOTALL)
    if not m:
        return "Unknown"
    for line in m.group(1).splitlines():
        if line.strip().lower().startswith("status:"):
            return line.split(":", 1)[1].strip().strip("\"'")
    return "Unknown"


def test_retired_index_exists():
    assert RETIRED_INDEX.exists(), "docs/adr/adrs_retired.md is missing"


def test_active_index_has_no_retired_adrs():
    """Top-level ADR files are all active, and index.md lists none that are retired."""
    text = RETIRED_INDEX.read_text() if RETIRED_INDEX.exists() else ""
    index_text = (ADR_DIR / "index.md").read_text()
    for path in sorted(ADR_DIR.glob("ADR-*.md")):
        status = _status(path)
        assert status in ACTIVE, (
            f"{path.name} is '{status}' but sits in the active ADR dir — "
            "move it to retired/ and list it in adrs_retired.md"
        )
    assert "(retired/" not in index_text, (
        "index.md links into retired/ — retired ADRs belong only in adrs_retired.md"
    )
    assert text  # adrs_retired.md must be non-empty


def test_retired_dir_holds_only_retired_adrs_all_catalogued():
    if not RETIRED_DIR.exists():
        return  # nothing retired yet is acceptable
    catalogue = RETIRED_INDEX.read_text()
    for path in sorted(RETIRED_DIR.glob("ADR-*.md")):
        status = _status(path)
        assert status in INACTIVE, (
            f"retired/{path.name} has active status '{status}' — it should not be retired"
        )
        assert path.name in catalogue, (
            f"retired/{path.name} is not listed in adrs_retired.md"
        )


def test_retired_catalogue_links_resolve():
    if not RETIRED_INDEX.exists():
        return
    for target in re.findall(r"\(retired/(ADR-[^)]+\.md)\)", RETIRED_INDEX.read_text()):
        assert (RETIRED_DIR / target).exists(), (
            f"adrs_retired.md links retired/{target} but that file does not exist"
        )
