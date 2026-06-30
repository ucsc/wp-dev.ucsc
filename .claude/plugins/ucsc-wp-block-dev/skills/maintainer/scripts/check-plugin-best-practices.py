#!/usr/bin/env python3
# implements: ADR-078-MAINTAINER-CLI-VALIDATE
"""Deterministic plugin best-practice checks used by maintainer self-test."""

from __future__ import annotations

import argparse
import json
import os
import re
import stat
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any


UPSTREAM = "https://github.com/anthropics/claude-code/tree/main/plugins/plugin-dev"
SKILL_CREATOR_UPSTREAM = (
    "https://github.com/anthropics/skills/tree/main/skills/skill-creator"
)
PLUGIN_COLLECTION_UPSTREAM = "https://github.com/anthropics/claude-code/tree/main/plugins"
PATTERN_PLUGINS = (
    "example-plugin",
    "feature-dev",
    "hookify",
    "security-guidance",
    "code-review",
    "pr-review-toolkit",
    "commit-commands",
    "code-simplifier",
    "session-report",
    "claude-md-management",
    "plugin-dev",
    "skill-creator",
)
RECOMMENDED_MANIFEST_FIELDS = {
    "name",
    "version",
    "description",
    "author",
    "repository",
    "homepage",
    "license",
}
JUNK_NAMES = {".DS_Store", "node_modules", "__pycache__", ".pytest_cache"}
KEBAB_CASE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
SEMVER = re.compile(r"^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$")
SECRET_PATTERNS = {
    "private-key": re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"),
    "github-token": re.compile(r"\bgh[oprsu]_[A-Za-z0-9_]{30,}\b"),
    "anthropic-key": re.compile(r"\bsk-ant-[A-Za-z0-9_-]{20,}\b"),
}


@dataclass(frozen=True)
class Finding:
    severity: str
    code: str
    path: str
    message: str


def parse_frontmatter(path: Path) -> tuple[dict[str, str], str]:
    text = path.read_text(errors="replace")
    match = re.match(r"^---\n(.*?)\n---\n?(.*)$", text, re.DOTALL)
    if not match:
        return {}, text

    values: dict[str, str] = {}
    for line in match.group(1).splitlines():
        if not line or line[0].isspace() or ":" not in line:
            continue
        key, _, value = line.partition(":")
        values[key.strip()] = value.strip().strip("\"'")
    return values, match.group(2)


def relative(path: Path, root: Path) -> str:
    try:
        return str(path.relative_to(root))
    except ValueError:
        return str(path)


