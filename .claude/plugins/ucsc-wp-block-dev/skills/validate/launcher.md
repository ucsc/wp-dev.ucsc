# Validate launcher

implements: ADR-086-VALIDATE-LAUNCHER

Use this when `validate` is invoked (via `/ucsc-wp-block-dev:validate` or model
routing).

1. Resolve the first argument as the test type: `php`, `jest`, or `e2e`.
2. Resolve the second argument as `create` or `run`, then read exactly one
   operation reference:
   - `create` → [`references/create.md`](references/create.md)
   - `run` → [`references/run.md`](references/run.md)
3. If either value is missing, infer it when clear; otherwise show
   [`skill-menu-mode.md`](skill-menu-mode.md) and ask one question for both.
4. Never run host `npm`/`wp-scripts`/PHP; all execution goes through the
   Dockerized driver (ADR-050).
