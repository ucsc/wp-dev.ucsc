---
title: "ADR-108: Plugin-scoped npm packages for test and lint tooling without polluting block package.json"
status: Proposed
date: 2026-06-26
---

# ADR-108: Plugin-scoped npm packages for test and lint tooling without polluting block package.json

## Status

Proposed

## Context

The `ucsc-wp-block-dev` plugin currently ships its self-test suite as a Python
pytest suite (`tests/test_plugin_structure.py`). JavaScript-layer checks —
linting SKILL.md code blocks, validating JSON files, or running eslint over
plugin scripts — currently have no automated home inside the plugin. Adding
these tools directly to the block plugin's `package.json`
(`ucsc-gutenberg-blocks`) would pollute a production dependency manifest with
plugin-maintenance tooling that has nothing to do with shipping WordPress blocks.

A precedent for this tension already exists with Python: ADR-016 prohibits
bundling Python dependencies into the plugin (no `requirements.txt`), and
ADR-050 prohibits local PHP or Python invocations. The equivalent question for
npm has not yet been decided.

The plugin does already have its own `package.json` (or could have one) at the
plugin root, separate from any block plugin's manifest. npm packages installed
there would be isolated to the plugin's own `node_modules/` and would not affect
the block plugin's build, test, or install surface.

## Decision

The plugin **may** maintain its own `package.json` at the plugin root
(`.claude/plugins/ucsc-wp-block-dev/package.json`) for tooling used exclusively
in plugin self-tests and maintenance scripts.

- Packages listed there are **dev-only plugin tooling** (e.g., `eslint`,
  `ajv` for JSON schema validation). They must never appear in a block plugin
  manifest.
- The plugin's `package.json` must **not** be installed as part of the normal
  block plugin bootstrap (i.e., not wired into `docker-compose-install.yml` or
  any `plugin_npm_*` service).
- Installation is on-demand by the maintainer only: `npm install` run from the
  plugin root when running plugin self-tests locally.
- `node_modules/` and `package-lock.json` at the plugin root must be listed in
  the plugin's `.gitignore`.
- Scripts that use these packages must fail gracefully if `node_modules/` is
  absent and emit a clear install hint, consistent with ADR-050's
  no-silent-dependency principle.
- The self-test runner (`run-all-plugin-tests.sh`) may invoke npm-based checks
  as an optional step guarded by a `node_modules/` presence check.

## Consequences

- **Positive:** JavaScript-layer plugin checks (eslint over scripts, JSON schema
  validation, SKILL.md code-block linting) become automatable without touching
  block plugin dependencies.
- **Positive:** Separation is explicit: plugin tooling lives in the plugin;
  production tooling lives in the block plugin. No cross-contamination.
- **Negative:** Maintainers must run a second `npm install` at the plugin root
  before running the full self-test suite; this is a new installation step not
  currently documented.
- **Negative:** Adds a second `package.json` / `node_modules/` tree in the repo,
  which could confuse developers unfamiliar with the two-package-json layout.
- **Risk:** If the gitignore is incomplete, `node_modules/` could be committed
  accidentally — the self-test suite should assert `node_modules/` is absent
  from git tracking (mirroring `test_no_stale_pycache_committed`).
