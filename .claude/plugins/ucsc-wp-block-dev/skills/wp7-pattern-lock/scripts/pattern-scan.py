#!/usr/bin/env python3
"""Scan a CampusPress site for pages whose content carries pattern-instance
metadata (metadata.patternName), which WP 7.0 locks to content-only editing.
Read-only: GET requests only.

Usage: python3 pattern-scan.py <site-url>

Credentials: WP_USER / WP_APP_PASS from the environment, or from an env file
at $UWP_ENV_FILE (default: .env in the current directory)."""
import base64
import json
import os
import re
import sys
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
            f"environment, or in an env file at {ENV_FILE}")
    return base64.b64encode(f"{env['WP_USER']}:{env['WP_APP_PASS']}".encode()).decode()

if len(sys.argv) < 2 or sys.argv[1] in ("-h", "--help"):
    print(__doc__.strip())
    sys.exit(0 if len(sys.argv) > 1 else 2)
SITE = sys.argv[1].rstrip("/")
auth = load_auth()

def get(url):
    # The CampusPress WAF rejects python-urllib's default User-Agent.
    req = urllib.request.Request(url, headers={
        "Authorization": f"Basic {auth}",
        "User-Agent": "curl/8.7.1",
    })
    with urllib.request.urlopen(req, timeout=30) as r:
        total_pages = r.headers.get("X-WP-TotalPages")
        return json.load(r), total_pages

pat_re = re.compile(r'"patternName":"([^"]+)"')
hits = []
page = 1
scanned = 0
while True:
    url = (f"{SITE}/wp-json/wp/v2/pages?context=edit&per_page=100&page={page}"
           f"&status=publish,draft,private,pending&_fields=id,link,status,content.raw")
    try:
        items, tp = get(url)
    except Exception as e:
        if page == 1:
            print(f"ERROR fetching {SITE}: {e}")
            sys.exit(1)
        break
    for p in items:
        scanned += 1
        raw = (p.get("content") or {}).get("raw") or ""
        names = pat_re.findall(raw)
        if names:
            hits.append((p["id"], p["status"], p["link"], sorted(set(names))))
    if not tp or page >= int(tp):
        break
    page += 1

print(f"site: {SITE}")
print(f"pages scanned (publish/draft/private/pending): {scanned}")
print(f"pages carrying patternName metadata (WP7-locked): {len(hits)}")
tally = {}
for _, _, _, names in hits:
    for n in names:
        tally[n] = tally.get(n, 0) + 1
print("\npattern usage counts:")
for n, c in sorted(tally.items(), key=lambda x: -x[1]):
    print(f"  {c:4d}  {n}")
print("\naffected pages:")
for pid, status, link, names in hits:
    print(f"  {pid:6d}  {status:8s}  {link}  <- {','.join(names)}")

# Resolve wp_block posts referenced as core/block/<id> so the report names them
ids = sorted({int(n.split("/")[-1]) for n in tally if n.startswith("core/block/")})
if ids:
    print("\nreferenced site patterns (wp_block posts):")
    for bid in ids:
        try:
            b, _ = get(f"{SITE}/wp-json/wp/v2/blocks/{bid}?context=edit&_fields=id,title,meta")
            sync = (b.get("meta") or {}).get("wp_pattern_sync_status", "?")
            print(f"  {bid}: \"{(b.get('title') or {}).get('raw','?')}\"  sync_status={sync or 'synced'}")
        except Exception as e:
            print(f"  {bid}: lookup failed ({e})")
