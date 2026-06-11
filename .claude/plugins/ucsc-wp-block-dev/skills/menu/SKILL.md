---
name: menu
description: Show the ucsc-wp-block-dev mode table mid-session and route a target, ordinary-language request, or Jira reference without repeating app discovery.
disable-model-invocation: true
argument-hint: "[mode | target | request | Jira key/URL]"
arguments: [mode, input]
---

# ucsc-wp-block-dev Mode Menu

## Universal Input Routing

Apply ADR-011: parse the full input as a possible mode, target, natural-language request, and Jira key/URL. Preserve all non-mode input for the selected handler. Ask which mode only when it cannot be inferred.

| # | Mode | Command |
|---|---|---|
| 1 | Develop | `/ucsc-wp-block-dev:develop` |
| 2 | Fix | `/ucsc-wp-block-dev:fix` |
| 3 | Test | `/ucsc-wp-block-dev:test [php\|jest\|e2e]` |
| 4 | Review | `/ucsc-wp-block-dev:review` |
| 5 | Run | `/ucsc-wp-block-dev:run` |
| 6 | Verify | `/ucsc-wp-block-dev:verify` |
| 7 | Maintainer | `/ucsc-wp-block-dev:maintainer` |

Route by number, name, Jira-backed request, or ordinary language.
