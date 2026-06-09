"""CLI contracts for helper scripts shipped under skills/."""

import os
import subprocess
from pathlib import Path

PLUGIN_ROOT = Path(__file__).resolve().parent.parent
SKILLS_DIR = PLUGIN_ROOT / "skills"


def skill_scripts() -> list[Path]:
    scripts = []
    for suffix in ("*.py", "*.sh"):
        scripts.extend(
            path
            for path in SKILLS_DIR.rglob(suffix)
            if "__pycache__" not in path.parts
        )
    return sorted(scripts)


def plugin_file_snapshot() -> dict[Path, tuple[int, int]]:
    ignored_dirs = {"__pycache__", ".pytest_cache"}
    snapshot = {}
    for path in PLUGIN_ROOT.rglob("*"):
        if not path.is_file():
            continue
        if any(part in ignored_dirs for part in path.parts):
            continue
        stat = path.stat()
        snapshot[path.relative_to(PLUGIN_ROOT)] = (stat.st_size, stat.st_mtime_ns)
    return snapshot


def test_all_skill_scripts_implement_help_without_side_effects():
    scripts = skill_scripts()
    assert scripts, "No skill scripts discovered"

    env = os.environ.copy()
    env["PYTHONDONTWRITEBYTECODE"] = "1"

    before = plugin_file_snapshot()
    failures = []
    for script in scripts:
        result = subprocess.run(
            [str(script), "--help"],
            capture_output=True,
            text=True,
            cwd=str(PLUGIN_ROOT),
            env=env,
            timeout=20,
        )
        output = result.stdout + result.stderr
        if result.returncode != 0:
            failures.append(
                f"{script.relative_to(PLUGIN_ROOT)}: --help exited {result.returncode}\n{output}"
            )
        if "Usage" not in output and "usage" not in output:
            failures.append(
                f"{script.relative_to(PLUGIN_ROOT)}: --help output missing Usage/usage\n{output}"
            )

    after = plugin_file_snapshot()
    changed = [
        str(path)
        for path, metadata in sorted(after.items())
        if before.get(path) != metadata
    ]
    created = [str(path) for path in sorted(set(after) - set(before))]
    deleted = [str(path) for path in sorted(set(before) - set(after))]

    assert not failures, "\n\n".join(failures)
    assert not changed and not created and not deleted, (
        "--help changed plugin files:\n"
        f"  changed: {changed}\n"
        f"  created: {created}\n"
        f"  deleted: {deleted}"
    )
