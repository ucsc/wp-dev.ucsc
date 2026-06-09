#!/bin/bash
# submit-feedback.sh — package a feedback note plus session context and deliver
# it to the configured destination. The ucsc-wp-block-dev analog of Claude
# Code's /bug (implements: ADR-097-FEEDBACK-SUBMIT).
#
# A local JSON copy is ALWAYS written first so feedback is never lost, then the
# first configured channel is used:
#   1. REST endpoint  — POST application/json to $UCSC_FEEDBACK_ENDPOINT
#   2. Email          — send (or print) to $UCSC_FEEDBACK_EMAIL
#   3. Local fallback — keep only the saved copy and print how to wire a channel
#
# Config (env vars; a settings file may export these — see SKILL.md):
#   UCSC_FEEDBACK_ENDPOINT   REST URL accepting POST application/json
#   UCSC_FEEDBACK_TOKEN      optional bearer token for the endpoint
#   UCSC_FEEDBACK_EMAIL      destination address (used when no endpoint)
#   UCSC_FEEDBACK_FROM       optional From address for the email path
#   UCSC_WP_BLOCK_DEV_CACHE  cache dir (default ~/.cache/ucsc-wp-block-dev)
#
# Privacy: only the fields shown in the payload below are sent — the note, an
# optional category, the named skill/target, plugin version, timestamp, OS
# string, cwd, and git branch. No file contents or transcripts.
set -uo pipefail

usage() {
  cat <<'EOF'
Usage: submit-feedback.sh -m "<note>" [-c bug|idea|question|other] [-s <skill>] [-t <target>] [--dry-run]

Package a feedback note with session context and deliver it to the configured
destination (REST endpoint, else email, else a saved local copy). Reads the note
from stdin when -m is omitted.

Options:
  -m, --message   feedback text (or pipe it on stdin)
  -c, --category  bug | idea | question | other   (default: other)
  -s, --skill     skill the feedback is about (e.g. run, validate)
  -t, --target    block target in play (e.g. class-schedule)
      --dry-run   build and save the payload, but do not send
  -h, --help      show this help

Config env: UCSC_FEEDBACK_ENDPOINT, UCSC_FEEDBACK_TOKEN, UCSC_FEEDBACK_EMAIL,
UCSC_FEEDBACK_FROM, UCSC_WP_BLOCK_DEV_CACHE. See the feedback SKILL.md.
EOF
}

message=""
category="other"
skill=""
target=""
dry_run=0

while [ $# -gt 0 ]; do
  case "$1" in
    -m|--message)  message="${2:-}"; shift 2 ;;
    -c|--category) category="${2:-}"; shift 2 ;;
    -s|--skill)    skill="${2:-}"; shift 2 ;;
    -t|--target)   target="${2:-}"; shift 2 ;;
    --dry-run)     dry_run=1; shift ;;
    -h|--help)     usage; exit 0 ;;
    *)             echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

# Read the note from stdin when -m was not supplied.
if [ -z "$message" ] && [ ! -t 0 ]; then
  message="$(cat)"
fi
if [ -z "$message" ]; then
  echo "submit-feedback: a feedback note is required (-m or stdin)." >&2
  exit 2
fi

case "$category" in bug|idea|question|other) ;; *)
  echo "submit-feedback: invalid category '$category' (use bug|idea|question|other)." >&2
  exit 2 ;;
esac

command -v python3 >/dev/null 2>&1 || {
  echo "submit-feedback: python3 is required (JSON encoding)." >&2
  exit 2
}

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd -- "$HERE/../../.." && pwd)"

# --- gather context ---
version="$(python3 -c 'import json,sys
try: print(json.load(open(sys.argv[1])).get("version",""))
except Exception: print("")' "$PLUGIN_ROOT/.claude-plugin/plugin.json" 2>/dev/null)"
ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
platform="$(uname -sr 2>/dev/null || echo unknown)"
cwd="$PWD"
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"

