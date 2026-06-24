# Run launcher

implements: ADR-086-RUN-LAUNCHER

Use this when `run` is invoked (via `/ucsc-wp-block-dev:run` or model routing).

`run` has no sub-modes, so there is no mode menu — do not prompt for one. Run the
workflow in `SKILL.md`:

1. Treat the first argument, if any, as a `driver.sh` phase — `inspect`, `build`,
   `launch`, `smoke`, `drive <url>`, `down`, or `all` — and pass it through per
   the Fast Path in `SKILL.md`.
2. With no argument, follow the Universal Command Intake in `SKILL.md` to resolve
   the requested operation before acting.
