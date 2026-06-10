# ADR-013: README is the canonical first-time user reference

**Status:** Accepted
**Date:** 2026-06-10

## Context

Plugin management commands — install, uninstall, reload, launch from source — are documented in the plugin README. Slide decks and the maintainer skill both reference these workflows but should not duplicate the full instructions. When commands change (new flags, renamed subcommands), a single source of truth prevents drift.

## Decision

The plugin `README.md` is the canonical reference for first-time users covering:

- Installation (`claude plugin install`)
- Uninstallation (`claude plugin uninstall`)
- Reloading after changes (`/reload-plugins`, `/reload-plugins --force`)
- Listing installed plugins (`claude plugin list`)
- Launching from source without installing (`claude --plugin-dir`)
- Anthropic plugin-dev tools (`plugin-dev:plugin-validator`, `plugin-dev:skill-reviewer`, `plugin-dev:skill-development`)

The slide deck and maintainer skill should reference the README rather than duplicating full command syntax. Brief inline examples are acceptable for slide context, but the README is authoritative.

## Consequences

- One place to update when plugin CLI commands change.
- Slide decks and skills link to the README for complete instructions.
- The maintainer skill's validate/test sections remain self-contained (they describe plugin-internal workflows, not user onboarding).
