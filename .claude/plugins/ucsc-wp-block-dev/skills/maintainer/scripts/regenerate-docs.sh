#!/usr/bin/env bash
# implements: ADR-045-MAINTAINER-GENERATE-DOCS, ADR-107-MAINTAINER-DOCS-MODE-CONSOLIDATION
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: regenerate-docs.sh [--check]

Regenerates maintainer documentation artifacts under
skills/maintainer/references/. Does not publish or upload anything.

  (no args)   Regenerate the guide and deck artifacts and stamp a source hash.
  --check     Do not write anything. Compare the source hash stored in the
              generated guide against the current sources and report whether
              regeneration is needed. Exit 0 = FRESH, 3 = STALE, 2 = error.
EOF
}

MODE="regenerate"
case "${1:-}" in
  --help|-h)
    usage
    exit 0
    ;;
  --check)
    MODE="check"
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
scripts_dir="$maintainer_dir/scripts"

# The guide is only the README span(s) between GUIDE markers — install/usage,
# no design history or contributor material (ADR-107). Falls back to the whole
# README when the markers are absent.
guide_source_text() {
  if grep -q '<!-- BEGIN GUIDE -->' "$main_source"; then
    awk '
      /<!-- BEGIN GUIDE -->/ { ing=1; next }
      /<!-- END GUIDE -->/   { ing=0; print ""; next }
      ing { print }
    ' "$main_source"
  else
    cat "$main_source"
  fi
}

main_source="$plugin_root/README.md"
manifest_source="$plugin_root/.claude-plugin/plugin.json"
deck_source="$maintainer_dir/assets/ucsc-wp-block-dev-presentation.md"
# The guide appends a harvested `:hub` skill list (ADR-107), so the skill tree is
# a guide source and belongs in the staleness hash.
skill_tree_source="$plugin_root/skills/hub/references/skill-tree.json"
main_out="$out_dir/generate-docs-main.md"
deck_out="$out_dir/generate-docs-presentation.md"
generated_date="$(date +%Y-%m-%d)"

# A content hash of exactly the bytes the script copies into the artifacts
# (README + manifest version + canonical deck + skill tree). It is independent of git
# working-tree state, so a committed-but-unregenerated source change is still
# detected. `git hash-object` is preferred; shasum is the portable fallback
# when git is unavailable.
file_hash() {
  local f="$1"
  if command -v git >/dev/null 2>&1 && git hash-object "$f" >/dev/null 2>&1; then
    git hash-object "$f"
  else
    shasum -a 256 "$f" | awk '{print $1}'
  fi
}

compute_source_hash() {
  local acc=""
  local f
  for f in "$main_source" "$manifest_source" "$deck_source" "$skill_tree_source"; do
    [[ -f "$f" ]] || { echo ""; return 1; }
    acc+="$(file_hash "$f")"
  done
  printf '%s' "$acc" | shasum -a 256 | awk '{print $1}'
}

stored_source_hash() {
  # Read `source-hash:` from the generated guide's frontmatter.
  [[ -f "$main_out" ]] || { echo ""; return 0; }
  awk -F': ' '/^source-hash: /{print $2; exit}' "$main_out"
}

if [[ ! -f "$main_source" ]]; then
  echo "FAIL missing main source: $main_source" >&2
  exit 1
fi

if [[ ! -f "$manifest_source" ]]; then
  echo "FAIL missing plugin manifest: $manifest_source" >&2
  exit 1
fi

if [[ ! -f "$deck_source" ]]; then
  echo "FAIL missing slide deck source: $deck_source" >&2
  exit 1
fi

# Refresh the canonical deck's harvested AUTO regions from the live skills and
# ADRs (ADR-106) before hashing/copying so a `docs` run reflects the live tree.
# In check mode we only ask whether the regions are stale (it writes nothing).
if [[ "$MODE" == "check" ]]; then
  if ! python3 "$scripts_dir/build-slides.py" --check >/dev/null 2>&1; then
    echo "STALE slide deck AUTO regions are out of date vs skills/ADRs"
    echo "  run: bash skills/maintainer/scripts/regenerate-docs.sh"
    exit 3
  fi
else
  python3 "$scripts_dir/build-slides.py" >/dev/null || {
    echo "FAIL build-slides.py could not refresh the deck" >&2
    exit 1
  }
fi

current_hash="$(compute_source_hash)"
plugin_version="$(sed -nE 's/^[[:space:]]*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' "$manifest_source" | head -n 1)"
[[ -n "$plugin_version" ]] || { echo "FAIL plugin version missing from manifest" >&2; exit 1; }
git_commit="$(git -C "$plugin_root" rev-parse HEAD 2>/dev/null || printf 'unknown')"
git_commit_short="${git_commit:0:12}"

if [[ "$MODE" == "check" ]]; then
  stored="$(stored_source_hash)"
  if [[ -z "$stored" ]]; then
    echo "STALE no generated guide or stored source hash — run regenerate-docs.sh"
    exit 3
  fi
  if [[ "$stored" == "$current_hash" ]]; then
    echo "FRESH generated docs match current sources (source-hash ${current_hash:0:12})"
    exit 0
  fi
  echo "STALE sources changed since last regeneration"
  echo "  stored:  ${stored:0:12}"
  echo "  current: ${current_hash:0:12}"
  echo "  run: bash skills/maintainer/scripts/regenerate-docs.sh"
  exit 3
fi

mkdir -p "$out_dir"  # references/ should already exist; guard for safety

{
  printf -- "---\n"
  printf "title: UCSC WordPress Block Development Plugin Guide\n"
  printf "generated: %s\n" "$generated_date"
  printf "version: %s\n" "$plugin_version"
  printf "git-commit: %s\n" "$git_commit"
  printf "source: README.md\n"
  printf "source-hash: %s\n" "$current_hash"
  printf -- "---\n\n"
  guide_source_text | awk -v generated="$generated_date" -v version="$plugin_version" -v commit="$git_commit_short" '
    { print }
    !inserted && /^# / {
      print ""
      printf "**Generated:** %s · **Plugin version:** %s · **Git commit:** `%s`\n", generated, version, commit
      inserted = 1
    }
  '
  # Close the guide with the harvested post-install `:hub` skill list (ADR-107)
  # so a reader knows what to do after installing.
  printf "\n"
  python3 "$scripts_dir/build-slides.py" --guide-skills
} > "$main_out"

{
  printf "<!-- Generated: %s from skills/maintainer/assets/ucsc-wp-block-dev-presentation.md -->\n" "$generated_date"
  printf "<!-- source-hash: %s -->\n\n" "$current_hash"
  perl -pe "s{\\*\\*Generated:\\*\\* \\d{4}-\\d{2}-\\d{2}<br />}{**Generated:** ${generated_date}<br />}" "$deck_source"
} > "$deck_out"

printf "PASS regenerated documentation artifacts (source-hash %s):\n" "${current_hash:0:12}"
printf "  %s\n" "$main_out"
printf "  %s\n" "$deck_out"
