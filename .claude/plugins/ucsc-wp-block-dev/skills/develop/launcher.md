# Develop launcher

implements: ADR-086-DEVELOP-LAUNCHER

Use this when `develop` is invoked (via `/ucsc-wp-block-dev:develop` or model
routing).

1. Resolve the first argument as the develop mode: `feature` or `fix`.
2. If a mode is provided, run that mode's sub-skill:
   - `develop feature` → [`feature/SKILL.md`](feature/SKILL.md)
   - `develop fix` → [`fix/SKILL.md`](fix/SKILL.md)
3. If no mode is provided:
   - When the request already makes the mode unambiguous — a clear new-behavior
     request implies `feature`; a described defect to repair implies `fix` —
     state the inferred mode and proceed through the Universal Command Intake in
     `SKILL.md` rather than forcing the menu (ADR-036).
   - Otherwise read [`skill-menu-mode.md`](skill-menu-mode.md), show that menu,
     and wait for the user to choose before implementing.
4. Either way, follow the target-resolution contract in `SKILL.md`: infer the
   block target from the current working directory before prompting
   (ADR-084/ADR-090).
