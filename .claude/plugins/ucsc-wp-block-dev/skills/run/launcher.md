# Run launcher

implements: ADR-086-RUN-LAUNCHER

Use this when `run` is invoked (via `/ucsc-wp-block-dev:run` or model routing).

`run` has no public submodes. Resolve the block/app target and the
natural-language change, interaction, or URL from the arguments and context.
Follow the recorded build, launch, and driver path in `SKILL.md`. Ask one
concise question only when the target or interaction cannot be inferred.
