# Session Block Target (ADR-093)

This is the **shared target-resolution contract** for every block-operating
skill — `develop` (+ `feature`/`fix`), `verify`, `validate`, `run`, and
`review`. Those skills do not each reinvent target intake; they follow the order
below and call the two helper scripts in `../scripts/`. It does **not** apply to
`maintainer` (whose target is the plugin itself, ADR-085) or `hub` (enumeration
only, no target).

The resolved block target is a **persistent session value**: it is resolved once
and reused across skills rather than re-asked each time.

Block targets span two repos plus a third team's plugin; the canonical index is
[`targets.md`](targets.md):

- `ucsc-gutenberg-blocks` — https://github.com/ucsc/ucsc-gutenberg-blocks
- `ucsc-blocks` — https://github.com/ucsc/ucsc-blocks
- `ucsc-custom-functionality` — separate team

## Resolution order

Apply this order at the start of any block-operating skill:

1. **Explicit ARGUMENTS** — a target named in the skill arguments always wins and
   **replaces** the persisted value. The user can switch targets mid-session by
   passing a new one.
2. **Persisted session value** — if no argument is given, adopt the stored target
   without re-asking.
3. **CWD inference** — otherwise infer from the working directory by running
   `bash "${CLAUDE_PLUGIN_ROOT}/skills/develop/scripts/resolve_target.sh" [path] [--persist]`,
   which derives `<slug> <repo> <path>` from the path string alone (no globbing,
   no token cost), validates it, and can persist it. State the inferred target so
   the user can correct it (ADR-090).
4. **Prompt** — only when the above are ambiguous or empty, **prompt the user**
   with the `targets.md` list plus an "other" option (ADR-084). Never silently
   proceed without a target.

On steps 1, 3, and 4 (a newly resolved or changed target), persist it so later
skills reuse it.

## Securing a target — repository, target, and path

When a target is secured, specify **all three** (ADR-093, 2026-06-23 amendment):

1. **Repository** — which repo/plugin owns it (`ucsc-blocks` or
   `ucsc-gutenberg-blocks`; `targets.md` records this per target). The slug alone
   is ambiguous across the two repos.
2. **Target** — the canonical block slug.
3. **Filesystem path** — the absolute path to the block directory (ucsc-blocks
   `src/blocks/<slug>/`) or single-file block (ucsc-gutenberg-blocks
   `src/blocks/<Name>.js`). Resolve and record the real on-disk path so later
   skills act on files directly instead of re-deriving the location.

Persist all three together:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/develop/scripts/session_target.sh" set <slug> <repo> <abs-path>
```

Validate the path with `block_target_check.sh` (below) before persisting.

## Validate the target is really a block

Before adopting an inferred or argument-supplied directory as the target, confirm
it is a WordPress block code set and not just a folder that happens to match a
name. Use the inexpensive check:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/develop/scripts/block_target_check.sh" <block-dir-or-file>
```

It exits 0 (PASS) when the path has a `block.json` (ucsc-blocks layout) or a JS
file calling `registerBlockType()` (ucsc-gutenberg-blocks single-file layout),
and non-zero otherwise. If it FAILs, treat the target as unresolved and prompt
(step 4) rather than persisting a bogus target.

## Helper

[`../scripts/session_target.sh`](../scripts/session_target.sh) reads and writes
the cache file at `~/.cache/ucsc-wp-block-dev/session-target` (override the dir
with `$UCSC_WP_BLOCK_DEV_CACHE`):

Issue these with the harness-expanded `${CLAUDE_PLUGIN_ROOT}` path (ADR-094); do
not assign the script path to a temporary shell variable:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/develop/scripts/session_target.sh" get    # "<slug> <repo> <path>" or empty
bash "${CLAUDE_PLUGIN_ROOT}/skills/develop/scripts/session_target.sh" slug   # slug only
bash "${CLAUDE_PLUGIN_ROOT}/skills/develop/scripts/session_target.sh" repo   # owning repo/plugin only
bash "${CLAUDE_PLUGIN_ROOT}/skills/develop/scripts/session_target.sh" dir    # target's filesystem path only
bash "${CLAUDE_PLUGIN_ROOT}/skills/develop/scripts/session_target.sh" set ucsc-events ucsc-blocks \
  /Users/.../plugins/ucsc-blocks/src/blocks/ucsc-events
bash "${CLAUDE_PLUGIN_ROOT}/skills/develop/scripts/session_target.sh" clear
```

The cache file is session/dev-machine scoped, never committed, and safe to clear
at any time.

## One-call check (ADR-094)

To inspect the session target in a single command — instead of a sequence of
ad-hoc `ls`/`get` calls — run the wrapper, which self-locates via
`${BASH_SOURCE[0]}` and validates the persisted path:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/develop/scripts/check_session_target.sh"
```

To review the source of the target-resolution scripts, run the wrapper's `show`
mode rather than an inline `cat`/`for` loop (which trips shell-expansion
permission prompts, ADR-094/ADR-095):

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/develop/scripts/check_session_target.sh" show
```
