#!/usr/bin/env python3
"""
Lightweight healthcheck helper for ucsc-wp-block-dev plugin.
Produces a short JSON report for automation.
"""
import json
import os
import sys
from pathlib import Path

# Resolve relative to this file (repo root is 4 levels up:
# <repo>/.claude/plugins/ucsc-wp-block-dev/<scripts|tests>/healthcheck.py); env
# override wins. Never hardcode a developer's absolute home path.
_REPO_ROOT = Path(__file__).resolve().parents[4]
PLUGIN_DIR = Path(
    os.environ.get(
        "UCSC_HEALTHCHECK_PLUGIN_DIR",
        str(_REPO_ROOT / "public/wp-content/plugins/ucsc-gutenberg-blocks"),
    )
)
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

# Print JSON report and enforce strict failure on raw-echo matches
output = json.dumps(report, indent=2)
print(output)
for c in report.get('checks', []):
    if c.get('name') == 'raw_echo_var' and c.get('matches'):
        # strict enforcement: fail when any raw-echo patterns are found
        sys.exit(2)
# otherwise success
sys.exit(0)