def audit(root: Path) -> list[Finding]:
    findings: list[Finding] = []

    def add(severity: str, code: str, path: Path | str, message: str) -> None:
        rendered = relative(path, root) if isinstance(path, Path) else path
        findings.append(Finding(severity, code, rendered, message))

    manifest_path = root / ".claude-plugin" / "plugin.json"
    manifest: dict = {}
    if not manifest_path.exists():
        add("ERROR", "manifest-missing", manifest_path, "Required plugin manifest is missing.")
    else:
        try:
            manifest = json.loads(manifest_path.read_text())
        except json.JSONDecodeError as exc:
            add("ERROR", "manifest-json", manifest_path, f"Invalid JSON: {exc.msg}.")

    if manifest:
        name = manifest.get("name")
        if not isinstance(name, str) or not KEBAB_CASE.fullmatch(name):
            add("ERROR", "manifest-name", manifest_path, "Plugin name must be non-empty kebab-case.")

        version = manifest.get("version")
        if version is not None and (
            not isinstance(version, str) or not SEMVER.fullmatch(version)
        ):
            add("ERROR", "manifest-version", manifest_path, "Version must use semantic versioning.")

        for field in sorted(RECOMMENDED_MANIFEST_FIELDS - set(manifest)):
            add("WARN", "manifest-recommended", manifest_path, f"Recommended field '{field}' is missing.")

        author = manifest.get("author")
        if author is not None and not (
            isinstance(author, str)
            or (
                isinstance(author, dict)
                and isinstance(author.get("name"), str)
                and bool(author["name"].strip())
            )
        ):
            add("ERROR", "manifest-author", manifest_path, "Author must be a string or object with a name.")

    for component in ("commands", "agents", "skills", "hooks"):
        misplaced = root / ".claude-plugin" / component
        if misplaced.exists():
            add(
                "ERROR",
                "component-placement",
                misplaced,
                f"Move '{component}' to the plugin root for auto-discovery.",
            )

    if not (root / "README.md").exists():
        add("WARN", "readme-missing", root / "README.md", "Add installation, usage, and test guidance.")
    if not (root / "LICENSE").exists():
        add("WARN", "license-missing", root / "LICENSE", "Add the license file named by the manifest.")

    skills_dir = root / "skills"
    if skills_dir.exists():
        for skill_path in sorted(skills_dir.rglob("SKILL.md")):
            frontmatter, body = parse_frontmatter(skill_path)
            skill_dir = skill_path.parent
            name = frontmatter.get("name", "")
            description = frontmatter.get("description", "")

            if not frontmatter:
                add("ERROR", "skill-frontmatter", skill_path, "SKILL.md needs YAML frontmatter.")
                continue
            if not name:
                add("ERROR", "skill-name", skill_path, "Frontmatter requires a name.")
            elif name != skill_dir.name:
                add(
                    "ERROR",
                    "skill-name-directory",
                    skill_path,
                    f"Skill name '{name}' must match directory '{skill_dir.name}'.",
                )
            if not KEBAB_CASE.fullmatch(skill_dir.name):
                add("ERROR", "skill-directory-name", skill_dir, "Skill directory must use kebab-case.")

            if not description:
                add("ERROR", "skill-description", skill_path, "Frontmatter requires a description.")
            else:
                if len(description) < 50:
                    add("WARN", "skill-description-short", skill_path, "Description is under 50 characters.")
                if len(description) > 500:
                    add("WARN", "skill-description-long", skill_path, "Description exceeds 500 characters.")
                trigger_markers = ('"', "when", "use for", "use when", "asked to")
                if not any(marker in description.lower() for marker in trigger_markers):
                    add(
                        "WARN",
                        "skill-trigger-clarity",
                        skill_path,
                        "Describe concrete requests or contexts that should trigger the skill.",
                    )

            word_count = len(re.findall(r"\b[\w'-]+\b", body))
            line_count = len(body.splitlines())
            if word_count > 3000:
                add(
                    "WARN",
                    "skill-progressive-disclosure",
                    skill_path,
                    f"Body is {word_count} words; move detail to references when practical.",
                )
            if line_count > 500:
                add(
                    "WARN",
                    "skill-line-budget",
                    skill_path,
                    f"Body is {line_count} lines; skill-creator recommends under 500 when practical.",
                )
            if word_count < 20:
                add("WARN", "skill-body-short", skill_path, "Skill body is unusually short.")

            for scripts_dir in (skill_dir / "scripts", skill_dir / "examples"):
                if not scripts_dir.exists():
                    continue
                for script in scripts_dir.rglob("*"):
                    if not script.is_file() or script.suffix not in {".sh", ".py", ".js"}:
                        continue
                    if not script.stat().st_mode & stat.S_IXUSR:
                        add(
                            "WARN",
                            "script-not-executable",
                            script,
                            "Executable helper lacks the user execute bit.",
                        )

    def is_tracked(path: Path) -> bool:
        result = subprocess.run(
            ["git", "-C", str(root), "ls-files", "--error-unmatch", "--", relative(path, root)],
            capture_output=True,
            text=True,
        )
        return result.returncode == 0

    files: list[Path] = []
    for current, dirnames, filenames in os.walk(root):
        current_path = Path(current)
        for dirname in list(dirnames):
            candidate = current_path / dirname
            if dirname in JUNK_NAMES:
                if is_tracked(candidate):
                    add("ERROR", "junk-file", candidate, f"Remove tracked generated '{dirname}'.")
                dirnames.remove(dirname)
        files.extend(current_path / filename for filename in filenames)

    for path in sorted(files):
        if path.name in JUNK_NAMES and is_tracked(path):
            add("ERROR", "junk-file", path, f"Remove tracked generated '{path.name}'.")
        if path.stat().st_size > 2_000_000:
            continue
        try:
            text = path.read_text(errors="ignore")
        except OSError:
            continue
        for code, pattern in SECRET_PATTERNS.items():
            if pattern.search(text):
                add("ERROR", f"secret-{code}", path, "Possible committed credential or private key.")

    return findings


