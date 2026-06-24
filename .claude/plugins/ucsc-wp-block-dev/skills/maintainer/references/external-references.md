# External References

Authoritative upstream docs for skill and command authoring in this plugin.
Consult these when writing or refining skills, slash commands, or the run/verify
drivers — they are the source of truth over any paraphrase in this repo.

| Topic | URL | Use it for |
|---|---|---|
| Claude Code skills | https://code.claude.com/docs/en/skills | Primary specification for skill locations, discovery, frontmatter, invocation controls, arguments, supporting files, progressive disclosure, and the bundled `/run`, `/verify`, and `/run-skill-generator` contract. Consult this first for Claude Code skill behavior. |
| Anthropic Claude Code plugin collection | https://github.com/anthropics/claude-code/tree/main/plugins | Production examples of command-only, agent-driven, hook-based, configurable, security, review, and phased-workflow plugins. Use `upstream-plugin-patterns.md` to select the closest comparison rather than scanning everything. |
| Run skill generator system prompt (community mirror) | https://github.com/Piebald-AI/claude-code-system-prompts/blob/main/system-prompts/skill-run-skill-generator.md | Supplemental implementation detail for `/run-skill-generator`. The official Skills documentation governs the public contract: `/run` launches/drives the app, `/verify` confirms a specific change in the running app, and `/run-skill-generator` records the clean-environment recipe and harness. This plugin keeps automated PHP/Jest/e2e suites under `validate`. |
| Anthropic `plugin-dev` toolkit | https://github.com/anthropics/claude-code/tree/main/plugins/plugin-dev | Current source for plugin structure, skill development, validation agents, security checks, examples, and reusable validation ideas. Use `self-test.md` for the locally adopted deterministic profile. |
| Anthropic `skill-creator` toolkit | https://github.com/anthropics/skills/tree/main/skills/skill-creator | Canonical guidance and tooling for authoring and improving skills: `SKILL.md`, progressive disclosure, bundled resources, evaluation agents, benchmarks, description optimization, and packaging scripts. Reference when creating, reviewing, or measuring any skill in this plugin. |
| Claude Code commands reference | https://code.claude.com/docs/en/commands | Inventory of built-in commands and bundled skills. Custom commands have merged into skills, so use the Skills documentation above for authored skill behavior and frontmatter. |

## Notes

- The `run-skill-generator` bundled skill (Claude Code v2.1.145+) produces a
  per-project `run-<unit>` skill that builds, launches, and *drives* an app from
  a clean environment. Its definition of done requires actually launching the app
  and committing the interaction harness (driver) next to the `SKILL.md` — not
  paraphrasing the README. Treat it as the upstream pattern this plugin's `run`
  skill follows.
- Claude Code custom commands are now skills. Prefer plugin skills under
  `skills/<name>/SKILL.md`; retain `.claude/commands/` only for compatibility
  with an existing command surface.
- Anthropic's `plugin-dev` repository is guidance, not a vendored dependency.
  Prefer the current Claude Code docs and `claude plugin validate --strict`
  whenever an older example disagrees with the live schema.
- The broader plugin collection is a pattern library, not a policy bundle.
  Preserve local ADRs and authorization boundaries when adapting examples.
