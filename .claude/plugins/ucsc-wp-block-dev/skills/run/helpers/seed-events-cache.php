<?php
/**
 * seed-events-cache.php — seed the ucsc/events transient so the block renders
 * real cards offline (without hitting the live events API).
 *
 * The block reads a transient keyed ucsc_events_<md5(apiUrl)>; this writes one
 * sample event under the default API URL. Run in-container only:
 *   docker compose exec -T wpcli wp eval-file - < helpers/seed-events-cache.php
 * Clear again with: wp transient delete --all
 */

$api = 'https://events.ucsc.edu/wp-json/tribe/v1/events';
$key = 'ucsc_events_' . md5( $api );

set_transient(
	$key,
	array(
		array(
			'title'          => 'Sample Event',
			'link'           => 'https://events.ucsc.edu/e/1',
			'date'           => 'July 10, 2026',
			'venue'          => 'Quarry Plaza',
			'slug'           => 'e1',
			'featured_image' => '',
		),
	),
	HOUR_IN_SECONDS
);

echo "seeded {$key}\n";
