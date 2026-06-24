# Develop mode menu

implements: ADR-086-DEVELOP-LAUNCHER, ADR-088-DEVELOP-SKILL-MODES

When `develop` is invoked without a mode and the intended mode is not clear from
the request, present this menu and wait for the user to choose.

| Mode | Use when |
|---|---|
| `develop feature` | Define and implement new behavior — a new block, an editor enhancement, or a behavior addition. |
| `develop fix` | Reproduce and repair a described defect in a specified target. |

Bare `develop` (no mode) follows the general add/modify flow in `SKILL.md` when
the work does not fit `feature` or `fix` cleanly.