cache="${UCSC_WP_BLOCK_DEV_CACHE:-$HOME/.cache/ucsc-wp-block-dev}/feedback"
mkdir -p "$cache"
saved="$cache/feedback-$(date -u +%Y%m%dT%H%M%SZ)-$$.json"

# --- build the JSON payload (python3 handles escaping; values via env) ---
FB_MESSAGE="$message" FB_CATEGORY="$category" FB_SKILL="$skill" FB_TARGET="$target" \
FB_VERSION="$version" FB_TS="$ts" FB_PLATFORM="$platform" FB_CWD="$cwd" FB_BRANCH="$branch" \
python3 - > "$saved" <<'PY'
import json, os
def opt(v): return v if v else None
doc = {
    "plugin": "ucsc-wp-block-dev",
    "plugin_version": opt(os.environ.get("FB_VERSION", "")),
    "category": os.environ.get("FB_CATEGORY", "other"),
    "message": os.environ.get("FB_MESSAGE", ""),
    "skill": opt(os.environ.get("FB_SKILL", "")),
    "target": opt(os.environ.get("FB_TARGET", "")),
    "submitted_at": os.environ.get("FB_TS", ""),
    "context": {
        "platform": opt(os.environ.get("FB_PLATFORM", "")),
        "cwd": opt(os.environ.get("FB_CWD", "")),
        "git_branch": opt(os.environ.get("FB_BRANCH", "")),
    },
}
print(json.dumps(doc, indent=2))
PY

echo "submit-feedback: saved a local copy -> $saved"

if [ "$dry_run" -eq 1 ]; then
  echo "submit-feedback: --dry-run, not sending. Payload:"
  cat "$saved"
  exit 0
fi

# --- deliver: endpoint, else email, else local-only ---
if [ -n "${UCSC_FEEDBACK_ENDPOINT:-}" ]; then
  command -v curl >/dev/null 2>&1 || { echo "submit-feedback: curl is required for the endpoint channel." >&2; exit 2; }
  auth=()
  [ -n "${UCSC_FEEDBACK_TOKEN:-}" ] && auth=(-H "Authorization: Bearer ${UCSC_FEEDBACK_TOKEN}")
  code="$(curl -sS -o /dev/null -w '%{http_code}' -X POST \
    -H 'Content-Type: application/json' "${auth[@]}" \
    --data @"$saved" "$UCSC_FEEDBACK_ENDPOINT" 2>>"$cache/last-error.log")" || {
      echo "submit-feedback: POST failed (see $cache/last-error.log). Local copy kept at $saved." >&2
      exit 1
    }
  if [ "$code" -ge 200 ] && [ "$code" -lt 300 ]; then
    echo "submit-feedback: delivered to endpoint (HTTP $code)."
    exit 0
  fi
  echo "submit-feedback: endpoint returned HTTP $code. Local copy kept at $saved." >&2
  exit 1
fi

if [ -n "${UCSC_FEEDBACK_EMAIL:-}" ]; then
  subject="[ucsc-wp-block-dev feedback] ${category}: $(printf '%s' "$message" | head -c 60)"
  if command -v mail >/dev/null 2>&1; then
    from_args=()
    [ -n "${UCSC_FEEDBACK_FROM:-}" ] && from_args=(-r "$UCSC_FEEDBACK_FROM")
    if mail -s "$subject" "${from_args[@]}" "$UCSC_FEEDBACK_EMAIL" < "$saved"; then
      echo "submit-feedback: emailed to $UCSC_FEEDBACK_EMAIL."
      exit 0
    fi
    echo "submit-feedback: mail command failed. Local copy kept at $saved." >&2
    exit 1
  fi
  echo "submit-feedback: no 'mail' command available. Send the saved payload manually:"
  echo "  to:      $UCSC_FEEDBACK_EMAIL"
  echo "  subject: $subject"
  echo "  body:    $saved"
  exit 0
fi

echo "submit-feedback: no channel configured. Feedback saved locally at:"
echo "  $saved"
echo "Set UCSC_FEEDBACK_ENDPOINT (REST URL) or UCSC_FEEDBACK_EMAIL to deliver automatically."
exit 0
