#!/usr/bin/env python3
"""skill_details.py — live per-skill frontmatter and invocation settings (ADR-071).

Usage:
    python3 skill_details.py [--plugin-root <path>]

Reads every skills/*/SKILL.md, resolves absent fields to platform defaults,
and prints the invocation grid with actual values. Flags any skill that
differs from the all-defaults baseline.
"""
import os
import re
import sys

if "--help" in sys.argv[1:] or "-h" in sys.argv[1:]:
    print(__doc__.strip())
    raise SystemExit(0)

PLUGIN_ROOT = None
for i, arg in enumerate(sys.argv[1:]):
    if arg == "--plugin-root" and i + 2 <= len(sys.argv) - 1:
        PLUGIN_ROOT = sys.argv[i + 2]

if not PLUGIN_ROOT:
    PLUGIN_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../.."))

SKILLS_DIR = os.path.join(PLUGIN_ROOT, "skills")

# Platform defaults per https://code.claude.com/docs/en/skills
DEFAULTS = {
    "user-invocable": True,
    "disable-model-invocation": False,
    "allowed-tools": None,
    "disallowed-tools": None,
    "context": None,
    "agent": None,
    "model": None,
    "effort": None,
    "paths": None,
    "when_to_use": None,
    "argument-hint": None,
    "arguments": None,
    "hooks": None,
    "shell": None,
}

INVOCATION_FIELDS = [
    "user-invocable",
    "disable-model-invocation",
    "allowed-tools",
    "disallowed-tools",
    "context",
    "agent",
]

def parse_frontmatter(path):
    try:
        text = open(path).read()
    except OSError:
        return {}
    m = re.match(r"^---\n(.*?)\n---", text, re.DOTALL)
    if not m:
        return {}
    fm = {}
    for line in m.group(1).splitlines():
        if ":" in line and not line.startswith(" "):
            k, _, v = line.partition(":")
            k = k.strip()
            v = v.strip()
            if v.lower() == "true":
                v = True
            elif v.lower() == "false":
                v = False
            elif v == "":
                v = None
            fm[k] = v
    return fm

def resolve(fm, field):
    if field in fm:
        return fm[field]
    return DEFAULTS.get(field)

def fmt(val):
    if val is True:
        return "true"
    if val is False:
        return "false"
    if val is None:
        return "—"
    return str(val)

def is_default(fm, field):
    return resolve(fm, field) == DEFAULTS.get(field)

def skill_row(name, fm):
    ui  = resolve(fm, "user-invocable")
    dmi = resolve(fm, "disable-model-invocation")
    mi  = not dmi   # model-invocable = NOT disable-model-invocation
    disc = mi       # discoverable = description in context = model-invocable

    at  = resolve(fm, "allowed-tools")
    dt  = resolve(fm, "disallowed-tools")
    ctx = resolve(fm, "context")
    agt = resolve(fm, "agent")

    extra = {k: v for k, v in fm.items()
             if k not in ("name", "description") and k not in INVOCATION_FIELDS}

    non_default = [f for f in INVOCATION_FIELDS if not is_default(fm, f)]
    flag = " *" if non_default else ""

    return {
        "name": name,
        "user-invocable": fmt(ui),
        "model-invocable": fmt(mi),
        "discoverable": fmt(disc),
        "disable-model-invocation": fmt(dmi),
        "allowed-tools": fmt(at),
        "disallowed-tools": fmt(dt),
        "context": fmt(ctx),
        "agent": fmt(agt),
        "extra": extra,
        "flag": flag,
    }

skills = []
for d in sorted(os.listdir(SKILLS_DIR)):
    skill_md = os.path.join(SKILLS_DIR, d, "SKILL.md")
    if os.path.isdir(os.path.join(SKILLS_DIR, d)) and os.path.exists(skill_md):
        fm = parse_frontmatter(skill_md)
        skills.append(skill_row(d, fm))

col_w = {
    "name": max(len(s["name"]) for s in skills) + 1,
    "user-invocable": 14,
    "model-invocable": 15,
    "discoverable": 13,
    "disable-model-invocation": 10,
    "allowed-tools": 13,
    "context": 9,
    "agent": 9,
}

def row(s):
    flag = s["flag"]
    name_col = (s["name"] + flag).ljust(col_w["name"])
    return (
        f"  {name_col}"
        f"  {s['user-invocable'].ljust(col_w['user-invocable'])}"
        f"  {s['model-invocable'].ljust(col_w['model-invocable'])}"
        f"  {s['discoverable'].ljust(col_w['discoverable'])}"
        f"  {s['disable-model-invocation'].ljust(col_w['disable-model-invocation'])}"
        f"  {s['allowed-tools'].ljust(col_w['allowed-tools'])}"
        f"  {s['context'].ljust(col_w['context'])}"
        f"  {s['agent'].ljust(col_w['agent'])}"
    )

hdr = row({
    "name": "Skill", "flag": "",
    "user-invocable": "user-invocable",
    "model-invocable": "model-invocable",
    "discoverable": "discoverable",
    "disable-model-invocation": "disable-mi",
    "allowed-tools": "allowed-tools",
    "context": "context",
    "agent": "agent",
})
sep = "  " + "-" * (len(hdr) - 2)

print("Skill invocation details (ADR-071)")
print(sep)
print(hdr)
print(sep)
for s in skills:
    print(row(s))
print(sep)

flagged = [s for s in skills if s["flag"]]
if flagged:
    print(f"\n* Non-default setting — differs from platform defaults:")
    for s in flagged:
        fm = parse_frontmatter(os.path.join(SKILLS_DIR, s["name"], "SKILL.md"))
        non_default = {f: resolve(fm, f) for f in INVOCATION_FIELDS if not is_default(fm, f)}
        print(f"  {s['name']}: {non_default}")

extra_skills = [s for s in skills if s["extra"]]
if extra_skills:
    print("\nExtra frontmatter fields (beyond name/description/invocation):")
    for s in extra_skills:
        print(f"  {s['name']}: {s['extra']}")

if not flagged and not extra_skills:
    print("\nAll skills on platform defaults.")
