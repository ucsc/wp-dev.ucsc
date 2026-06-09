#!/usr/bin/env python3
# implements: ADR-106-MAINTAINER-GENERATE-DOCS-MODE-MARKER-DRIVEN-DOCUMENTATION, ADR-018-MAINTAINER-SLIDE-DECK, ADR-099-MAINTAINER-RETRO-MODE-ORCHESTRATION-WRAPPER-SCRIPTS
"""Harvest slide content from skills and ADRs into the canonical deck.

This is the marker-driven documentation harvester sketched in ADR-106. It keeps
the canonical Marp deck (ADR-018) deterministic: the editorial framing slides are
hand-authored, and two AUTO regions are regenerated in place from the live tree
so the deck never drifts from the skill set.

Sources (the signal lives where it is true):
  - skills/hub/references/skill-tree.json  — the ordered public skill set and
    each skill's argument hint and sub-modes (already the sync-inventory source
    of truth, so the per-skill slides cannot drift from the live inventory).
  - skills/<skill>/SKILL.md                — an optional `<!-- doc-slide: ... -->`
    landmark gives each skill's one-line tour copy; falls back to the
    skill-tree short_description when the landmark is absent.
  - docs/adr/index.md                      — Proposed ADRs become the roadmap.

Targets (rewritten in place, marker lines preserved):
  <!-- BEGIN AUTO:skills -->  ... <!-- END AUTO:skills -->
  <!-- BEGIN AUTO:roadmap --> ... <!-- END AUTO:roadmap -->

Usage:
  build-slides.py            Rewrite the AUTO regions in the canonical deck.
  build-slides.py --check    Write nothing; exit 0 if the regions are already
                             current, 3 if a rebuild is needed, 2 on error.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

PLUGIN_ROOT = Path(__file__).resolve().parents[3]
SKILLS_DIR = PLUGIN_ROOT / "skills"
SKILL_TREE = SKILLS_DIR / "hub" / "references" / "skill-tree.json"
ADR_INDEX = PLUGIN_ROOT / "docs" / "adr" / "index.md"
DECK = SKILLS_DIR / "maintainer" / "assets" / "ucsc-wp-block-dev-presentation.md"

DOC_SLIDE_RE = re.compile(r"<!--\s*doc-slide:\s*(.*?)\s*-->", re.DOTALL)
ADR_ROW_RE = re.compile(
    r"^\|\s*\[ADR-(\d+)\]\([^)]*\)\s*\|\s*(.*?)\s*\|\s*([A-Za-z]+)\s*\|"
)


def fail(msg: str) -> "NoReturn":  # type: ignore[name-defined]
    sys.stderr.write(f"FAIL build-slides: {msg}\n")
    sys.exit(2)


def doc_slide_for(skill_name: str, fallback: str) -> str:
    """Return the harvested `doc-slide:` landmark, or the fallback one-liner."""
    skill_md = SKILLS_DIR / skill_name / "SKILL.md"
    if skill_md.is_file():
        match = DOC_SLIDE_RE.search(skill_md.read_text(encoding="utf-8"))
        if match:
            return " ".join(match.group(1).split())
    return fallback


def render_skills_region() -> str:
    if not SKILL_TREE.is_file():
        fail(f"missing skill tree: {SKILL_TREE}")
    tree = json.loads(SKILL_TREE.read_text(encoding="utf-8"))
    skills = tree.get("skills", [])
    if not skills:
        fail("skill tree has no skills")

    parts = [
        "",
        "## **The Skills**",
        "",
        "One slide per public skill, harvested from `skill-tree.json` and the "
        "`doc-slide:` landmark in each `SKILL.md` (ADR-106).",
        "",
    ]
    for skill in skills:
        name = skill["name"]
        hint = skill.get("argument_hint", "").strip()
        summary = doc_slide_for(name, skill.get("short_description", ""))
        header = f"## Skill: `{name}`"
        if hint:
            header += f" &nbsp; `{hint}`"
        parts.append("---")
        parts.append("")
        parts.append(header)
        parts.append("")
        parts.append(summary)
        modes = skill.get("modes", [])
        if modes:
            parts.append("")
            mode_lines = [
                f"* `{m['name']}` — {m.get('short_description', '').strip()}"
                for m in modes
            ]
            parts.append("**Modes:**")
            parts.append("")
            parts.extend(mode_lines)
        parts.append("")
    return "\n".join(parts)


def render_roadmap_region() -> str:
    if not ADR_INDEX.is_file():
        fail(f"missing ADR index: {ADR_INDEX}")
    proposed: list[tuple[str, str]] = []
    for line in ADR_INDEX.read_text(encoding="utf-8").splitlines():
        match = ADR_ROW_RE.match(line)
        if match and match.group(3).lower() == "proposed":
            proposed.append((f"ADR-{match.group(1)}", match.group(2).strip()))

    parts = [
        "",
        "## **Roadmap — Proposed ADRs**",
        "",
        "Future direction lives as **Proposed** ADRs; each graduates to Accepted "
        "when it is built. Harvested live from `docs/adr/index.md` (ADR-048, ADR-106).",
        "",
    ]
    if proposed:
        for adr, title in proposed:
            parts.append(f"* **{adr}** — {title}")
    else:
        parts.append("* *No open proposals — every recorded decision is Accepted.*")
    parts.append("")
    return "\n".join(parts)


def replace_region(text: str, tag: str, body: str) -> str:
    begin = f"<!-- BEGIN AUTO:{tag} -->"
    end = f"<!-- END AUTO:{tag} -->"
    pattern = re.compile(
        re.escape(begin) + r".*?" + re.escape(end), re.DOTALL
    )
    if not pattern.search(text):
        fail(f"deck is missing the AUTO:{tag} region markers")
    return pattern.sub(f"{begin}\n{body}\n{end}", text)


def main() -> int:
    args = sys.argv[1:]
    if "--help" in args or "-h" in args:
        print(__doc__)
        return 0
    check = "--check" in args
    if not DECK.is_file():
        fail(f"missing canonical deck: {DECK}")
    original = DECK.read_text(encoding="utf-8")
    updated = replace_region(original, "skills", render_skills_region())
    updated = replace_region(updated, "roadmap", render_roadmap_region())

    if check:
        if updated != original:
            sys.stderr.write(
                "STALE deck AUTO regions are out of date — run build-slides.py\n"
            )
            return 3
        print("FRESH deck AUTO regions match skills and ADR roadmap")
        return 0

    if updated != original:
        DECK.write_text(updated, encoding="utf-8")
        print(f"PASS rebuilt AUTO regions in {DECK}")
    else:
        print(f"PASS deck AUTO regions already current ({DECK})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
