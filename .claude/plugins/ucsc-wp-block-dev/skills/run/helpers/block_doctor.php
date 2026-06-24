<?php
/**
 * block_doctor.php — explain WHY a (usually dynamic) block renders its real
 * content or falls back, in one call. Built for the recurring "the block shows
 * a placeholder / 'No X available' and I don't know why" diagnosis.
 *
 * It does two things a single `wp eval` rarely does together:
 *   1. Renders the target block server-side as the current (anonymous) user and
 *      reports the output + a heuristic "looks like a fallback" flag.
 *   2. Audits the anonymous permission posture of every REST route in a
 *      namespace — because a dynamic block that fetches via its OWN
 *      rest_do_request() endpoints silently 401s (and falls back) when those
 *      routes deny anonymous access during a logged-out frontend render.
 *
 * Env:
 *   DOCTOR_BLOCK   block name or slug (e.g. ucscblocks/classschedule, classschedule)
 *   DOCTOR_REST_NS REST namespace prefix to audit (default: ucsc)
 *
 * Run via the wp_eval.sh substrate (no inline heredoc, ADR-095):
 *   wp_eval.sh helpers/block_doctor.php DOCTOR_BLOCK=ucscblocks/classschedule
 */

$target = getenv( 'DOCTOR_BLOCK' ) ?: '';
$ns     = getenv( 'DOCTOR_REST_NS' ) ?: 'ucsc';

$norm = function ( $s ) {
	return preg_replace( '/[^a-z0-9]/', '', strtolower( (string) $s ) );
};

// --- 1. block render -------------------------------------------------------
echo "== block ==\n";
$registry = WP_Block_Type_Registry::get_instance();
$all      = $registry->get_all_registered();

$resolved = null;
if ( '' !== $target ) {
	if ( isset( $all[ $target ] ) ) {
		$resolved = $target;
	} else {
		$nt = $norm( $target );
		foreach ( $all as $name => $bt ) {
			$short = strpos( $name, '/' ) !== false ? substr( strrchr( $name, '/' ), 1 ) : $name;
			if ( $norm( $name ) === $nt || $norm( $short ) === $nt ) {
				$resolved = $name;
				break;
			}
		}
	}
}

if ( '' === $target ) {
	echo "  (no DOCTOR_BLOCK given — skipping render, auditing REST only)\n";
} elseif ( null === $resolved ) {
	echo "  target '{$target}': NOT REGISTERED\n";
} else {
	$bt      = $all[ $resolved ];
	$dynamic = ! empty( $bt->render_callback );
	echo "  name: {$resolved}\n";
	echo "  dynamic (render_callback): " . ( $dynamic ? 'yes' : 'no' ) . "\n";
	echo "  current_user_id: " . get_current_user_id() . "\n";
	if ( $dynamic ) {
		$html  = render_block( array(
			'blockName'    => $resolved,
			'attrs'        => array(),
			'innerBlocks'  => array(),
			'innerHTML'    => '',
			'innerContent' => array(),
		) );
		$text  = trim( preg_replace( '/\s+/', ' ', wp_strip_all_tags( (string) $html ) ) );
		$short = function_exists( 'mb_substr' ) ? mb_substr( $text, 0, 240 ) : substr( $text, 0, 240 );
		echo "  rendered (anon, no attrs): " . ( '' === $short ? '[empty]' : $short ) . "\n";
		$markers = array( 'no ', 'error', 'unavailable', 'please select', 'try again', 'not found', 'no courses', 'no terms' );
		$low     = strtolower( $text );
		$is_fb   = false;
		foreach ( $markers as $m ) {
			if ( strpos( $low, $m ) !== false ) {
				$is_fb = true;
				break;
			}
		}
		echo "  looks like fallback: " . ( $is_fb ? 'YES — block is not getting data' : 'no' ) . "\n";
	}
}

// --- 2. REST posture (anonymous) -------------------------------------------
echo "== rest posture (anonymous, namespace '{$ns}') ==\n";
$server = rest_get_server();
$routes = $server->get_routes();
$seen   = array();
$denies = 0;
foreach ( $routes as $route => $handlers ) {
	if ( strpos( ltrim( $route, '/' ), $ns ) !== 0 ) {
		continue;
	}
	foreach ( $handlers as $h ) {
		$methods = isset( $h['methods'] ) && is_array( $h['methods'] )
			? implode( ',', array_keys( array_filter( $h['methods'] ) ) )
			: (string) ( $h['methods'] ?? 'GET' );
		$key = $route . '|' . $methods;
		if ( isset( $seen[ $key ] ) ) {
			continue;
		}
		$seen[ $key ] = 1;

		$cb = array_key_exists( 'permission_callback', $h ) ? $h['permission_callback'] : null;
		if ( null === $cb ) {
			$verdict = 'PUBLIC (no permission_callback)';
		} else {
			try {
				$req = new WP_REST_Request( 'GET', $route );
				$res = call_user_func( $cb, $req );
				if ( true === $res ) {
					$verdict = 'ALLOW anon';
				} else {
					$verdict = 'DENY  anon';
					$denies++;
				}
			} catch ( Throwable $e ) {
				$verdict = 'ERROR (' . $e->getMessage() . ')';
			}
		}
		echo "  [{$verdict}] {$methods} {$route}\n";
	}
}
if ( $denies > 0 ) {
	echo "  NOTE: internal rest_do_request() runs as current_user_id=" . get_current_user_id() . " with no nonce.\n";
	echo "        A DENY above means a server-side block render calling that route gets 401 and falls back.\n";
}
