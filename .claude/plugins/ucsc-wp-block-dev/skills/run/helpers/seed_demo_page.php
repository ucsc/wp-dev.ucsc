<?php
/**
 * seed_demo_page.php — upsert a single "UCSC Block Demo" page whose content is
 * every `ucsc/*` block currently registered in the RUNNING WordPress.
 *
 * Registry-driven, so it spans ALL activated plugins (ucsc-blocks AND
 * ucsc-gutenberg-blocks) automatically and shrinks to whatever is present when
 * only one plugin is active — without reading either repo's source. Idempotent:
 * keyed on the page slug, it updates in place on re-run. Prints the permalink.
 *
 * Run in-container only (host PHP is not guaranteed):
 *   docker compose exec -T wpcli wp eval-file - < helpers/seed_demo_page.php
 */

$slug = 'ucsc-block-demo';

$registry = WP_Block_Type_Registry::get_instance();
$names     = array();
foreach ( $registry->get_all_registered() as $name => $block_type ) {
	if ( strpos( $name, 'ucsc/' ) === 0 ) {
		$names[] = $name;
	}
}
sort( $names );

$content = '';
foreach ( $names as $name ) {
	$content .= "<!-- wp:{$name} /-->\n\n";
}
if ( '' === $content ) {
	$content = "<!-- wp:paragraph --><p>No ucsc/* blocks are registered.</p><!-- /wp:paragraph -->";
}

$postarr = array(
	'post_title'   => 'UCSC Block Demo',
	'post_name'    => $slug,
	'post_status'  => 'publish',
	'post_type'    => 'page',
	'post_content' => $content,
);

$existing = get_page_by_path( $slug, OBJECT, 'page' );
if ( $existing ) {
	$postarr['ID'] = $existing->ID;
	$id            = wp_update_post( $postarr, true );
} else {
	$id = wp_insert_post( $postarr, true );
}

if ( is_wp_error( $id ) ) {
	fwrite( STDERR, 'seed_demo_page: ' . $id->get_error_message() . "\n" );
	exit( 1 );
}

echo get_permalink( $id ), "\n";