def resolve_source(path: Path, source_name: str, marker: Path) -> Path:
    """Accept a source directory, its common parent, or its repository root."""
    direct = path.resolve()
    candidates = (
        direct,
        direct / source_name,
        direct / "plugins" / source_name,
        direct / "skills" / source_name,
    )
    for candidate in candidates:
        if (candidate / marker).exists():
            return candidate
    return direct


def source_metadata(
    source: Path | None,
    source_name: str,
    marker: Path,
    required_paths: tuple[Path, ...],
) -> dict[str, str] | None:
    if source is None:
        return None
    resolved = resolve_source(source, source_name, marker)
    metadata = {"path": str(resolved), "status": "available" if resolved.exists() else "missing"}
    if not resolved.exists():
        return metadata

    required = tuple(resolved / path for path in required_paths)
    metadata["status"] = "available" if all(path.exists() for path in required) else "incomplete"

    result = subprocess.run(
        ["git", "-C", str(resolved), "rev-parse", "HEAD"],
        capture_output=True,
        text=True,
    )
    if result.returncode == 0:
        metadata["commit"] = result.stdout.strip()
    return metadata


def resolve_plugin_collection(path: Path) -> Path:
    direct = path.resolve()
    candidates = (direct, direct / "plugins")
    for candidate in candidates:
        if (candidate / "plugin-dev").is_dir() and (candidate / "feature-dev").is_dir():
            return candidate
    return direct


