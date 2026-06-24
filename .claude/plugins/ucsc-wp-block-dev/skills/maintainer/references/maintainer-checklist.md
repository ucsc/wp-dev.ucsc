# Maintainer checklist — official Skills spec + upstream toolkits

Use the official
[Claude Code Skills documentation](https://code.claude.com/docs/en/skills) for
runtime behavior and supported frontmatter. This checklist also synthesizes
authoring and review practices from Anthropic's current
[`plugin-dev`](https://github.com/anthropics/claude-code/tree/main/plugins/plugin-dev)
and `skill-creator` sources. Run `maintainer self-test` first; use this list for
the semantic decisions that remain.

1. Plugin manifest
   - Ensure `.claude-plugin/plugin.json` contains: name, version, description, author, repository, homepage, license.
   - Use kebab-case for `name` and semantic versioning.

2. Structure & discovery
   - Keep commands/agents/skills/hooks at plugin root.
   - Use `${CLAUDE_PLUGIN_ROOT}` in scripts and hooks.
   - For major structure or workflow changes, compare the closest analogous
     plugin listed in `upstream-plugin-patterns.md`.

3. Skill frontmatter
   - Include a concise `description`; keep `name` aligned with the directory
     even though Claude Code can derive the command name from its location.
   - Use `argument-hint` to make invocation syntax understandable in
     autocomplete; use `arguments` only when named positional substitution is
     useful in the skill body.
   - Use `disable-model-invocation: true` for manually controlled workflows
     with side effects or deliberate timing.
   - Remember that `allowed-tools` pre-approves listed tools; it does not
     restrict the remaining tool pool. Use `disallowed-tools` when an active
     skill must remove a tool temporarily.
   - Keep `description` concise and include triggering contexts.

4. Security & secrets
   - Do not commit tokens/keys. Add token locations to `.gitignore`.
   - Add a repository secret-scan in CI. Fail the build on findings.

5. Tests & CI
   - Provide a simple CI workflow that installs test deps and runs pytest in a venv.
   - Guard external CLI tests behind `CLAUDE_AVAILABLE` env var.

6. Documentation
   - README.md covers install, run, test, and maintainer operations.
   - Maintain ADRs and regenerate docs via maintainer scripts.

7. Releases
   - Tag releases with semantic versions and include change notes in ADRs or changelog.

8. Review checklist
   - Run `maintainer self-test`.
   - Run `maintainer validate` before publishing.
   - Ensure `check-references` passes (ADR-032).
   - Confirm `skill_details.py` shows no unexpected allowed/disallowed tools.
   - Use `plugin-dev:skill-reviewer` only when an opt-in qualitative review is
     worth the token cost.

See `self-test.md` for adopted checks, deliberate adaptations, and the
current companion-plugin installation command.
