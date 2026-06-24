#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: regenerate-docs.sh

Regenerates maintainer documentation artifacts under
skills/maintainer/references/. Does not publish or upload anything.
EOF
}

case "${1:-}" in
  --help|-h)
    usage
    exit 0
    ;;
  "")
    ;;
  *)
    echo "Unknown argument: $1" >&2
    usage >&2
    exit 2
    ;;
esac

maintainer_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
plugin_root="$(cd "$maintainer_dir/../.." && pwd)"
out_dir="$maintainer_dir/references"

main_source="$plugin_root/README.md"
deck_source="$maintainer_dir/assets/ucsc-wp-block-dev-presentation.md"
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
  printf "<!-- Generated: %s from skills/maintainer/assets/ucsc-wp-block-dev-presentation.md -->\n\n" "$generated_date"
  perl -pe "s{\\*\\*Generated:\\*\\* \\d{4}-\\d{2}-\\d{2}<br />}{**Generated:** ${generated_date}<br />}" "$deck_source"
} > "$deck_out"

printf "PASS regenerated documentation artifacts:\n"
printf "  %s\n" "$main_out"
printf "  %s\n" "$deck_out"
