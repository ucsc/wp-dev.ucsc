# Refactoring Markdown Links After File Moves

When reference files are renamed or moved, markdown links across the plugin
break. The `test_all_markdown_links_resolve` test catches these, but fixing
them one by one is expensive. Use the one-liners below instead.

## Find all files linking to an old path

```bash
grep -rl "old-path-fragment" .claude/plugins/ucsc-wp-block-dev --include="*.md"
```

Replace `old-path-fragment` with a distinctive portion of the old link (e.g.
`references/targets/` or `generate-docs/scripts`).

## Bulk replace a link across all markdown files

```bash
find .claude/plugins/ucsc-wp-block-dev -name "*.md" -print0 \
  | xargs -0 sed -i '' 's|old/path/fragment|new/path/fragment|g'
```

On Linux (no `''` after `-i`):

```bash
find .claude/plugins/ucsc-wp-block-dev -name "*.md" -print0 \
  | xargs -0 sed -i 's|old/path/fragment|new/path/fragment|g'
```

After running, re-run the test suite to confirm no links remain broken:

```bash
cd .claude/plugins/ucsc-wp-block-dev && ../ucsc-wp-block-dev-venv/bin/pytest -q -k "markdown_links"
```

## When to use a script vs manual edits

- **1–3 files affected** — edit manually; grep to confirm nothing was missed.
- **4+ files or a systemic rename** — use the bulk replace above.

The AgentSkills flat-reference rule (ADR: `test_no_deeply_nested_skill_support_files`)
means bulk renames should only be needed during structural refactors, not
routine maintenance.

## Moving a top-level skill to a sub-skill (ADR-081)

When a skill is moved from `skills/<name>/` to `skills/<parent>/<name>/`:

1. **Update relative paths inside the moved SKILL.md** — `../parent/references/` becomes `../references/` (one level closer).
2. **Reference the sub-skill from the parent SKILL.md** — add a `## Sub-workflows` section linking `<name>/SKILL.md`.
3. **Update `sync_inventory.sh` METADATA** — the hardcoded dict still has entries for the old skill name; update or remove them and update the parent skill's `readme`/`hub`/`agents_md` copy. Run `--write` after.
4. **Update `test_plugin_validity.py`** — `test_core_skills_present` has its own hardcoded skill list separate from `test_plugin_structure.py`; both must be updated.
5. **Update hub, README, AGENTS.md, slide deck** — `sync_inventory.sh --write` handles these once METADATA is correct.
6. **Check for prose backtick paths** — `test_all_markdown_links_resolve` only catches markdown hyperlinks (text-plus-href format); backtick prose paths like `` `skill/references/foo.md` `` can silently drift. Run the plugin-validator agent after a structural refactor to catch these.

## Detecting stale prose paths

The automated link test misses paths written as inline code (`` `path/to/file.md` ``) rather than markdown links. After any structural refactor, grep for the old path fragment across all markdown files:

```bash
grep -rn "old/path/fragment" .claude/plugins/ucsc-wp-block-dev --include="*.md"
```
