#!/usr/bin/env bash
set -euo pipefail

maintainer_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
plugin_root="$(cd "$maintainer_dir/../.." && pwd)"
out_dir="$maintainer_dir/references"

main_source="$plugin_root/README.md"
deck_source="$maintainer_dir/assets/ucsc_wp_block_dev_presentation.md"
main_out="$out_dir/generate-docs-main.md"
deck_out="$out_dir/generate-docs-presentation.md"
generated_date="$(date +%Y-%m-%d)"

mkdir -p "$out_dir"  # references/ should already exist; guard for safety

if [[ ! -f "$main_source" ]]; then
  echo "FAIL missing main source: $main_source" >&2
  exit 1
fi

if [[ ! -f "$deck_source" ]]; then
  echo "FAIL missing slide deck source: $deck_source" >&2
  exit 1
fi

{
  printf -- "---\n"
  printf "title: UCSC WordPress Block Development Plugin Guide\n"
  printf "generated: %s\n" "$generated_date"
  printf "source: README.md\n"
  printf -- "---\n\n"
  cat "$main_source"
} > "$main_out"

{
  printf "<!-- Generated: %s from skills/maintainer/assets/ucsc_wp_block_dev_presentation.md -->\n\n" "$generated_date"
  perl -pe "s{\\*\\*Generated:\\*\\* \\d{4}-\\d{2}-\\d{2}<br />}{**Generated:** ${generated_date}<br />}" "$deck_source"
} > "$deck_out"

printf "PASS regenerated documentation artifacts:\n"
printf "  %s\n" "$main_out"
printf "  %s\n" "$deck_out"
