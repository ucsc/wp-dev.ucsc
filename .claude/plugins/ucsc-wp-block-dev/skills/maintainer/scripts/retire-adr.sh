#!/bin/bash
# retire-adr.sh — maintainer adr-mode helper for retiring / consolidating ADRs
# (implements: ADR-086-MAINTAINER-CONVENTIONS).
#
# Automates the DETERMINISTIC parts of moving an ADR out of the active set. The
# judgment parts — folding the absorbed decision into a survivor ADR and
# repointing prose/`implements:` markers — stay manual, and are surfaced as a
# reference checklist so nothing is left dangling (the accuracy guardrail from
# the first consolidation sample).
#
# Subcommands:
#   retire-adr.sh refs <NNN> [NNN...]     List every ACTIVE reference to each ADR
#                                         number (skips retired/ and adrs_retired.md
#                                         and the ADR's own file). Use BEFORE a merge
#                                         to scope the repointing, and AFTER to verify
#                                         zero references remain.
#   retire-adr.sh retire <NNN> [NNN...]   For each: move docs/adr/ADR-NNN-*.md to
#                                         retired/, set status to Superseded, drop its
#                                         index.md row, add a sorted adrs_retired.md
#                                         row. Then print any remaining references as a
#                                         repoint checklist.
#
# Run from anywhere; self-locates docs/adr via ${BASH_SOURCE[0]} (ADR-094).
set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd -- "$SCRIPT_DIR/../../.." && pwd)"
ADR_DIR="$PLUGIN_ROOT/docs/adr"

usage() {
  echo "Usage: retire-adr.sh refs|retire <NNN> [NNN...]"
  echo
  sed -n '2,27p' "$0" | sed 's/^# \{0,1\}//'
}

list_refs() {
  # $1 = zero-padded number (e.g. 058). Print active references, excluding the
  # retired set, the retired index, and the ADR's own (possibly retired) file.
  local n="$1"
  grep -rEn "ADR-${n}\b" "$PLUGIN_ROOT" \
    --include='*.md' --include='*.sh' --include='*.py' 2>/dev/null \
    | grep -vE "/docs/adr/retired/|/docs/adr/adrs_retired.md|/ADR-${n}-" \
    || true
}

case "${1:-}" in
  -h|--help|"") usage; exit 0 ;;
  refs)
    shift
    [ $# -ge 1 ] || { echo "refs needs at least one ADR number" >&2; exit 2; }
    for n in "$@"; do
      n="$(printf '%03d' "$((10#$n))")"
      echo "== references to ADR-${n} =="
      out="$(list_refs "$n")"
      if [ -n "$out" ]; then echo "$out"; else echo "  (none — clean)"; fi
    done
    ;;
  retire)
    shift
    [ $# -ge 1 ] || { echo "retire needs at least one ADR number" >&2; exit 2; }
    nums=()
    for n in "$@"; do nums+=("$(printf '%03d' "$((10#$n))")"); done
    ADR_DIR="$ADR_DIR" python3 - "${nums[@]}" <<'PY'
import os, re, sys, glob, shutil
adr = os.environ["ADR_DIR"]
absorbed = sys.argv[1:]
idx = os.path.join(adr, "index.md")
lines = open(idx).read().splitlines(keepends=True)
kept, captured = [], []
for ln in lines:
    m = re.search(r'\[ADR-(\d+)\]\((ADR-[^)]+\.md)\)', ln)
    if m and m.group(1) in absorbed:
        captured.append(ln.replace('(' + m.group(2) + ')', '(retired/' + m.group(2) + ')')
                          .replace('| Accepted |', '| Superseded |'))
    else:
        kept.append(ln)
open(idx, 'w').writelines(kept)
rp = os.path.join(adr, "adrs_retired.md")
rl = open(rp).read().splitlines(keepends=True)
head = [l for l in rl if not re.match(r'\|\s*\[ADR-\d+\]', l)]
rows = [l for l in rl if re.match(r'\|\s*\[ADR-\d+\]', l)] + captured
rows.sort(key=lambda l: int(re.search(r'ADR-(\d+)', l).group(1)))
open(rp, 'w').write(''.join(head).rstrip('\n') + '\n' + ''.join(rows))
for n in absorbed:
    matches = glob.glob(f"{adr}/ADR-{n}-*.md")
    if len(matches) != 1:
        print(f"  WARN: ADR-{n} matched {len(matches)} files; skipped", file=sys.stderr); continue
    src = matches[0]
    # Read fully BEFORE opening for write — open(src,'w') truncates first,
    # so reading inside the same expression would yield empty content.
    text = open(src).read()
    if not text.strip():
        print(f"  WARN: ADR-{n} source is empty; not moving", file=sys.stderr); continue
    open(src, 'w').write(text.replace("status: Accepted", "status: Superseded", 1))
    shutil.move(src, f"{adr}/retired/" + os.path.basename(src))
    print(f"  retired ADR-{n} -> retired/{os.path.basename(src)}")
PY
    echo
    echo "Remaining references to repoint (should be repointed to the survivor):"
    for n in "$@"; do
      n="$(printf '%03d' "$((10#$n))")"
      echo "== ADR-${n} =="
      out="$(list_refs "$n")"
      if [ -n "$out" ]; then echo "$out"; else echo "  (none — clean)"; fi
    done
    ;;
  *)
    echo "Unknown subcommand: $1" >&2; usage >&2; exit 2 ;;
esac
