---
title: "ADR-095: Resolve a source base and use reusable inspection scripts instead of hardcoded paths and ad-hoc find"
status: Accepted
date: 2026-06-23
---

# ADR-095: Resolve a source base and use reusable inspection scripts instead of hardcoded paths and ad-hoc find

## Status

Accepted

## Context

Skill sessions repeatedly produce inline shell snippets like:

```bash
base=/abs/path/to/wp-dev.ucsc/public/wp-content/plugins/ucsc-gutenberg-blocks
ls -la "$base" | head -30
find "$base" -name block.json -not -path '*/node_modules/*' | head -20
```

This pattern has three problems:

1. **Hardcoded absolute paths.** The `base=` line bakes in one developer's
   checkout location. It is not portable, drifts when the repo moves, and
   duplicates knowledge the harness already has.
2. **No shared notion of the source base.** Each snippet re-derives where the
   wp-dev.ucsc repo root, the `.claude` plugin dir, the WordPress plugins dir, and
   each block plugin live, instead of resolving them once.
3. **Ad-hoc, unsafe exploration.** Free-hand `find`/`ls` with unquoted globs or
   patterns can glob-expand in the calling shell before the command runs, and the
   logic is re-typed (and re-broken) each time.

ADR-094 established `${CLAUDE_PLUGIN_ROOT}`-based commands and wrapper scripts.
This ADR extends that to the *project* side: a resolvable source base and reusable
inspection scripts.

## Decision

**Resolve the source base through a script; do not hardcode paths or hand-roll
exploration in skill commands.**

1. **Source base resolver** — `skills/develop/scripts/source-base.sh` is the one
   authority for the canonical roots:
   - `repo-root` — the wp-dev.ucsc repository root
   - `plugin-root` — this Claude plugin (`.claude/plugins/ucsc-wp-block-dev`)
   - `wp-plugins` — `<repo>/public/wp-content/plugins`
   - `plugin-dir <slug>` — a specific block plugin (`ucsc-blocks`,
     `ucsc-gutenberg-blocks`)

   It self-locates via `${BASH_SOURCE[0]}` and walks up from
   `$WP_DEV_ROOT` / `$CLAUDE_PROJECT_DIR` / `$CLAUDE_PLUGIN_ROOT` / `$PWD` to the
   dir holding both `public/wp-content/plugins` and `docker-compose.yml`, so it
   works without any hardcoded path and regardless of cwd.

2. **Reusable inspection scripts** — common exploration is a script, not an
   inline `find`. `skills/develop/scripts/inspect-block-layout.sh
   <plugin-slug-or-path>` is the reference: it resolves the plugin through
   `source-base.sh`, quotes every expansion, prunes `node_modules`, and prints the
   top-level listing, every `block.json`, and single-file `registerBlockType()`
   blocks — covering both repo layouts safely.

3. **Runtime introspection** — the same rule applies to WordPress/PHP runtime
   queries. Do not pipe an inline PHP heredoc into `wp eval-file`
   (`printf '... $n[] = $name; ...' | docker compose exec -T wpcli wp eval-file -`):
   embedding PHP on the command line trips zsh array/arith expansion prompts.
   Store the PHP as a bundled file under `helpers/` and run it through a thin
   wrapper that pipes it into `wp eval-file -` over STDIN.
   `skills/run/list-blocks.sh` + `skills/run/helpers/list-blocks.php` are the
   reference example.

4. **Skill rule** — skill instructions must not embed hardcoded absolute base
   paths, free-hand `find`/`ls` exploration, or inline PHP/SQL eval heredocs. Use
   `source-base.sh` for locations, a reusable inspection script for layout
   discovery, and `wp-eval.sh` + a bundled `.php` for runtime introspection — each
   invoked via the `${CLAUDE_PLUGIN_ROOT}` absolute form (ADR-094) with all
   expansions quoted (ADR-092).

## Consequences

- **Positive:** No hardcoded checkout paths; one resolver means layout knowledge
  lives in a single place; inspection is safe (quoted, `node_modules` pruned) and
  consistent across both block repos.
- **Positive:** Cheaper and more reliable than re-deriving `find`/`ls` each
  session; reduces the unquoted-glob risk class entirely.
- **Negative:** Adds two maintained scripts that must be referenced from their
  SKILL.md (ADR-032) and updated if the repo layout or plugin set changes.

## Related

- ADR-092: zsh-safe terminal command issuance on macOS
- ADR-094: Expand harness path variables when issuing script commands to Claude
- ADR-093: Persistent session block target (uses block-target-check.sh on resolved paths)
