# GitHub CLI Tooling

Use this reference when a `ucsc-gutenberg-blocks` workflow needs GitHub CLI
tooling for pull request inspection or creation.

## Tool choice

- Prefer the least-token available safe channel for the requested operation, in
  this order: GitHub MCP if already available and low-token, `gh` for
  local/manual CLI work, GitHub REST API with a fine-grained token, `hub` only
  for legacy compatibility, then a manual compare URL.
- Prefer `gh` when a local CLI is needed. GitHub's official `cli/cli`
  README describes it as GitHub on the command line for pull requests, issues,
  and other GitHub concepts, and lists macOS installation through Homebrew or
  precompiled release binaries.
- Treat `hub` as legacy fallback tooling. The `hub` README describes it as a
  wrapper around `git` that adds GitHub features, and directs users who want an
  official, more user-friendly GitHub CLI to `cli.github.com`.
- Do not require `gh` or `hub` when MCP or REST can complete the same GitHub
  operation with less setup or lower token use.

## macOS installation

Authoritative Homebrew formula pages list these install commands:

```bash
brew install gh
brew install hub
```

For this UCSC WordPress block workflow, install `gh` first. Install `hub` only
when a legacy script or workflow explicitly requires it.

## First-time authentication

After installing `gh`, authenticate interactively:

```bash
gh auth login
gh auth status
```

Choose GitHub.com unless working against a GitHub Enterprise host. Use SSH for
Git operations when the local repository remote is SSH-based.

## GitHub MCP setup notes

Use GitHub MCP for PR work when it is already available and lower-token than
CLI or REST. When it is not loaded, do not treat that as a hard failure: check
for `gh`, `hub`, REST token availability, then fall back to a manual compare
URL.

After installing or changing a GitHub MCP server, the active Codex session may
need a restart before the new tools appear. Verify availability with the
session's MCP listing before attempting PR creation through MCP. A good minimal
local GitHub MCP toolset for this plugin is `context,repos,pull_requests`.

## Pull request workflow guardrails

Per ADR-055, the assistant must not push branches or rewrite remote branch
history. None of the GitHub connection options should be used by the assistant
to run `git push`. When a branch is not available remotely, provide the manual
push command and stop. Once the branch exists remotely, `gh pr create`,
`gh pr view`, `gh pr diff`, GitHub MCP, or GitHub REST may be used for pull
request work.

Useful read-only checks:

```bash
gh auth status
gh pr status
gh pr view --web
gh pr diff
hub version
```

Useful user-run PR creation command:

```bash
gh pr create --base main --head <branch> --title "<title>" --body "<body>"
```
