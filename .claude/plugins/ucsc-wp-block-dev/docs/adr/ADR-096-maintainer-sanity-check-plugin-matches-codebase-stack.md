---
title: "ADR-096: Sanity-check that the active plugin matches the codebase stack"
status: Accepted
date: 2026-06-24
---

# ADR-096: Sanity-check that the active plugin matches the codebase stack

## Context

This plugin (`ucsc-wp-block-dev`) was forked from a Laravel + Vue development plugin (`ucsc-laravel-vue-dev`) and shares a near-identical skill set (hub, develop, review, run, validate, verify). Because the two plugins look alike and can be installed from different sources (an inline `--plugin-dir` dev copy and a marketplace copy), the wrong one can load silently:

- The WordPress plugin can be active while operating on a Laravel codebase, or the Laravel plugin can be active while operating on this WordPress/Gutenberg codebase.
- Skill namespaces and SessionStart banners then disagree with the project (e.g. a `[ucsc-laravel-vue-dev]` banner appearing in a WordPress repo), and stack-specific guidance is applied to the wrong code.

A mismatch like this is both confusing and unsafe: stack-specific build, test, and edit workflows assume a particular project layout.

## Decision

Skills that operate on a codebase must perform a lightweight stack sanity check before acting, and surface a mismatch rather than proceeding silently.

- Detect the project stack from the target repository using cheap, deterministic signals — for WordPress/Gutenberg: presence of `block.json`, `wp-scripts`/`@wordpress/*` dependencies, plugin PHP headers, `docker-compose` WordPress services, etc. The Laravel counterpart plugin should apply the symmetric check (`artisan`, `composer.json` Laravel deps, `resources/js` Vue, etc.).
- The WordPress plugin (`ucsc-wp-block-dev`) expects a WordPress/Gutenberg codebase; the Laravel plugin expects a Laravel + Vue codebase.
- If the detected stack does not match the active plugin, warn the user once and identify the mismatch (which plugin is active, which stack was detected). Recommend switching to the correct plugin instead of continuing.
- Do not hard-block on ambiguous or undetectable stacks; warn and let the user confirm. Block only when proceeding would clearly operate the wrong stack's workflow on the code.
- Perform the check once per session or when the target repository changes, consistent with the other once-per-session checks (see ADR-035, ADR-093).

## Consequences

- A WordPress plugin running against Laravel code (or vice versa) is caught early instead of producing wrong-stack build/test/edit actions.
- The forked-from-Laravel lineage no longer causes silent wrong-plugin sessions.
- Each plugin needs a small, reliable stack-detection signal set; these signals must be kept current as project conventions evolve.
- The check adds a minimal, once-per-session cost consistent with existing baseline checks.
