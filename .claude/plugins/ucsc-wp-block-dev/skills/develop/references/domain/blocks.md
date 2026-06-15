# UCSC Gutenberg Blocks

Reference for the `ucsc-gutenberg-blocks` WordPress plugin at `public/wp-content/plugins/ucsc-gutenberg-blocks/`.

**Scope.** Domain reference for work under
`public/wp-content/plugins/ucsc-gutenberg-blocks/`. Hosts may load it
automatically or pair it with a workflow skill.

This is a WordPress plugin, not a Laravel app. Use WordPress plugin patterns, Gutenberg block APIs, PHP render callbacks, and `@wordpress/scripts` conventions throughout.

## Fast Orientation

All paths relative to `public/wp-content/plugins/ucsc-gutenberg-blocks/`:

- **Bootstrap**: `index.php` — composition root; PHP class instantiation and block includes
- **PHP classes**: `classes/*.php` — one class per block or integration
- **Templates**: `templates/*.php` — substantial frontend markup lives here
- **Block JS**: `src/index.js` (entry), `src/blocks/<BlockName>.js` (per-block edit/save/registration)
- **Shared components**: `src/components/<Feature>/` — reusable editor components and frontend scripts
- **Tests**: `src/blocks/__tests__/*.test.js`, config at `jest-unit.config.js` + `jest-setup.js`
- **Build output**: `build/index.js`, `build/index.asset.php`

Stack versions and resolved dependencies: see [`references/stack-profile.md`](references/stack-profile.md). For detailed block architecture notes, see [`references/blocks-reference.md`](references/blocks-reference.md).

## Core Conventions

**PHP composition root** — `index.php` is the only place that `require`s classes and instantiates them. New blocks always get a line here.

**Dynamic blocks** — prefer PHP `register_block_type('ucscblocks/block-name', array('editor_script' => 'ucscblocks', 'render_callback' => array($this, 'theHTML')))` over static `save()` for server-rendered content. Static save is fine for editor-only or purely structural blocks.

**Class per block** — each block's PHP lives in `classes/<BlockName>.php`. Constructor hooks into `init` via `add_action`; the init callback registers the block and enqueues styles. `theHTML()` returns rendered HTML.

**Templates** — keep substantial markup in `templates/<block-name>.php` and `require` it from the render method.

**Transient caching** — all external API and LDAP calls must cache with `set_transient` / `get_transient`. Never hit PeopleSoft or LDAP on every page request.

**Escaping** — always escape output: `esc_html()`, `esc_attr()`, `esc_url()`, `sanitize_text_field()`. No raw `echo $_GET[...]`.

**Rewrite rules** — the `/course/<term>/<id>/` and `/directory/<cruzid>/` detail pages depend on custom rewrite rules and a flush. Preserve flush calls in `index.php` when modifying rules.

## Runtime Integrations

| Integration | Entry point | Notes |
|---|---|---|
| Class Schedule | `classes/ClassSchedule.php` | Registers `ucscgutenbergblocks/v1` REST routes for class schedule data |
| Course Catalog | `classes/CourseCatalog.php` | Calls PeopleSoft XML endpoint; 1-week transient cache |
| Campus Directory | `classes/CampusDirectoryAPI.php` | LDAP via `ldap_api_key`, `ldap_cn`, `ldap_url` network options |
| Class Schedule block | `src/blocks/ClassSchedule.js` | Uses internal REST requests to the Course Schedule API |

In local Docker, Campus Directory binds LDAP anonymously when `DOCKER_DEV=docker_dev`.

## Validation

Use the narrowest check that covers the change:

```bash
# Build only
npm run build
```

Note: the plugin does not currently have a `test` script in `package.json`. If Jest tests are added, run from `wp-dev.ucsc/` root via Docker:

```bash
docker compose -f docker-compose.yml -f docker-compose-start.yml run --rm \
  -w /var/www/html/wp-content/plugins/ucsc-gutenberg-blocks \
  plugin_npm_start npm test
```

## Reference Documentation

- **WordPress Block Editor Handbook**: [`https://developer.wordpress.org/block-editor/`](https://developer.wordpress.org/block-editor/) — Authoritative reference for Gutenberg block API, components, and attributes.
- **WordPress Gutenberg Tutorial**: [`https://developer.wordpress.org/block-editor/getting-started/tutorial/`](https://developer.wordpress.org/block-editor/getting-started/tutorial/) — Step-by-step guide on creating custom Gutenberg blocks.
- **WordPress Create Block Tool Guide**: [`https://developer.wordpress.org/block-editor/getting-started/devenv/get-started-with-create-block/`](https://developer.wordpress.org/block-editor/getting-started/devenv/get-started-with-create-block/) — Quick-start guide using `@wordpress/create-block`.
- **WordPress Block Editor Package Reference**: [`https://developer.wordpress.org/block-editor/reference-guides/packages/packages-block-editor/`](https://developer.wordpress.org/block-editor/reference-guides/packages/packages-block-editor/) — API reference for `@wordpress/block-editor` components and functions.
- **WordPress Block Development Examples**: [`https://github.com/WordPress/block-development-examples`](https://github.com/WordPress/block-development-examples) — Official repository containing clean patterns, components, and recipes for custom Gutenberg blocks.
