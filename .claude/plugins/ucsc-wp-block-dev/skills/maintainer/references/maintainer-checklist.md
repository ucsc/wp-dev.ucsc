# Maintainer checklist — plugin-dev + skill-creator distilled

This checklist synthesizes best practices from the plugin-dev and skill-creator references.

1. Plugin manifest
   - Ensure `.claude-plugin/plugin.json` contains: name, version, description, author, repository, homepage, license.
   - Use kebab-case for `name` and semantic versioning.

2. Structure & discovery
   - Keep commands/agents/skills/hooks at plugin root.
   - Use `${CLAUDE_PLUGIN_ROOT}` in scripts and hooks.

3. Skill frontmatter
   - SKILL.md frontmatter must include `name` and `description`.
   - For risky skills, prefer `allowed-tools` whitelist over `disallowed-tools`.
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
   - Run `maintainer validate` before publishing.
   - Ensure `check-references` passes (ADR-032).
   - Confirm `skill_details.py` shows no unexpected allowed/disallowed tools.

End of checklist.