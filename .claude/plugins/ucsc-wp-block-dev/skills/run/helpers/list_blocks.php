<?php
/**
 * list_blocks.php — print every `ucsc/*` block registered in the RUNNING
 * WordPress, one per line, sorted.
 *
 * This is the runtime source of truth for "all blocks, all plugins": it reads
 * the live WP_Block_Type_Registry, which already spans every activated plugin
 * (ucsc-blocks AND ucsc-gutenberg-blocks) — so it never needs to read either
 * repo's source. Run it via wp-cli over STDIN so this PHP stays in a reviewed
 * file rather than an inline `wp eval` string:
 *
 *   docker compose exec -T wpcli wp eval-file - < helpers/list_blocks.php
 *
 * (the run/list_blocks.sh wrapper does exactly this).
 */

$registry = WP_Block_Type_Registry::get_instance();
$names     = array();

foreach ( $registry->get_all_registered() as $name => $block_type ) {
	if ( strpos( $name, 'ucsc/' ) === 0 ) {
		$names[] = $name;
	}
}

sort( $names );

foreach ( $names as $name ) {
	echo $name, "\n";
}
