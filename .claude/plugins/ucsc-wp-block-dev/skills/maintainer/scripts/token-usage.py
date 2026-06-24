#!/usr/bin/env python3
"""Record and summarize per-user token-heavy plugin operations."""

from __future__ import annotations

import argparse
import os
from collections import Counter
from datetime import datetime
from pathlib import Path


def cache_dir() -> Path:
    override = os.environ.get("UCSC_WP_BLOCK_DEV_CACHE")
    if override:
        return Path(override).expanduser()

    xdg_cache = os.environ.get("XDG_CACHE_HOME")
    if xdg_cache:
        return Path(xdg_cache).expanduser() / "ucsc-wp-block-dev"

    return Path.home() / ".cache" / "ucsc-wp-block-dev"


def log_path() -> Path:
    return cache_dir() / "token-usage.log"


def append_entry(operation: str, notes: str) -> None:
    path = log_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now().astimezone().strftime("%Y-%m-%d %H:%M")
    line = f"{timestamp}  {operation:<14}  {notes.strip()}\n"
    with path.open("a", encoding="utf-8") as handle:
        handle.write(line)
    print(path)


def report_entries() -> None:
    path = log_path()
    print(f"token usage log: {path}")
    if not path.exists():
        print("entries: 0")
        return

    lines = [line.rstrip() for line in path.read_text(encoding="utf-8").splitlines()]
    lines = [line for line in lines if line]
    operations = Counter()
    for line in lines:
        parts = line.split()
        if len(parts) >= 3:
            operations[parts[2]] += 1

    print(f"entries: {len(lines)}")
    for operation, count in sorted(operations.items()):
        print(f"{operation}: {count}")
    if lines:
        print("recent:")
        for line in lines[-10:]:
            print(f"  {line}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Record or summarize user-specific ucsc-wp-block-dev token usage."
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    append_parser = subparsers.add_parser("append", help="append one operation")
    append_parser.add_argument("operation")
    append_parser.add_argument("notes", nargs="?", default="")

    subparsers.add_parser("report", help="summarize the current user's log")
    subparsers.add_parser("path", help="print the current user's log path")

    args = parser.parse_args()
    if args.command == "append":
        append_entry(args.operation, args.notes)
    elif args.command == "report":
        report_entries()
    else:
        print(log_path())


if __name__ == "__main__":
    main()
