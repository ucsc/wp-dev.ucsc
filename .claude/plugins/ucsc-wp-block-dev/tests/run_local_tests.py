#!/usr/bin/env python3
import json
import subprocess
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
script_py = ROOT / 'tests' / 'healthcheck.py'
script_sh = ROOT / 'tests' / 'healthcheck.sh'

print('Running local Claude-plugin tests...')
# existence
assert ROOT.exists(), f"Plugin root missing: {ROOT}"
assert script_py.exists(), f"Missing healthcheck.py at {script_py}"
assert script_sh.exists(), f"Missing healthcheck.sh at {script_sh}"
# executability
assert script_sh.stat().st_mode & 0o111, f"healthcheck.sh is not executable: {script_sh}"

# run python healthcheck and parse JSON
proc = subprocess.run([sys.executable, str(script_py)], capture_output=True, text=True)
print('healthcheck.py exitcode=', proc.returncode)
print(proc.stdout)
try:
    report = json.loads(proc.stdout)
except Exception as e:
    print('Failed to parse JSON output from healthcheck.py')
    print(proc.stdout)
    raise

assert 'checks' in report and isinstance(report['checks'], list), 'healthcheck.py output missing checks list'
# Strict: require overall ok == True (no raw-echo matches)
assert report.get('ok') is True, 'Healthcheck reported failures (see JSON output)'

print('All local Claude-plugin tests passed')
