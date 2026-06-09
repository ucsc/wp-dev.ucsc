# Develop mode menu

implements: ADR-086-DEVELOP-LAUNCHER, ADR-088-DEVELOP-SKILL-MODES

When `develop` is invoked without a mode and the intended mode is not clear from
the request, present this menu (the hub subtree for `develop`, ADR-088) and wait
for the user to choose.

```text
develop  [feature|fix] [block] [request]  — add or modify WordPress block code
├─ feature  [block] [request]  — implement planned block behavior
└─ fix      [block] [problem]  — diagnose and repair a block defect
```

Bare `develop` (no mode) follows the general add/modify flow in `SKILL.md` when
the work does not fit `feature` or `fix` cleanly. The tree above is rendered from
`skills/hub/references/skill-tree.json` by `sync-inventory.sh`, so it always
matches the hub. The full per-mode argument syntax lives in each mode's
`argument-hint` (surfaced by the `/` slash menu); `feature` and `fix` both also
accept a Jira or GitHub URL/ID.
