#!/usr/bin/env python3
# implements: ADR-085-MAINTAINER-TARGET
"""backlog.py — maintainer `backlog` mode (ADR-085).

Generates a combined, on-the-fly backlog for ucsc-wp-block-dev by merging:

  1. The personal backlog (WORKLIST.md), kept in the user's personal ~/.claude
     folder, NOT in the repo.
  2. Active ADRs not yet implemented by any skill or script — the forward-coverage
     gap from the `implements:` markers (see check_adr_implements.py). This list
     is computed fresh on every run.

The merged result is written to a CACHE file that is NOT checked in (an ephemeral
cache dir outside the plugin tree), and a short summary is printed to stdout.

Locations (override via env):
  Personal worklist : $UCSC_WP_BLOCK_DEV_WORKLIST
                      (default ~/.claude/ucsc-wp-block-dev/WORKLIST.md)
  Generated cache   : $UCSC_WP_BLOCK_DEV_CACHE/backlog.md
                      (default ~/.cache/ucsc-wp-block-dev/backlog.md)

Usage:
  python3 backlog.py            # generate + cache + print summary
  python3 backlog.py --print    # also echo the full combined backlog to stdout
"""

import os
import re
import sys
from datetime import date
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))
import check_adr_implements as cai  # noqa: E402  (sibling script, reuse its logic)


def _home_subdir(env_var: str, default_under_home: str) -> Path:
    override = os.environ.get(env_var)
    if override:
        return Path(override).expanduser()
    return Path.home() / default_under_home


WORKLIST = _home_subdir(
    "UCSC_WP_BLOCK_DEV_WORKLIST", ".claude/ucsc-wp-block-dev/WORKLIST.md"
)
CACHE_DIR = Path(
    os.environ.get("UCSC_WP_BLOCK_DEV_CACHE")
    or (Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "ucsc-wp-block-dev")
).expanduser()
OUT = CACHE_DIR / "backlog.md"


def adr_title(path: Path) -> str:
    text = path.read_text(errors="ignore")
    m = re.match(r"^---\n(.+?)\n---", text, re.DOTALL)
    if m:
        for line in m.group(1).splitlines():
            if line.strip().lower().startswith("title:"):
                title = line.split(":", 1)[1].strip().strip("\"'")
                # The title field already begins with "ADR-NNN:"; drop it so the
                # caller can apply a single, consistent prefix.
                return re.sub(r"^ADR-\d+:\s*", "", title)
    return path.stem


def unimplemented_adrs():
    """Active ADRs with no `implements:` marker, as (number, title) tuples."""
    adr_index = cai.build_adr_index()
    refs = cai.collect_implements()
    return [
        (num, adr_title(path))
        for num, (path, _status, active) in sorted(adr_index.items())
        if active and num not in refs
    ]


def personal_backlog() -> str:
    if not WORKLIST.exists():
        return f"(personal worklist not found at {WORKLIST})"
    text = WORKLIST.read_text(errors="ignore")
    # Capture from the "STILL OPEN" banner through the end, dropping a trailing
    # "Notes" footer if present. Falls back to the whole file.
    start = text.find("STILL OPEN")
    tail = text[start:] if start != -1 else text
    notes = tail.rfind("\nNotes\n")
    if notes != -1:
        tail = tail[:notes]
    return tail.strip()


def main() -> int:
    show = "--print" in sys.argv
    adrs = unimplemented_adrs()
    personal = personal_backlog()

    lines = [
        "# ucsc-wp-block-dev — combined backlog (generated)",
        "",
        f"Generated: {date.today().isoformat()} by maintainer `backlog` mode (ADR-085).",
        "Ephemeral cache file — NOT checked in. Regenerate any time; do not edit by hand.",
        f"Sources: {WORKLIST} + unimplemented active ADRs.",
        "",
        f"## Unimplemented active ADRs (no implements: marker): {len(adrs)}",
        "",
    ]
    if adrs:
        lines += [f"- ADR-{num}: {title}" for num, title in adrs]
    else:
        lines.append("- (none — every active ADR is implemented)")
    lines += [
        "",
        "## Personal backlog (from WORKLIST.md)",
        "",
        personal,
        "",
    ]
    content = "\n".join(lines)

    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    OUT.write_text(content)

    print(f"Combined backlog written to: {OUT}")
    print(f"  unimplemented active ADRs: {len(adrs)}")
    print(f"  personal worklist:         {WORKLIST}"
          f"{'' if WORKLIST.exists() else '  (MISSING)'}")
    if show:
        print("----")
        print(content)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
