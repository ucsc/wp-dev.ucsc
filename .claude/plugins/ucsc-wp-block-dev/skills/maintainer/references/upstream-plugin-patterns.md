# Anthropic plugin pattern library

Use the current
[`anthropics/claude-code/plugins`](https://github.com/anthropics/claude-code/tree/main/plugins)
collection as a pattern library when evolving `ucsc-wp-block-dev`. Compare the
closest analogous plugin instead of assuming `plugin-dev` demonstrates every
production pattern.

For offline study, set `CLAUDE_PLUGINS_SOURCE` to a local
`claude-plugins-official` repository or its `plugins/` directory. The local
marketplace checkout may contain additional or historical examples not present
in the current public `claude-code/plugins` directory, so treat the public
repository and current CLI documentation as canonical when they differ.

```bash
CLAUDE_PLUGINS_SOURCE=/path/to/claude-plugins-official/plugins \
  bash "${CLAUDE_PLUGIN_ROOT}/skills/maintainer/scripts/run-self-test.sh"
```

## Purposeful comparison set

| Upstream plugin | Study for | Apply locally when |
|---|---|---|
| [`plugin-dev`](https://github.com/anthropics/claude-code/tree/main/plugins/plugin-dev) | Manifest/component conventions, authoring guidance, validation agents, reusable scripts | Changing plugin structure, adding components, or extending deterministic checks |
| [`feature-dev`](https://github.com/anthropics/claude-code/tree/main/plugins/feature-dev) | Explicit phased workflows, approval gates, focused exploration/design/review agents, clear “use/don't use” boundaries | Refining `develop feature` or another multi-phase workflow |
| [`hookify`](https://github.com/anthropics/claude-code/tree/main/plugins/hookify) | Project-local configuration, enable/disable lifecycle, simple rule formats, immediate testing, dependency-light hook implementation | Adding configurable hooks or local maintainer policies |
| [`security-guidance`](https://github.com/anthropics/claude-code/tree/main/plugins/security-guidance) | Layered validation: cheap deterministic patterns, focused model review, deeper agentic review; kill switches and privacy documentation | Designing security checks or tiered validation with explicit cost/data trade-offs |
| [`code-review`](https://github.com/anthropics/claude-code/tree/main/plugins/code-review) | Changed-code scope, parallel perspectives, evidence/confidence thresholds, false-positive suppression, skip conditions | Improving `review` findings quality or adding automated review gates |
| [`pr-review-toolkit`](https://github.com/anthropics/claude-code/tree/main/plugins/pr-review-toolkit) | Narrowly specialized agents, concrete trigger examples, targeted vs comprehensive review modes | Splitting a broad review workflow into focused optional lenses |
| [`commit-commands`](https://github.com/anthropics/claude-code/tree/main/plugins/commit-commands) | Small command-focused plugin structure, prerequisites, workflow examples, troubleshooting | Reviewing command documentation and ergonomics only |

Useful local-marketplace additions include `example-plugin` for a compact
mixed command/skill layout, `code-simplifier` for a single-purpose agent
plugin, `session-report` for a skill-oriented reporting workflow, and
`claude-md-management` for commands plus skills in one package.

## Review method

1. Choose one or two analogous plugins from the table; do not read the entire
   collection by default.
2. Inspect the manifest, README, relevant command/agent/skill, helper scripts,
   and tests or hooks for the pattern under review.
3. Record the upstream commit or review date when a decision materially depends
   on the example.
4. Separate reusable design principles from product-specific behavior.
5. Prefer current Claude Code documentation and `claude plugin validate
   --strict` when examples disagree with the live schema.
6. Convert stable, objective rules into focused local scripts and
   negative-path tests. Keep qualitative judgments advisory or opt-in.

## Patterns worth preserving

- Make workflow boundaries explicit, including when not to use a workflow.
- Use the cheapest reliable validation layer first; escalate only when deeper
  judgment is useful.
- Scope reviews to changed code and require evidence before reporting findings.
- Give configurable automation a kill switch, documented lifecycle, and clear
  storage location.
- Document dependencies, data sent externally, local files written, and
  troubleshooting paths.
- Keep agents focused enough that their trigger descriptions and output
  contracts remain concrete.

## Do not copy blindly

An upstream example does not override local requirements. In particular:

- Preserve this repository's no-push rule and explicit external-write
  authorization even when another plugin automates commits, pushes, or PRs.
- Preserve ADR-086's opt-in agent checks and low-token defaults.
- Preserve WordPress, Gutenberg, Docker, macOS zsh, and Bash 3.2 constraints.
- Do not add hooks, agents, MCP servers, dependencies, or telemetry merely
  because an example includes them.
- Do not vendor upstream plugin files. Link, compare, and adapt the smallest
  useful pattern.
