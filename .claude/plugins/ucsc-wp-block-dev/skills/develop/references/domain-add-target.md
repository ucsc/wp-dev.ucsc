# Add a New Block Target

Checklist for onboarding a new block as a first-class target in the
`develop` skill. Run these steps in order; the bidirectional test
(`test_target_references_are_bidirectional`) will catch any divergence.

## 1. Create the target reference file

Create `skills/develop/references/target-<slug>.md`. Cover:

- **Plugin identity** — plugin name, directory, block namespace
- **Key files** — PHP class, template, JS source, `render.php` if applicable
- **Attributes** — every `register_block_type` attribute with type and default
- **Data layer** — API source, cache key, TTL, SSRF/size-limit guards
- **AJAX/REST endpoints** — if any
- **Editor UI** — inspector controls, preview behaviour
- **Gotchas** — known sharp edges (function_exists guard, no rate limit, etc.)

Use an existing target reference as a template (e.g.
[`target-class-schedule.md`](target-class-schedule.md)).

## 2. Update targets.md

Add a row to the correct plugin section in
[`targets.md`](targets.md). Columns vary by plugin:

**ucsc-gutenberg-blocks** — `Target | Aliases | Block name (dev) | Block name (rendered) | Reference`  
**ucsc-blocks** — `Target | Aliases | Block name | Reference`

## 3. Update develop/SKILL.md

Add a bullet to the matching plugin section under "Target references":

```
- `references/target-SLUG.md`
```

Replace `SLUG` with the actual target slug (e.g. `target-my-block.md`).

## 4. Decide verify coverage

Per ADR-074, `verify` covers only the original three ucsc-gutenberg-blocks
targets until a block is formally onboarded. If this block is ready to be
covered, update `skills/verify/SKILL.md` and revise ADR-074's onboarding
criteria.

## 5. Run the test suite

```bash
cd "${CLAUDE_PLUGIN_ROOT}" && ../ucsc-wp-block-dev-venv/bin/pytest -q
```

The `test_target_references_are_bidirectional` test will fail if step 1 and
step 2 are out of sync.
