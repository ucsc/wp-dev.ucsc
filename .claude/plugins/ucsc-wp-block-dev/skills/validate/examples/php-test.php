<?php
/**
 * Standalone PHP test template for a ucsc-gutenberg-blocks dynamic block.
 *
 * Location: tests/php/MyBlockTest.php
 *
 * Run in-container (no PHPUnit required):
 *   docker run --rm -v "$PWD:/plugin" -w /plugin php:8.1-cli \
 *     php tests/php/MyBlockTest.php
 *
 * Pattern: define WP stubs, require the class under test, run assertions,
 * exit non-zero on any failure. CI runs this directly — no test runner needed.
 */

// ── WP function stubs ────────────────────────────────────────────────────────

$registered_blocks = array();
$registered_routes = array();

function register_block_type( $name, $args = array() ) {
	global $registered_blocks;
	$registered_blocks[ $name ] = $args;
}

function register_rest_route( $namespace, $route, $args = array() ) {
	global $registered_routes;
	$registered_routes[] = array( 'namespace' => $namespace, 'route' => $route );
}

function add_action( $hook, $callback ) {}
function add_filter( $hook, $callback ) {}
function esc_html( $text ) { return htmlspecialchars( $text, ENT_QUOTES ); }
function esc_attr( $text ) { return htmlspecialchars( $text, ENT_QUOTES ); }
function esc_html__( $text, $domain = 'default' ) { return $text; }
function get_transient( $key ) { return false; }
function set_transient( $key, $value, $ttl = 0 ) {}
function wp_json_encode( $data ) { return json_encode( $data ); }

// ── Helpers ──────────────────────────────────────────────────────────────────

$failures = array();

function assert_equals( $expected, $actual, $label ) {
	global $failures;
	if ( $expected !== $actual ) {
		$failures[] = "$label: expected " . var_export( $expected, true )
		            . ", got " . var_export( $actual, true );
	}
}

function assert_true( $condition, $label ) {
	global $failures;
	if ( ! $condition ) {
		$failures[] = "$label: expected true, got false";
	}
}

function assert_contains( $needle, $haystack, $label ) {
	global $failures;
	if ( strpos( $haystack, $needle ) === false ) {
		$failures[] = "$label: '$needle' not found in output";
	}
}

// ── Require the class under test ─────────────────────────────────────────────

require_once __DIR__ . '/../../classes/MyBlock.php';

// ── Tests ────────────────────────────────────────────────────────────────────

// Instantiate triggers register_block_type and register_rest_route via __construct
$block = new UCSC_Gutenberg_Blocks\MyBlock();

// 1. Block registration
assert_true(
	isset( $registered_blocks['ucscblocks/myblock'] ),
	'block is registered'
);

// 2. Render callback is set
assert_true(
	isset( $registered_blocks['ucscblocks/myblock']['render_callback'] ),
	'render_callback is set'
);

// 3. REST route is registered
$route_registered = false;
foreach ( $registered_routes as $r ) {
	if ( $r['namespace'] === 'ucscgutenbergblocks/v1' && strpos( $r['route'], 'myblock' ) !== false ) {
		$route_registered = true;
		break;
	}
}
assert_true( $route_registered, 'REST route is registered' );

// 4. Render output contains expected markup
$html = $block->render_callback( array( 'title' => 'Test Title' ), '' );
assert_contains( 'Test Title', $html, 'render contains title' );
assert_contains( 'ucsc-myblock', $html, 'render contains CSS class' );

// ── Report ────────────────────────────────────────────────────────────────────

if ( $failures ) {
	foreach ( $failures as $f ) {
		echo "FAIL: $f\n";
	}
	exit( 1 );
}

echo "PASS: MyBlockTest (" . ( 4 ) . " assertions)\n";
exit( 0 );
