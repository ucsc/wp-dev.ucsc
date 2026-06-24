# Validate launcher

implements: ADR-086-VALIDATE-LAUNCHER

Use this when `validate` is invoked (via `/ucsc-wp-block-dev:validate` or model
routing).

1. Resolve the first argument as the validate mode: `create` or `run`.
2. If a mode is provided, follow the `Confirm Type And Mode` step in `SKILL.md`,
   then read exactly one mode reference:
   - `validate create` → [`references/create.md`](references/create.md)
   - `validate run` → [`references/run.md`](references/run.md)
3. If no mode is provided:
   - When the request already makes the mode unambiguous — "write tests" implies
     `create`; "run the tests" implies `run` — state the inferred mode and
     confirm type (`php`/`jest`/`e2e`) in the single intake question per
     `SKILL.md`.
   - Otherwise read [`skill-menu-mode.md`](skill-menu-mode.md), show that menu,
     and wait for the user to choose before reading files or running commands.
4. Never run host `npm`/`wp-scripts`/PHP; all execution goes through the
   Dockerized driver (ADR-050).
