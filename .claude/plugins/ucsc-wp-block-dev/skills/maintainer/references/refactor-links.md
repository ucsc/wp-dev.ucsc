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
