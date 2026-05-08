---
name: wordpress-practices
description: Use when writing or modifying PHP, JS, or CSS in WordPress plugins, registering blocks, enqueuing assets, creating REST endpoints, handling settings, or any WordPress development task. Provides project-specific conventions and WordPress best practices.
user-invocable: false
---

# WordPress Development Practices

This skill covers both general WordPress best practices and the specific conventions used in this project's two plugins.

---

## Project Conventions at a Glance

| Concern | ucsc-gutenberg-blocks | ucsc-custom-functionality |
|---------|----------------------|--------------------------|
| **Architecture** | Procedural classes, no namespaces | PSR-4 namespaced (`UCSC\Blocks\`), OOP |
| **Autoloading** | Manual `include_once()` in `index.php` | Composer PSR-4 autoloader |
| **Block registration** | `register_block_type()` in class constructors | ACF `acf_register_block_type()` via abstract `ACF_Group` |
| **Asset enqueue** | `wp_register_*` then enqueue in render callback | `Assets_Subscriber` + `.asset.php` manifests |
| **REST namespace** | `ucsc/v1` | Consumes external REST; no custom endpoints |
| **Templates** | `ob_start()` + `include()` + `ob_get_clean()` | View files in `src/views/` via controller |
| **Build tool** | `@wordpress/scripts` (`wp-scripts build`) | `@wordpress/scripts` (`wp-scripts build`) |
| **PHP strict types** | No | Yes (`declare(strict_types=1)`) |
| **Linting** | Jest for JS tests | PHPCS (WordPress-Extra), stylelint |

---

## Security — Always Follow These

### Output Escaping (mandatory for all rendered output)

```php
esc_html( $text );          // Text content
esc_attr( $value );         // HTML attributes
esc_url( $url );            // URLs (href, src)
wp_kses_data( $markup );    // Block wrapper attributes
wp_kses_post( $html );      // Post-level HTML (allows safe tags)
```

Never echo unescaped user-supplied or dynamic data. Escape as late as possible (at the point of output).

### Input Sanitization

```php
sanitize_text_field( $input );        // General text
sanitize_title_for_query( $input );   // Slugs/search terms
absint( $input );                     // Positive integers
filter_input( INPUT_GET, 'key', FILTER_DEFAULT ); // Query params (then sanitize)
```

### Nonces (forms and state-changing requests)

```php
// In form output:
wp_nonce_field( 'ucscplugin-validate' );

// In form handler:
check_admin_referer( 'ucscplugin-validate' );
```

### Capability Checks

```php
if ( ! current_user_can( 'manage_options' ) ) { return; }           // Admin pages
if ( ! current_user_can( 'edit_posts' ) ) { return new WP_Error(); } // REST endpoints
```

### REST API Permission Callbacks

```php
// Public data (read-only, non-sensitive):
'permission_callback' => '__return_true'

// Authenticated data:
'permission_callback' => function() { return current_user_can( 'edit_posts' ); }
```

---

## Block Registration

### ucsc-gutenberg-blocks pattern (standard blocks)

```php
register_block_type( 'ucscblocks/blockname', array(
    'editor_script'   => 'ucscblocks',
    'render_callback' => array( $this, 'theHTML' ),
    'editor_style'    => 'ucscblocks-editor',
) );
```

### ucsc-custom-functionality pattern (ACF blocks)

```php
// Extend abstract ACF_Group, define fields in child class
class News_Block extends ACF_Group {
    const NAME = 'news_query_block';
    // ...
}
```

---

## Asset Enqueuing

### Register early, enqueue only when needed

```php
// Register in init or enqueue_block_assets:
wp_register_script( 'classschedule-js', plugins_url( $js_file, __FILE__ ), array(), filemtime( $path ), true );
wp_register_style( 'classschedule', plugins_url( $css_file, __FILE__ ), array(), filemtime( $path ) );

// Enqueue only in render callback:
function theHTML( $attributes ) {
    wp_enqueue_script( 'classschedule-js' );
    wp_enqueue_style( 'classschedule' );
    // ...
}
```

### Cache busting

```php
// Development (file modification time):
filemtime( plugin_dir_path( __FILE__ ) . $file )

// Production (plugin version):
$plugin_data['Version']
```

### Environment detection

The project uses `DOCKER_DEV`, `WP_DEBUG`, and `SCRIPT_DEBUG` constants to toggle dev vs. production asset paths and versioning.

---

## REST API Endpoints

### Registration pattern (ucsc-gutenberg-blocks)

```php
register_rest_route( 'ucsc/v1', '/terms', [
    'methods'             => 'GET',
    'callback'            => [ $this, 'get_terms' ],
    'permission_callback' => '__return_true',
    'args'                => [
        'term' => [
            'required'          => true,
            'validate_callback' => function( $param ) { return is_numeric( $param ); },
        ],
    ],
] );
```

### Internal REST calls (server-side data fetching)

```php
$request  = new \WP_REST_Request( 'GET', '/ucsc/v1/terms' );
$response = rest_do_request( $request );
$data     = $response->get_data();
```

---

## Template Rendering

### ucsc-gutenberg-blocks pattern

```php
public function theHTML( $attributes ) {
    // Fetch data, prepare variables
    $courses      = /* ... */;
    $current_term = /* ... */;

    ob_start();
    include plugin_dir_path( __FILE__ ) . '../templates/ClassScheduleTemplate.php';
    return ob_get_clean();
}
```

Template files should document available variables at the top:
```php
/**
 * Variables available:
 *   $courses       array   Course data from the API
 *   $current_term  string  Active term code
 *   $attributes    array   Block attributes
 */
```

### ucsc-custom-functionality pattern

Uses MVC-style controllers in `src/Components/` with view files in `src/views/`:
```php
class News_Block_Controller extends Abstract_Controller {
    // Prepares data, renders view
}
```

---

## Naming Conventions

### PHP

| Element | Convention | Example |
|---------|-----------|---------|
| Global functions | `ucsc_` prefix | `ucsc_enqueue_admin_styles()` |
| Classes (gutenberg-blocks) | PascalCase, no namespace | `ClassSchedule`, `CourseCatalog` |
| Classes (custom-functionality) | PascalCase, namespaced | `UCSC\Blocks\Components\News_Block_Controller` |
| Abstract classes | `Abstract_` prefix | `Abstract_Controller` |
| Traits | `With_` prefix | `With_CTA_Field` |
| Interfaces | Noun | `CTA_Field`, `Taxonomies` |
| Subscribers | `*_Subscriber` | `Assets_Subscriber` |
| Constants | UPPER_SNAKE | `const NAME = 'news_query_block';` |
| REST namespace | `ucsc/v1` | `register_rest_route( 'ucsc/v1', ... )` |
| Block type names | `ucscblocks/blockname` | `ucscblocks/classschedule` |

### JavaScript / CSS

| Element | Convention | Example |
|---------|-----------|---------|
| Script handles | `ucsc-` or block prefix | `ucscblocks`, `classschedule-js` |
| Style handles | block name | `classschedule`, `campusdirectory` |
| JS files | lowercase | `classschedule.js`, `tablesorter.js` |
| CSS files | lowercase | `classschedule.css`, `campusdirectory.css` |
| SCSS files | kebab-case | `post-terms.scss`, `social-sharing.scss` |

### Settings / Options

| Element | Convention | Example |
|---------|-----------|---------|
| Option group | plugin slug | `ucsc_gutenberg_blocks` |
| Option names | snake_case | `ldap_api_key` |
| Settings page slug | plugin-slug-settings | `ucsc-gutenberg-blocks-network-settings` |
| Text domain | `ucsc` | |

---

## WordPress General Best Practices

### Always

- **Escape all output.** No exceptions.
- **Sanitize all input.** Use the appropriate sanitize function for the data type.
- **Use nonces** for any form submission or state-changing AJAX/REST request.
- **Check capabilities** before performing privileged actions.
- **Enqueue assets properly** — never hardcode `<script>` or `<link>` tags.
- **Use `plugin_dir_path()` and `plugin_dir_url()`** — never hardcode paths.
- **Prefix everything** in the global scope (functions, constants, option names) with `ucsc_`.
- **Use `$wpdb->prepare()`** for any direct database queries with variables.

### Avoid

- **Direct `$_GET` / `$_POST` access** without sanitization.
- **`extract()`** — makes variable origins unclear.
- **`eval()`** or `preg_replace()` with the `e` modifier.
- **Hardcoded URLs** — use `home_url()`, `admin_url()`, `rest_url()`.
- **Loading assets globally** when they're only needed on specific pages/blocks.
- **`query_posts()`** — use `WP_Query` or `get_posts()` instead.
- **Modifying core files or plugin files directly** — use hooks and filters.

### Accessibility in Templates

- Use semantic HTML (`<table>`, `<nav>`, `<main>`, `<header>`) and ARIA attributes.
- Add `aria-live="polite"` to dynamically updated regions.
- Add `aria-hidden="true"` to decorative icons.
- Escape alt text: `esc_attr( $image['alt'] ?? '' )`.
- See the global `CLAUDE.md` for detailed a11y fix patterns.

### Caching

```php
// Transient caching for external API calls (project pattern: 20-min expiry):
$data = get_transient( $cache_key );
if ( false === $data ) {
    $data = /* fetch from API */;
    set_transient( $cache_key, $data, 20 * MINUTE_IN_SECONDS );
}
```

### Rewrite Rules

When adding custom URL routes, flush rewrite rules on activation/deactivation:
```php
register_activation_hook( __FILE__, function() {
    // Register rules first, then flush
    flush_rewrite_rules();
} );
register_deactivation_hook( __FILE__, 'flush_rewrite_rules' );
```

The gutenberg-blocks plugin also auto-flushes on file modification using `filemtime()` checks against a stored option — this avoids requiring manual reactivation during development.
