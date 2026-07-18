#!/usr/bin/env python3
"""Network-wide sweep for WP 7.0 pattern-lock exposure.

Reads site URLs from a comprehensive-report CSV ("Canonical Url" column),
scans every site's pages (read-only, authenticated REST) for
metadata.patternName stamps, and writes:
  - network-sweep_<date>.csv          one row per site (summary)
  - network-sweep-detail_<date>.csv   one row per affected page

Usage:
  python3 network-sweep.py <report-rows.csv> [output-dir]

Output CSVs go to output-dir (default: current directory). Credentials:
WP_USER / WP_APP_PASS from the environment, or from an env file at
$UWP_ENV_FILE (default: .env in the current directory).
"""
import base64
import csv
import json
import os
import re
import sys
import time
import urllib.request
from datetime import date

ENV_FILE = os.environ.get("UWP_ENV_FILE", ".env")
DELAY = float(os.environ.get("SWEEP_DELAY", "0.15"))

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

AUTH = None
PAT_RE = re.compile(r'"patternName":"([^"]+)"')

def get(url):
    global AUTH
    if AUTH is None:
        AUTH = load_auth()
    # The CampusPress WAF rejects python-urllib's default User-Agent.
    req = urllib.request.Request(url, headers={
        "Authorization": f"Basic {AUTH}", "User-Agent": "curl/8.7.1"})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r), r.headers.get("X-WP-TotalPages")

def scan_site(base):
    scanned = 0
    hits = []       # (id, status, link, [patterns])
    page = 1
    while True:
        items, tp = get(f"{base}/wp-json/wp/v2/pages?context=edit&per_page=100&page={page}"
                        f"&status=publish,draft,private,pending&_fields=id,link,status,content.raw")
        for p in items:
            scanned += 1
            names = sorted(set(PAT_RE.findall((p.get("content") or {}).get("raw") or "")))
            if names:
                hits.append((p["id"], p["status"], p["link"], names))
        if not tp or page >= int(tp):
            break
        page += 1
        time.sleep(DELAY)
    return scanned, hits

def main():
    if len(sys.argv) < 2 or sys.argv[1] in ("-h", "--help"):
        print(__doc__.strip())
        sys.exit(0 if len(sys.argv) > 1 else 2)
    src = sys.argv[1]
    outdir = sys.argv[2] if len(sys.argv) > 2 else "."
    os.makedirs(outdir, exist_ok=True)
    tag = date.today().isoformat()
    sites = []
    with open(src, newline="") as f:
        for row in csv.DictReader(f):
            u = (row.get("Canonical Url") or "").strip().rstrip("/")
            if u.startswith("http"):
                sites.append(u)
    print(f"sweeping {len(sites)} sites from {src}")

    sum_path = os.path.join(outdir, f"network-sweep_{tag}.csv")
    det_path = os.path.join(outdir, f"network-sweep-detail_{tag}.csv")
    with open(sum_path, "w", newline="") as sf, open(det_path, "w", newline="") as df:
        sw = csv.writer(sf)
        dw = csv.writer(df)
        sw.writerow(["site", "pages_scanned", "stamped_pages", "pct", "patterns", "error"])
        dw.writerow(["site", "page_id", "status", "link", "patterns"])
        total_sites = affected_sites = total_pages = total_stamped = 0
        for i, site in enumerate(sites, 1):
            host = site.split("//")[-1]
            try:
                scanned, hits = scan_site(site)
                tally = {}
                for _, _, _, names in hits:
                    for n in names:
                        tally[n] = tally.get(n, 0) + 1
                pats = "; ".join(f"{n}={c}" for n, c in sorted(tally.items(), key=lambda x: -x[1]))
                pct = round(100 * len(hits) / scanned, 1) if scanned else 0
                sw.writerow([host, scanned, len(hits), pct, pats, ""])
                for pid, st, link, names in hits:
                    dw.writerow([host, pid, st, link, ",".join(names)])
                total_sites += 1
                total_pages += scanned
                total_stamped += len(hits)
                if hits:
                    affected_sites += 1
                print(f"[{i}/{len(sites)}] {host}: {len(hits)}/{scanned} stamped")
            except Exception as e:
                sw.writerow([host, "", "", "", "", str(e)[:120]])
                print(f"[{i}/{len(sites)}] {host}: ERROR {e}")
            sf.flush(); df.flush()
            time.sleep(DELAY)
    print(f"\nDONE. sites scanned: {total_sites}, sites affected: {affected_sites}, "
          f"pages scanned: {total_pages}, stamped pages: {total_stamped}")
    print(f"summary: {sum_path}\ndetail:  {det_path}")

if __name__ == "__main__":
    main()
