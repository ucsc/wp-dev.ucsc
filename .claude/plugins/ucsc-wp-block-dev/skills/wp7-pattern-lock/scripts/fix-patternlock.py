#!/usr/bin/env python3
"""Remove metadata.patternName stamps from page content so WordPress 7.0
stops treating those blocks as locked pattern instances.

Dry-run by default: fetches, transforms, validates, and reports without
writing. --apply performs the REST update (one revision per page, so each
page is individually revertable via wp-admin revisions).

Usage:
  python3 fix-patternlock.py https://shr.wordpress.ucsc.edu --pages 6597          # dry-run one page
  python3 fix-patternlock.py https://shr.wordpress.ucsc.edu --pages 6597 --apply  # fix one page
  python3 fix-patternlock.py https://shr.wordpress.ucsc.edu --all                 # dry-run every stamped page
  python3 fix-patternlock.py https://shr.wordpress.ucsc.edu --all --apply         # fix every stamped page

Credentials (a WP application password with edit rights on the target site):
set WP_USER and WP_APP_PASS in the environment, or as `WP_USER=...` /
`WP_APP_PASS=...` lines (optional `export ` prefix and quotes) in an env
file at $UWP_ENV_FILE (default: .env in the current directory).

Originals are saved to <PATTERNLOCK_BACKUP_DIR or ./backups>/<host>/<id>.html
before any write. Requires only the Python 3 standard library.
"""
import argparse
import base64
import json
import os
import re
import urllib.request

ENV_FILE = os.environ.get("UWP_ENV_FILE", ".env")

def load_auth():
    env = dict(os.environ)
    if not (env.get("WP_USER") and env.get("WP_APP_PASS")):
        try:
            for line in open(ENV_FILE):
                m = re.match(r'(?:export\s+)?([A-Za-z_]+)=["\']?([^"\']*)["\']?\s*$', line.strip())
                if m:
                    env.setdefault(m.group(1), m.group(2))
        except OSError:
            pass
    if not (env.get("WP_USER") and env.get("WP_APP_PASS")):
        raise SystemExit(
            "missing credentials: set WP_USER and WP_APP_PASS in the "
            f"environment, or in an env file at {ENV_FILE} (see --help)")
    return base64.b64encode(f"{env['WP_USER']}:{env['WP_APP_PASS']}".encode()).decode()

AUTH = None

def request(url, payload=None):
    global AUTH
    if AUTH is None:
        AUTH = load_auth()
    # The CampusPress WAF rejects python-urllib's default User-Agent.
    headers = {"Authorization": f"Basic {AUTH}", "User-Agent": "curl/8.7.1"}
    data = None
    if payload is not None:
        headers["Content-Type"] = "application/json"
        data = json.dumps(payload).encode()
    req = urllib.request.Request(url, data=data, headers=headers)
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.load(r), r.headers

# --- block-comment JSON surgery -------------------------------------------

OPEN_RE = re.compile(r'<!--\s+wp:[a-z][\w/-]*\s+\{')

def find_json_span(text, start):
    """Return (start, end) of the JSON object beginning at text[start] == '{'."""
    depth = 0
    i = start
    in_str = False
    while i < len(text):
        c = text[i]
        if in_str:
            if c == "\\":
                i += 2
                continue
            if c == '"':
                in_str = False
        else:
            if c == '"':
                in_str = True
            elif c == "{":
                depth += 1
            elif c == "}":
                depth -= 1
                if depth == 0:
                    return start, i + 1
        i += 1
    raise ValueError("unterminated block-comment JSON")

def wp_json_encode(attrs):
    """Match WP serialize_block_attributes() encoding."""
    s = json.dumps(attrs, ensure_ascii=False, separators=(",", ":"))
    s = s.replace("--", "\\u002d\\u002d")
    s = s.replace("<", "\\u003c").replace(">", "\\u003e").replace("&", "\\u0026")
    s = s.replace('\\"', "\\u0022")
    return s

def strip_pattern_stamps(raw):
    """Remove metadata.patternName (and metadata if emptied) from every block
    comment. Returns (new_raw, n_changed)."""
    out = []
    pos = 0
    changed = 0
    for m in OPEN_RE.finditer(raw):
        jstart = m.end() - 1
        if jstart < pos:
            continue  # inside a previously handled span (overlap safety)
        jstart_, jend = find_json_span(raw, jstart)
        attrs = json.loads(raw[jstart_:jend])
        meta = attrs.get("metadata")
        if isinstance(meta, dict) and "patternName" in meta:
            del meta["patternName"]
            if not meta:
                del attrs["metadata"]
            out.append(raw[pos:jstart_])
            out.append(wp_json_encode(attrs))
            pos = jend
            changed += 1
    out.append(raw[pos:])
    return "".join(out), changed

def validate(new_raw):
    """Every block comment in the result must still parse as JSON and no
    patternName may remain."""
    for m in OPEN_RE.finditer(new_raw):
        s, e = find_json_span(new_raw, m.end() - 1)
        json.loads(new_raw[s:e])
    return '"patternName"' not in new_raw

# --- main -------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("site")
    ap.add_argument("--pages", help="comma-separated page IDs")
    ap.add_argument("--all", action="store_true", help="scan for all stamped pages")
    ap.add_argument("--apply", action="store_true", help="write changes (default: dry-run)")
    args = ap.parse_args()
    site = args.site.rstrip("/")
    host = site.split("//")[-1]

    ids = []
    if args.pages:
        ids = [int(x) for x in args.pages.split(",")]
    elif args.all:
        page = 1
        while True:
            items, hdrs = request(
                f"{site}/wp-json/wp/v2/pages?context=edit&per_page=100&page={page}"
                f"&status=publish,draft,private,pending&_fields=id,content.raw")
            ids += [p["id"] for p in items if '"patternName"' in ((p.get("content") or {}).get("raw") or "")]
            tp = hdrs.get("X-WP-TotalPages")
            if not tp or page >= int(tp):
                break
            page += 1
        print(f"found {len(ids)} stamped pages")
    else:
        ap.error("need --pages or --all")

    # Backups hold production page content — keep them out of any repo.
    backup_root = os.environ.get("PATTERNLOCK_BACKUP_DIR", "backups")
    backup_dir = os.path.join(backup_root, host)
    os.makedirs(backup_dir, exist_ok=True)
    ok = failed = 0
    for pid in ids:
        try:
            p, _ = request(f"{site}/wp-json/wp/v2/pages/{pid}?context=edit&_fields=id,link,content.raw")
            raw = p["content"]["raw"]
            new_raw, changed = strip_pattern_stamps(raw)
            if not changed:
                print(f"  {pid}: no stamps found, skipping")
                continue
            if not validate(new_raw):
                raise ValueError("validation failed (patternName remains)")
            delta = len(raw) - len(new_raw)
            if args.apply:
                with open(os.path.join(backup_dir, f"{pid}.html"), "w") as f:
                    f.write(raw)
                request(f"{site}/wp-json/wp/v2/pages/{pid}", {"content": new_raw})
                print(f"  {pid}: APPLIED  {changed} stamp(s) removed, -{delta} bytes  {p['link']}")
            else:
                print(f"  {pid}: DRY-RUN  {changed} stamp(s) would be removed, -{delta} bytes, JSON valid  {p['link']}")
            ok += 1
        except Exception as e:
            failed += 1
            print(f"  {pid}: FAILED  {e}")
    print(f"\n{'applied' if args.apply else 'dry-run ok'}: {ok}, failed: {failed}")

if __name__ == "__main__":
    main()
