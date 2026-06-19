# Stack Profile

Generated from repository scan on 2026-06-08.

Git HEAD at scan time: `a7dc42af76716838647cd796ced05f0adfe86f91`

## Summary

`ucsc-gutenberg-blocks` is a WordPress plugin for UCSC custom Gutenberg blocks. It combines PHP plugin classes and templates with Gutenberg editor block registrations built by `@wordpress/scripts`.

## Versions

| Area | Evidence |
|---|---|
| Plugin version | `1.1.29` in `package.json` and `package-lock.json` |
| Lockfile version | `package-lock.json` lockfileVersion `2`; root package version `1.1.29` |
| Build tool | `@wordpress/scripts` resolved to `22.5.0` |
| JS runtime | React `17.0.2`, React DOM `17.0.2` |
| Bundler | Webpack `5.106.2` |
| Tests | Jest `27.5.1`, Babel Jest `27.5.1` |
| Testing libraries | `@testing-library/react` `12.1.5`, `@testing-library/jest-dom` `5.17.0` |
| Release tooling | `standard-version` `9.5.0`, `wp-scripts plugin-zip` |
| CSS framework | No direct Bootstrap, Tailwind, Bulma, or Foundation dependency found; CSS is plugin-authored |
| CI | PR tests: Node 18 and `npm ci`; tag releases: Node 17 and `npm install` |

## Architecture

- `index.php` includes classes, wires activation/deactivation hooks, flushes rewrite rules, enqueues `build/index.js`, and instantiates active feature classes.
- `src/index.js` imports block registration functions from `src/blocks/` and calls them.
- PHP classes register blocks with `register_block_type` and dynamic `render_callback` handlers.
- Substantial frontend markup lives in `templates/*.php`; editor controls and supporting JS/CSS live under `src/components/**`.
- Class Schedule and Campus Directory add public detail pages through WordPress rewrite rules and `template_include`.
- Unit tests live under `src/blocks/__tests__/` and rely on Jest virtual mocks for WordPress packages supplied at runtime.

## External Data

- `classes/ClassSchedule.php` registers REST routes under `ucscgutenbergblocks/v1` for class schedule data.
- `classes/CourseCatalog.php` handles PeopleSoft catalog data with transient caching.
- Course Catalog posts XML to the PeopleSoft catalog endpoint and caches by subject or department.
- Campus Directory uses LDAP, with options sourced from site/network settings and transients used for cached directory results.
