#!/usr/bin/env python3
# implements: ADR-086-MAINTAINER-CONVENTIONS
"""check-adr-implements.py — ADR <-> implements: consistency checker (ADR-086).

Two checks:

  1. Reverse (hard gate): every ADR referenced by an `implements:` marker in a
     SKILL.md, .py, or .sh file must resolve to an existing, ACTIVE ADR
     (status Accepted or Proposed; not Superseded/Deprecated/Rejected).
     Any violation exits non-zero.

  2. Forward (coverage, advisory): every *Accepted* ADR should be implemented by
     at least one skill or script. Uncovered Accepted ADRs are reported as
     warnings. With --strict, uncovered ADRs also fail the run (intended once the
     per-skill rollout completes). `Proposed` ADRs are exempt — a proposal is a
     forward-looking idea that is intentionally not yet implemented, so it is a
     valid `implements:` target (reverse check) but is not required to have one.

`implements:` markers:
  - In SKILL.md (and other .md): a body line `implements: ADR-086-FOO, ADR-089-BAR`.
  - In .py / .sh: a comment line `# implements: ADR-086-FOO, ADR-089-BAR`.

The human-readable slug is `ADR-NNN-SKILL-MODE`; only the leading ADR number is
used to resolve the ADR file. Files and references use the three-digit
`ADR-NNN-` convention; the matcher accepts any 3+ digit leading number.

Usage:
  python3 check-adr-implements.py [--strict]

Exit 0 when all hard checks pass, 1 otherwise.
"""

import argparse
import re
import sys
from pathlib import Path

PLUGIN_ROOT = Path(__file__).resolve().parents[3]
ADR_DIR = PLUGIN_ROOT / "docs" / "adr"
SKILLS_DIR = PLUGIN_ROOT / "skills"

ACTIVE_STATUSES = {"Accepted", "Proposed"}
# Forward-coverage applies only to decisions that are meant to be implemented.
# A `Proposed` ADR is a forward-looking idea, intentionally not yet implemented.
IMPLEMENTED_STATUSES = {"Accepted"}
ADR_KEY_RE = re.compile(r"ADR-(\d{3,})")
IMPLEMENTS_MD_RE = re.compile(r"^\s*implements:\s*(.+)$", re.IGNORECASE)
IMPLEMENTS_CODE_RE = re.compile(r"^\s*#\s*implements:\s*(.+)$", re.IGNORECASE)


def adr_status(path: Path) -> str:
    text = path.read_text(errors="ignore")
    m = re.match(r"^---\n(.+?)\n---", text, re.DOTALL)
    if not m:
        return "Unknown"
    for line in m.group(1).splitlines():
        if line.strip().lower().startswith("status:"):
            return line.split(":", 1)[1].strip().strip("\"'")
    return "Unknown"


def build_adr_index() -> dict:
    """Map ADR number (zero-padded str) -> (path, status, active)."""
    index = {}
    for path in sorted(ADR_DIR.glob("ADR-*.md")):
        m = ADR_KEY_RE.match(path.name)
        if not m:
            continue
        num = m.group(1)
        status = adr_status(path)
        index[num] = (path, status, status in ACTIVE_STATUSES)
    return index


def collect_implements() -> dict:
    """Map ADR number -> list of files declaring implements: of it."""
    refs: dict = {}
    targets = list(SKILLS_DIR.rglob("SKILL.md"))
    targets += [p for p in SKILLS_DIR.rglob("*.py") if "__pycache__" not in p.parts]
    targets += list(SKILLS_DIR.rglob("*.sh"))
    for path in targets:
        pattern = IMPLEMENTS_CODE_RE if path.suffix in (".py", ".sh") else IMPLEMENTS_MD_RE
        for line in path.read_text(errors="ignore").splitlines():
            m = pattern.match(line)
            if not m:
                continue
            for num in ADR_KEY_RE.findall(m.group(1)):
                refs.setdefault(num, []).append(path.relative_to(PLUGIN_ROOT))
    return refs


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Check that implements: ADR references resolve to active ADRs.",
    )
    parser.add_argument(
        "--strict",
        action="store_true",
        help="Fail when any active ADR has no implements: marker.",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    strict = args.strict
    adr_index = build_adr_index()
    refs = collect_implements()

    print(f"ADRs on disk: {len(adr_index)}   ADRs referenced via implements: {len(refs)}")

    # Check 1 — reverse (hard gate)
    reverse_violations = []
    for num, files in sorted(refs.items()):
        entry = adr_index.get(num)
        flist = ", ".join(str(f) for f in files)
        if entry is None:
            reverse_violations.append(f"ADR-{num} referenced by {flist} but no ADR file exists")
        elif not entry[2]:
            reverse_violations.append(
                f"ADR-{num} referenced by {flist} is '{entry[1]}' (not active)"
            )

    # Check 2 — forward (coverage, advisory unless --strict).
    # Only Accepted ADRs must be implemented; Proposed (forward-looking) ADRs are exempt.
    uncovered = sorted(num for num, (_p, status, _active) in adr_index.items()
                       if status in IMPLEMENTED_STATUSES and num not in refs)

    print("----")
    if reverse_violations:
        print(f"[FAIL] reverse check — {len(reverse_violations)} stale/missing reference(s):")
        for v in reverse_violations:
            print(f"   - {v}")
    else:
        print("[ OK ] reverse check — all implements: references resolve to active ADRs")

    label = "FAIL" if strict else "WARN"
    if uncovered:
        print(f"[{label}] forward coverage — {len(uncovered)} Accepted ADR(s) not yet "
              f"implemented by any skill or script:")
        print("   " + ", ".join(f"ADR-{n}" for n in uncovered))
    else:
        print("[ OK ] forward coverage — every active ADR is implemented")

    failed = bool(reverse_violations) or (strict and bool(uncovered))
    print("----")
    print("RESULT: FAIL" if failed else "RESULT: PASS")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
