# Hub: resolving the current repository and its block targets

implements: ADR-060-HUB-LIST-SKILLS

`:hub` resolves, validates, and **sets** the session block target so the next
workflow skill reuses it instead of making the user re-specify it (ADR-093,
ADR-060 amendment) — but only when a target is **supplied or unambiguously
inferred from the cwd**. The block target is **optional** for `:hub`: it never
prompts for a target and never blocks the inventory on a target selection.
Setting that session value is the only state `:hub` changes; it still does not
invoke a workflow skill (no routing). Resolution and validation order:

1. **Target passed to `:hub`** — when the user supplies a block (e.g.
   `:hub ucsc-events`), validate it before adopting it. Resolve its repo and
   on-disk path from
   [`../../develop/references/targets.md`](../../develop/references/targets.md),
   then confirm it is a real block:

   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/skills/develop/scripts/block-target-check.sh" <block-dir-or-file>
   ```

   On PASS, persist it (below); on FAIL, report the target as invalid and fall
   through to CWD detection rather than persisting a bogus value.

2. **CWD auto-set** — otherwise detect the repo and slug from the
   working-directory path string (token-free, no globbing) and, **only when a
   single slug resolves**, persist it:

   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/skills/develop/scripts/resolve-target.sh" --persist
   ```

   It prints `<slug> <repo> <path>`. A resolved slug auto-sets the session
   target; it does **not** scope which repos appear in the list below. When no
   single slug resolves (e.g. the cwd is a repo root, or exit 3), set nothing and
   fall through to step 3.

3. **List targets from every block repo that exists (no prompt)** — independent
   of the cwd, list the block targets for each known repo **that is present on
   disk**, and omit any repo that is absent. Check presence cheaply (a directory
   test, not a scan):

   ```bash
   plugins="$(bash "${CLAUDE_PLUGIN_ROOT}/skills/develop/scripts/source-base.sh" wp-plugins)"
   for repo in ucsc-blocks ucsc-gutenberg-blocks; do
     [ -d "$plugins/$repo" ] && echo "present: $repo"
   done
   ```

   For each repo reported `present:`, list that repo's targets from
   [`targets.md`](../../develop/references/targets.md) (the canonical, drift-free
   source). If both repos exist, include both — the `ucsc-blocks` blocks **and**
   the `ucsc-gutenberg-blocks` blocks. If only one exists, list only that one. If
   neither is present, say no block repo is on disk and list no targets. This is
   an **informational** list shown beside the inventory: `:hub` leaves the
   session target unset and never blocks on a selection. The user may run
   `:hub <block>` or name the target when invoking a workflow skill. Listing
   available targets is not the same as requiring a selection.

When a target is resolved by step 1 or step 2, persist it with the ADR-093
contract so every later skill reuses it without re-asking:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/develop/scripts/session-target.sh" set <slug> <repo> <abs-path>
```

When a target was set (step 1 or 2), show it at the top of the inventory and
frame the workflow list around it (e.g. "what the plugin can do with `<slug>` as
the target"). When none was set, just show the inventory. Either way the user
then invokes a workflow skill to act — `:hub` itself never invokes one.

Known block-hosting repos:

- `ucsc-blocks` — `src/blocks/<slug>/` (e.g. `ucsc-events`, `calendar-feed`)
- `ucsc-gutenberg-blocks` — `src/blocks/<Name>.js`
