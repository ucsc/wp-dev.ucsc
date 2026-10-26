<?php
/**
 * Plugin Name: UCSC dev faults
 * Description: wp-dev.ucsc only (WPM-234). Fakes campusdirectory.ucsc.edu answers chosen by bin/fault.sh, which a TCP proxy cannot do.
 */

add_filter('pre_http_request', function ($pre, $args, $url) {
  $mode = get_option('ucsc_dev_fault_campusdirectory');
  if (!$mode || wp_parse_url($url, PHP_URL_HOST) !== 'campusdirectory.ucsc.edu') return $pre;

  $answers = [
    '403'  => [403, '<html><body>Forbidden</body></html>'],
    'html' => [200, '<html><body>Please sign in</body></html>'],
    '500'  => [500, ''],
  ];
  if (!isset($answers[$mode])) return $pre;

  return [
    'headers'  => ['content-type' => 'text/html'],
    'body'     => $answers[$mode][1],
    'response' => ['code' => $answers[$mode][0], 'message' => ''],
    'cookies'  => [],
    'filename' => null,
  ];
}, 10, 3);
