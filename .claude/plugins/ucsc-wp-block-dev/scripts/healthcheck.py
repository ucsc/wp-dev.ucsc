#!/usr/bin/env python3
"""
Lightweight healthcheck helper for ucsc-wp-block-dev plugin.
Produces a short JSON report for automation.
"""
import json
import os
from pathlib import Path

PLUGIN_DIR = Path("/Users/henryh/_code/_campuspress/wp-dev.ucsc/public/wp-content/plugins/ucsc-gutenberg-blocks")
report = {"ok": True, "checks": []}

if not PLUGIN_DIR.exists():
    report["ok"] = False
    report["checks"].append({"name": "plugin_dir", "ok": False, "msg": f"Missing {PLUGIN_DIR}"})
else:
    report["checks"].append({"name": "plugin_dir", "ok": True, "msg": str(PLUGIN_DIR)})

# files
files_to_check = ["templates/CampusDirectoryTemplate.php", "tests/run_manual_test.php", "tests/phpunit/CampusDirectoryTemplateTest.php"]
for f in files_to_check:
    p = PLUGIN_DIR / f
    ok = p.exists()
    report["checks"].append({"name": f, "ok": ok, "path": str(p)})
    if not ok:
        report["ok"] = False

# simple pattern scans
import re
patterns = {
    "permissive_rest": re.compile(r"permission_callback.*__return_true"),
    "raw_echo_var": re.compile(r"echo .*\$"),
}
for name, pat in patterns.items():
    matches = []
    if PLUGIN_DIR.exists():
        for p in PLUGIN_DIR.rglob("*.php"):
            try:
                txt = p.read_text(errors="ignore")
            except Exception:
                continue
            if pat.search(txt):
                matches.append(str(p))
    report["checks"].append({"name": name, "ok": len(matches)==0, "matches": matches})
    if matches:
        report["ok"] = False

# try to run manual php test locally (non-fatal)
manual = PLUGIN_DIR / "tests/run_manual_test.php"
if manual.exists() and os.system("php --version >/dev/null 2>&1") == 0:
    rc = os.system(f"php {manual}")
    report["checks"].append({"name": "run_manual_test_local", "ok": rc==0, "rc": rc})
else:
    report["checks"].append({"name": "run_manual_test_local", "ok": False, "msg": "php or manual test missing"})

print(json.dumps(report, indent=2))