def plugin_collection_metadata(source: Path | None) -> dict[str, Any] | None:
    if source is None:
        return None
    resolved = resolve_plugin_collection(source)
    metadata: dict[str, Any] = {
        "path": str(resolved),
        "status": "available" if resolved.exists() else "missing",
    }
    if not resolved.exists():
        return metadata

    plugins = sorted(path.name for path in resolved.iterdir() if path.is_dir())
    metadata["plugin_count"] = len(plugins)
    metadata["plugins"] = plugins
    metadata["pattern_plugins"] = {
        name: "available" if name in plugins else "missing" for name in PATTERN_PLUGINS
    }
    metadata["status"] = (
        "available"
        if all(status == "available" for status in metadata["pattern_plugins"].values())
        else "incomplete"
    )

    result = subprocess.run(
        ["git", "-C", str(resolved), "rev-parse", "HEAD"],
        capture_output=True,
        text=True,
    )
    if result.returncode == 0:
        metadata["commit"] = result.stdout.strip()
    return metadata


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Check a Claude Code plugin using deterministic rules adapted from upstream examples."
    )
    parser.add_argument(
        "--plugin-root",
        type=Path,
        default=Path(__file__).resolve().parents[3],
        help="Plugin root containing .claude-plugin/plugin.json.",
    )
    parser.add_argument(
        "--strict-warnings",
        action="store_true",
        help="Return non-zero when warnings are present.",
    )
    parser.add_argument(
        "--plugin-dev-source",
        type=Path,
        default=Path(os.environ["PLUGIN_DEV_SOURCE"]) if os.environ.get("PLUGIN_DEV_SOURCE") else None,
        help="Optional local plugin-dev checkout or parent repository (also PLUGIN_DEV_SOURCE).",
    )
    parser.add_argument(
        "--skill-creator-source",
        type=Path,
        default=Path(os.environ["SKILL_CREATOR_SOURCE"]) if os.environ.get("SKILL_CREATOR_SOURCE") else None,
        help="Optional local skill-creator checkout or parent repository (also SKILL_CREATOR_SOURCE).",
    )
    parser.add_argument(
        "--plugin-collection-source",
        type=Path,
        default=Path(os.environ["CLAUDE_PLUGINS_SOURCE"]) if os.environ.get("CLAUDE_PLUGINS_SOURCE") else None,
        help="Optional local Anthropic plugins directory or repository root (also CLAUDE_PLUGINS_SOURCE).",
    )
    parser.add_argument("--json", action="store_true", help="Print a JSON report.")
    args = parser.parse_args()

    root = args.plugin_root.resolve()
    findings = audit(root)
    plugin_dev_source = source_metadata(
        args.plugin_dev_source,
        "plugin-dev",
        Path("agents/plugin-validator.md"),
        (
            Path("agents/plugin-validator.md"),
            Path("agents/skill-reviewer.md"),
            Path("skills/plugin-structure/SKILL.md"),
            Path("skills/skill-development/SKILL.md"),
        ),
    )
    skill_creator_source = source_metadata(
        args.skill_creator_source,
        "skill-creator",
        Path("SKILL.md"),
        (
            Path("SKILL.md"),
            Path("references/schemas.md"),
            Path("scripts/quick_validate.py"),
            Path("scripts/run_eval.py"),
        ),
    )
    plugin_collection_source = plugin_collection_metadata(args.plugin_collection_source)
    errors = [finding for finding in findings if finding.severity == "ERROR"]
    warnings = [finding for finding in findings if finding.severity == "WARN"]

    if args.json:
        print(
            json.dumps(
                {
                    "plugin_root": str(root),
                    "upstream": UPSTREAM,
                    "skill_creator_upstream": SKILL_CREATOR_UPSTREAM,
                    "plugin_collection_upstream": PLUGIN_COLLECTION_UPSTREAM,
                    "plugin_dev_source": plugin_dev_source,
                    "skill_creator_source": skill_creator_source,
                    "plugin_collection_source": plugin_collection_source,
                    "errors": len(errors),
                    "warnings": len(warnings),
                    "findings": [finding.__dict__ for finding in findings],
                },
                indent=2,
            )
        )
    else:
        print(f"plugin best-practice checks: {root}")
        print(f"upstream: {UPSTREAM}")
        print(f"skill-creator upstream: {SKILL_CREATOR_UPSTREAM}")
        print(f"plugin collection upstream: {PLUGIN_COLLECTION_UPSTREAM}")
        for label, source in (
            ("plugin-dev source", plugin_dev_source),
            ("skill-creator source", skill_creator_source),
        ):
            if source:
                commit = f" @ {source['commit'][:12]}" if source.get("commit") else ""
                print(f"{label}: {source['path']} ({source['status']}{commit})")
        if plugin_collection_source:
            commit = (
                f" @ {plugin_collection_source['commit'][:12]}"
                if plugin_collection_source.get("commit")
                else ""
            )
            count = plugin_collection_source.get("plugin_count", 0)
            print(
                "plugin collection source: "
                f"{plugin_collection_source['path']} "
                f"({plugin_collection_source['status']}{commit}; {count} plugins)"
            )
        for finding in findings:
            print(f"{finding.severity} [{finding.code}] {finding.path}: {finding.message}")
        result = "PASS" if not errors and not (args.strict_warnings and warnings) else "FAIL"
        print(f"RESULT: {result} ({len(errors)} errors, {len(warnings)} warnings)")

    return 1 if errors or (args.strict_warnings and warnings) else 0


if __name__ == "__main__":
    sys.exit(main())
