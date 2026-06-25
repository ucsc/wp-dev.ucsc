# Maintainer launcher

implements: ADR-086-MAINTAINER-CONVENTIONS

Use this when `/ucsc-wp-block-dev:maintainer` is invoked.

1. Resolve the first argument as the maintainer mode.
2. If a mode is provided, run the matching section in `SKILL.md`.
3. If no mode is provided, read `skill-menu-mode.md`, show that menu, and wait
   for the user to choose before running any operation.
4. Treat `test` as a legacy alias for `self-test`, `new-adr` as a legacy alias
   for `adr`, `generate-docs` as a legacy alias for `docs`, and `publish` (and
   `publish docs`/`publish slides`) as a legacy alias for `docs publish`; and
   route `skill-details`, `review-skills`, `review-contrib`, `promote-contrib`,
   and `sync-inventory` through matching `skill` submodes when presenting new
   guidance.
5. For `docs publish`, default to publishing both outputs when no target follows
   `publish`: run `scripts/publish-docs.sh --target both --confirm`. Route
   `docs publish guide` to `--target guide --confirm` and `docs publish slides`
   to `--target slides --confirm`. Accept `deck` as a compatibility alias for
   `slides`. Use `scripts/publish-docs.sh --dry-run` for preflight without
   external writes.
6. Route `retro` to `retrospective/SKILL.md`.
7. Never start `validate`, `review-skills`, or any plugin-dev agent from a bare
   maintainer invocation.
