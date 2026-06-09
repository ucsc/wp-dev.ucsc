#!/bin/bash
# implements: ADR-095-RUN-WP-EVAL
# block-doctor.sh — diagnose why a dynamic block renders real content or a
# fallback. Renders the block server-side (anonymous) and audits the anonymous
# permission posture of the REST routes it may depend on, in one call. The PHP
# (helpers/block-doctor.php) runs in-container via the wp-eval.sh substrate, so
# no PHP is embedded in a shell string (ADR-095).
#
# Usage:
#   block-doctor.sh <block>            # e.g. ucscblocks/classschedule  OR  classschedule
#   block-doctor.sh <block> --ns ucsc  # audit a specific REST namespace prefix
#   block-doctor.sh --ns ucsc          # REST audit only (no block render)
#
# Env: WP_DEV_ROOT=/path   override repo-root autodetection
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"

usage() {
  sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'
}

BLOCK=""
NS="ucsc"
while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h|help) usage; exit 0 ;;
    --ns) NS="${2:-ucsc}"; shift 2 ;;
    -*) echo "block_doctor: unknown flag '$1'" >&2; usage >&2; exit 2 ;;
    *) BLOCK="$1"; shift ;;
  esac
done

bash "$HERE/wp-eval.sh" "$HERE/helpers/block-doctor.php" "DOCTOR_BLOCK=$BLOCK" "DOCTOR_REST_NS=$NS"
