---
title: "ADR-002: wp-dev.ucsc is the local development environment for block work"
status: Accepted
date: 2026-06-08
origin: Adapted from sw-dev ADR-041
---

# ADR-002: wp-dev.ucsc is the local development environment for block work

## Status

Accepted

## Context

WordPress plugin development requires a running WordPress instance. The UCSC team uses a dedicated Docker-based local dev environment:

- **Repository:** `https://github.com/ucsc/wp-dev.ucsc`
- **Role:** Runs a local WordPress instance; mounts `ucsc-gutenberg-blocks` into the container
- **Relationship to plugin code:** `wp-dev.ucsc` is infrastructure, not a code target

## Decision

`wp-dev.ucsc` is the environment where block code runs. Developers:

1. Start the Docker environment from `wp-dev.ucsc/`
2. Work on plugin code in `ucsc-gutenberg-blocks/` (inside `wp-dev.ucsc/public/wp-content/plugins/`)
3. Use `wp-dev.ucsc` for WP-CLI commands, browser testing, and container-level validation

The `ucsc-wp-block-dev` plugin lives at `wp-dev.ucsc/.claude/plugins/ucsc-wp-block-dev/` so it auto-discovers when the project root is `wp-dev.ucsc`. This is intentional — the developer's working directory is the dev environment, not a standalone plugin checkout.

### Docker commands use the container service name

WP-CLI and runtime checks run through Docker:

```bash
docker compose exec wordpress wp <command>
```

See `/ucsc-wp-block-dev:run` for the full Docker workflow.

### Environment vs. code

`wp-dev.ucsc` is an environment repo, not a code target. The `develop` and `fix` skills operate on `ucsc-gutenberg-blocks` code; the `run` skill operates on the Docker environment. These are kept in separate skills to avoid mixing concerns.

## Consequences

- The plugin auto-loads in the correct context (working in `wp-dev.ucsc`).
- Future UCSC WordPress plugins hosted in `wp-dev.ucsc` can be covered by extending this plugin's skills.
- The `run` skill owns all Docker/WP-CLI environment guidance; `develop` and `fix` stay focused on code.
