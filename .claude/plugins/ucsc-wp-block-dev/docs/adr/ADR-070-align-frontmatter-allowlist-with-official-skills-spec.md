---
title: "ADR-070: Align frontmatter allowlist with official Claude Code skills specification"
status: Accepted
date: 2026-06-16
---

# ADR-070: Align frontmatter allowlist with official Claude Code skills specification

## Status

Accepted

Supersedes ADR-005 (Skill frontmatter uses supported skill and command fields).

## Context

ADR-005 restricted `SKILL.md` frontmatter to the two portable Agent Skills core
fields (`name`, `description`), and the structural tests enforced this with an
exact-match assertion. The intent was portability across AI tools that implement
the [Agent Skills open standard](https://agentskills.io).

The official Claude Code skills specification
(`https://code.claude.com/docs/en/skills`) documents a larger set of supported
frontmatter fields — including `when_to_use`, `argument-hint`, `arguments`,
`disable-model-invocation`, `user-invocable`, `allowed-tools`, `disallowed-tools`,
`model`, `effort`, `context`, `agent`, `hooks`, `paths`, and `shell` — none of
which are illegal in practice but were blocked by the tests. The restriction
prevented legitimate use of platform features and would have required an ADR
amendment before any new field could be used.

## Decision

The official Claude Code skills specification is the authoritative source for
valid frontmatter fields. The structural tests are updated to use an allowlist
containing the full official field set rather than requiring exact `{name,
description}` membership. Any key not in the official list is still rejected
(to catch typos), but any key that is in the official list is permitted.

Canonical reference: `https://code.claude.com/docs/en/skills`

Full allowlist (as of 2026-06-16):

```
name  description  when_to_use  argument-hint  arguments
disable-model-invocation  user-invocable  allowed-tools  disallowed-tools
model  effort  context  agent  hooks  paths  shell
```

## Consequences

- **Positive:** Skills can use the full platform feature set (`when_to_use`,
  `argument-hint`, `context: fork`, `allowed-tools`, etc.) without failing
  tests or requiring ADR amendments.
- **Positive:** Tests still reject unknown keys, so typos in frontmatter are
  caught.
- **Negative:** Skills that use Claude Code-specific fields (beyond `name` and
  `description`) will not be portable to other Agent Skills implementations.
  Maintainers should document any Claude Code-specific field usage in the
  relevant SKILL.md.
