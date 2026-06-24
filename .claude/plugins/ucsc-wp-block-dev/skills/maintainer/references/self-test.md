# Maintainer self-test profile

Use Anthropic's current
[`plugin-dev` source](https://github.com/anthropics/claude-code/tree/main/plugins/plugin-dev)
as an upstream review aid for maintaining `ucsc-wp-block-dev`.

The self-test combines the plugin's pytest contracts with stable deterministic
rules adapted from upstream examples. Subjective judgments remain with opt-in
Tier 2 agents.

## Deterministic checks adopted locally

- Manifest JSON, kebab-case name, semantic version, author shape, and
  recommended metadata.
- Root-level placement of auto-discovered components.
- Skill frontmatter, skill-directory naming, description length and trigger
  clarity.
- Progressive-disclosure warning when a `SKILL.md` body exceeds 3,000 words.
- Executable-bit checks for helper scripts and runnable examples.
- README and LICENSE presence.
- Common generated junk and high-confidence credential signatures.

Run the complete self-test from the repository root:

```bash
bash .claude/plugins/ucsc-wp-block-dev/skills/maintainer/scripts/run_self_test.sh
```

Run only the best-practice checker when diagnosing that layer:

```bash
python3 .claude/plugins/ucsc-wp-block-dev/skills/maintainer/scripts/check_plugin_best_practices.py \
  --strict-warnings
```

Warnings are advisory by default. The checker also supports `--json`.

## Optional local source checkouts

For offline inspection or periodic comparison, point the audit at local
Anthropic checkouts. Keep locations outside checked-in skill instructions:

```bash
PLUGIN_DEV_SOURCE=/path/to/claude-plugins-official/plugins/plugin-dev \
SKILL_CREATOR_SOURCE=/path/to/skills/skills/skill-creator \
CLAUDE_PLUGINS_SOURCE=/path/to/claude-plugins-official/plugins \
  bash .claude/plugins/ucsc-wp-block-dev/skills/maintainer/scripts/run_self_test.sh
```

`--plugin-dev-source` accepts the `plugin-dev` directory, its `plugins/`
parent, or the repository root. `--skill-creator-source` similarly accepts the
`skill-creator` directory, its `skills/` parent, or the repository root. The
audit reports whether expected source and validation files are present and
includes each Git commit when available. It does not execute or vendor files
from either checkout.

`--plugin-collection-source` accepts the marketplace repository root or its
`plugins/` directory. It reports the Git commit, plugin count, complete
inventory in JSON mode, and availability of the focused examples listed in
`upstream-plugin-patterns.md`.

The current `skill-creator` source adds useful review dimensions beyond the
older plugin-dev guidance:

- Keep the core `SKILL.md` below roughly 500 lines when practical.
- Put both capability and triggering context in the description.
- Capture concrete use cases and expected output before writing.
- Add reusable scripts when repeated work appears across real uses.
- For meaningful skill changes, consider evaluation prompts, baselines, and
  iteration rather than relying only on structural linting.

## Qualitative checks retained as Tier 2

Use the companion plugin when semantic review is worth the token cost:

- `plugin-dev:plugin-validator` for overall plugin quality and security review.
- `plugin-dev:skill-reviewer` for trigger effectiveness, writing style, and
  progressive-disclosure judgment.
- `plugin-dev:plugin-structure` and `plugin-dev:skill-development` while
  designing or substantially refactoring components.

Install the current marketplace distribution in Claude Code:

```text
/plugin install plugin-dev@claude-code-marketplace
```

Then run `/reload-plugins`.

Before Tier 2 work, verify installation with `claude plugin list`. Use
`plugin-dev:plugin-validator` for semantic plugin validation and
`plugin-dev:skill-reviewer` for `maintainer skill review`; neither runs as part
of `self-test` or `all`.

## Deliberate adaptations

Do not copy upstream checks blindly. The `plugin-dev` source is a strong
reference, but portions can lag the current Claude Code schema or conflict with
accepted local ADRs.

- Treat missing recommended manifest metadata as warnings; only `name` is
  required by Claude Code.
- Accept the frontmatter fields allowed by ADR-070 instead of the smaller field
  set shown in older `plugin-dev` examples.
- Preserve the plugin's accepted nested mode/sub-skill organization.
- Keep agent-backed review opt-in under ADR-064; deterministic checks belong in
  `maintainer all`.
- Prefer the official Claude Code docs and CLI validator when they disagree
  with prose or examples in `plugin-dev`.

Review upstream changes periodically rather than vendoring the toolkit. When a
new stable rule is useful, add a focused local check plus a negative-path test.
