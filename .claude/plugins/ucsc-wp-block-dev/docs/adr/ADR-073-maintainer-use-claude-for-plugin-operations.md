---
title: "ADR-073: Always use .claude for plugin operations; ignore .agents config"
status: Accepted
date: 2026-06-17
---

# ADR-073: Always use .claude for plugin operations; ignore .agents config

## Status

Accepted

## Context

The repository contains two directories that could be used for Claude Code plugin/agent configuration: `.claude/` and `.agents/`. The `.agents/` directory holds legacy or parallel config (e.g., `api_signature.json`, `monitor_api.py`) that is unrelated to the Claude Code plugin system. Keeping both in scope creates confusion about which config is authoritative for plugin operations such as skill invocation, hook execution, manifest validation, and publishing.

## Decision

All plugin operations — skill authoring, agent definitions, hook configuration, manifest (`plugin.json`), scripts, tests, and publishing — are performed exclusively under `.claude/plugins/ucsc-wp-block-dev/`. The `.agents/` directory and any files within it are out of scope for this plugin's maintenance workflow and must not be read, modified, or referenced during plugin operations.

## Consequences

- **Positive:** Single authoritative location for all plugin config eliminates ambiguity and prevents accidental cross-contamination between the Claude Code plugin system and legacy agent tooling.
- **Negative:** Maintainers must be aware that `.agents/` exists but is intentionally ignored; no automatic enforcement prevents someone from editing it during a plugin session.
