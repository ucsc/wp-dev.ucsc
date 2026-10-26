#!/bin/bash
# Switch wp-dev.ucsc into one outage scenario for LDAP or campusdirectory.ucsc.edu
# (WPM-234). The wp container always reaches both hosts through toxiproxy, so a
# normal run and a fault run take the same path. Each command clears any
# previous fault and flushes transients so cached results do not hide the fault.
#
#   bin/fault.sh off | status
#   bin/fault.sh ldap-stall | ldap-down
#   bin/fault.sh cd-stall | cd-down | cd-403 | cd-html | cd-500
#
# stall = connection accepted, then no reply ever arrives
# down  = connection refused
# cd-403/html/500 = campusdirectory answers with that page (dev mu-plugin)
# Bash 3.2 compatible.

set -euo pipefail
cd "$(dirname "$0")/.."

TOXIPROXY='http://toxiproxy:8474'

# Toxiproxy API, called from inside the wp container (it shares the faults network).
api() {
	docker compose exec -T wp curl -sf -X "$1" "$TOXIPROXY$2" ${3:+-d "$3"} >/dev/null
}

# Run PHP with WordPress loaded in the wp container.
wp_php() {
	docker compose exec -T wp php -r "\$_SERVER['HTTP_HOST'] = 'wp-dev.ucsc'; require '/var/www/html/wp-load.php'; $1"
}

clear_faults() {
	api POST /reset
	wp_php "delete_option('ucsc_dev_fault_campusdirectory');"
}

flush_transients() {
	wp_php 'global $wpdb; $n = 0; foreach (["_transient_", "_site_transient_"] as $p) $n += $wpdb->query($wpdb->prepare("DELETE FROM {$wpdb->options} WHERE option_name LIKE %s", $wpdb->esc_like($p) . "%")); echo "flushed $n transient rows\n";'
}

stall() {
	api POST "/proxies/$1/toxics" '{"name":"stall","type":"timeout","stream":"downstream","attributes":{"timeout":0}}'
}

down() {
	api POST "/proxies/$1" '{"enabled":false}'
}

campusdirectory_answers() {
	wp_php "update_option('ucsc_dev_fault_campusdirectory', '$1');"
}

status() {
	docker compose exec -T wp curl -sf "$TOXIPROXY/proxies" | php_pretty
	wp_php "echo 'campusdirectory answers: ', get_option('ucsc_dev_fault_campusdirectory') ?: 'real', \"\n\";"
}

php_pretty() {
	docker compose exec -T wp php -r '
		foreach (json_decode(stream_get_contents(STDIN), true) as $name => $p) {
			$toxics = array_map(function ($t) { return $t["name"]; }, $p["toxics"]);
			printf("%-16s %s  %s\n", $name, $p["enabled"] ? "enabled " : "DISABLED", $toxics ? "toxics: " . implode(",", $toxics) : "");
		}'
}

case "${1:-}" in
	off)        clear_faults ;;
	status)     status; exit 0 ;;
	ldap-stall) clear_faults; stall ldap ;;
	ldap-down)  clear_faults; down ldap ;;
	cd-stall)   clear_faults; stall campusdirectory ;;
	cd-down)    clear_faults; down campusdirectory ;;
	cd-403)     clear_faults; campusdirectory_answers 403 ;;
	cd-html)    clear_faults; campusdirectory_answers html ;;
	cd-500)     clear_faults; campusdirectory_answers 500 ;;
	*)
		sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'
		exit 1
		;;
esac

flush_transients
echo "fault: $1"
