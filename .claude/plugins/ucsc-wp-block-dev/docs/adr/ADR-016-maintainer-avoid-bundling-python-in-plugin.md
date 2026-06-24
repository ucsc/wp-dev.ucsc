---
title: "ADR-016: Avoid bundling Python dependencies in the plugin"
status: Accepted
date: 2026-06-10
---

# ADR-016: Avoid bundling Python dependencies in the plugin

**Status:** Accepted
**Date:** 2026-06-10

## Context

Claude Code plugins are distributed as lightweight skill and script bundles. Bundling Python virtual environments, pip packages, or compiled artifacts inflates the plugin, creates platform-specific portability issues, and complicates marketplace distribution. The plugin currently has only a `requirements-dev.txt` (pytest for tests) and the publish script's dependencies are auto-installed into a `.venv` outside the plugin tree.

## Decision

1. **No pip dependencies in the plugin tree.** Python scripts bundled in the plugin must use only the Python standard library. Third-party imports (e.g., `google-api-python-client`, `markdown`) belong in scripts that manage their own venv outside the plugin directory.

2. **Venvs are gitignored and user-local.** Virtual environments (`.venv/`, `*-venv/`) are excluded via `.gitignore` and never committed or distributed.

3. **`requirements-dev.txt` is for local development only.** It lists test dependencies (pytest) that developers install into a venv outside the plugin root. It is not a runtime dependency manifest.

4. **Credentials and tokens are never committed.** Service account JSON, OAuth credentials, and token files are gitignored at every level where a publish script may run.

## What is allowed

- Python scripts using only the stdlib (os, sys, json, re, pathlib, subprocess, argparse, etc.).
- A `requirements-dev.txt` for test tooling, installed outside the plugin tree.
- Scripts that self-bootstrap a venv for their own dependencies (like `publish_to_gdoc.py`), as long as the venv is gitignored and outside the distributed plugin.

## Consequences

- The plugin stays lean and portable across platforms.
- Users need Python 3 available on their system but no pre-installed packages.
- Publish and test workflows document their own setup steps.
