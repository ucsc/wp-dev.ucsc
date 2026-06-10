# ADR-017: .agents uses symlinks to .claude, not file copies

**Status:** Accepted
**Date:** 2026-06-10

## Context

The `.agents/` directory exists to provide a Codex-compatible adapter for the plugin. Previously, `codex.sh` used `rsync --delete` to copy all skills from `.claude/plugins/ucsc-wp-block-dev/skills/` into `.agents/plugins/ucsc-wp-block-dev/skills/`, and these copies were checked into git. This created two problems:

1. **Drift.** Every skill edit had to be synced to `.agents`, and forgetting to sync caused Codex to serve stale instructions.
2. **Noise.** Every skill change produced duplicate diffs — one in `.claude` (the source of truth) and one in `.agents` (the copy).

## Decision

1. **`.claude/` is the single source of truth** for all skills, scripts, hooks, and docs. No skill content lives in `.agents/`.

2. **`.agents/plugins/<name>/skills/` uses symlinks** pointing to the corresponding `.claude/plugins/<name>/skills/` directories. The symlinks are created by `codex.sh` and are not checked into git.

3. **Do not check in symlinks.** Symlinks are platform-specific and break across clones on different OS/path layouts. `.agents/plugins/<name>/skills/` is gitignored, and `codex.sh` recreates the symlinks on demand.

4. **What stays in `.agents/` (tracked):**
   - `codex.sh` — the adapter script itself
   - `.codex-plugin/plugin.json` — the Codex-specific manifest (different format from `.claude-plugin/plugin.json`)
   - `plugins/marketplace.json` — the local marketplace definition
   - Any Codex-only files that have no `.claude` equivalent

## Migration

```bash
# Remove tracked copies from git (does not delete working-tree files)
git rm -r --cached .agents/plugins/ucsc-wp-block-dev/skills/

# Add gitignore entry
echo '.agents/plugins/ucsc-wp-block-dev/skills/' >> .gitignore

# Recreate as symlinks
rm -rf .agents/plugins/ucsc-wp-block-dev/skills
ln -s ../../../.claude/plugins/ucsc-wp-block-dev/skills .agents/plugins/ucsc-wp-block-dev/skills
```

## Consequences

- One source of truth eliminates sync drift.
- Skill diffs appear only once in PRs.
- `codex.sh` becomes simpler — symlink creation replaces rsync.
- Contributors must run `codex.sh` after cloning to set up the symlinks (or Codex won't find skills).
