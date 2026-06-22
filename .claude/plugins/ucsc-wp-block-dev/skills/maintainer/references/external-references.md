# External References

Authoritative upstream docs for skill and command authoring in this plugin.
Consult these when writing or refining skills, slash commands, or the run/verify
drivers — they are the source of truth over any paraphrase in this repo.

| Topic | URL | Use it for |
|---|---|---|
| Anthropic `skill-creator` skill | https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md | Canonical guidance for authoring skills: `SKILL.md` structure, frontmatter (`name`/`description`), progressive disclosure, bundling driver/support files. Reference when creating or reviewing any skill in this plugin. |
| Claude Code slash commands | https://code.claude.com/docs/en/commands | Official spec for slash commands: frontmatter fields, arguments, `$ARGUMENTS`, bash execution, file references, namespacing. Reference when adding or auditing user-invocable commands/skills. |

## Notes

- The `run-skill-generator` bundled skill (Claude Code v2.1.145+) produces a
  per-project `run-<unit>` skill that builds, launches, and *drives* an app from
  a clean environment. Its definition of done requires actually launching the app
  and committing the interaction harness (driver) next to the `SKILL.md` — not
  paraphrasing the README. Treat it as the upstream pattern this plugin's `run`
  skill follows.
