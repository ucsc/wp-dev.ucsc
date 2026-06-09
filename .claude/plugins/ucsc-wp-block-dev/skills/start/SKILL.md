---
name: start
description: Launch ucsc-wp-block-dev, identify the active WordPress app and block target, summarize the plugin, and route a target, request, or Jira issue to the right mode.
disable-model-invocation: false
argument-hint: "[mode | target | request | Jira key/URL]"
arguments: [mode, input]
---

# UCSC WordPress Block Development

Use this as the default entry point for `ucsc-wp-block-dev`.

## Universal Input Routing

Apply ADR-011: parse the full input by meaning as a possible mode, target, natural-language request, and Jira key/URL, regardless of order. Preserve target, request, and Jira values when handing work to another skill. Ask one concise question only when the mode or active app cannot be resolved.

## Identify the Active App

Resolve the app before routing:

1. A working directory containing `docker-compose.yml` and `public/wp-content/plugins/ucsc-gutenberg-blocks/` is the `wp-dev.ucsc` app root.
2. A working directory inside `public/wp-content/plugins/ucsc-gutenberg-blocks/` belongs to that app.
3. Otherwise ask which WordPress app or folder is the target.

State the app, stack, and current directory in one short context receipt.

## Modes

| Mode | Command | Purpose |
|---|---|---|
| Develop | `/ucsc-wp-block-dev:develop` | Add or change block behavior |
| Fix | `/ucsc-wp-block-dev:fix` | Diagnose and repair a problem |
| Test | `/ucsc-wp-block-dev:test` | Add or run PHP, Jest, or browser checks |
| Review | `/ucsc-wp-block-dev:review` | Review a diff, branch, file, or block |
| Run | `/ucsc-wp-block-dev:run` | Build, launch, and smoke-test Docker |
| Maintainer | `/ucsc-wp-block-dev:maintainer` | Improve and validate this plugin |

Route by number, mode name, Jira-backed request, or ordinary language. A clear bug goes to `fix`; new behavior goes to `develop`. Preserve all remaining input during handoff.

Mention `/ucsc-wp-block-dev:menu` as the lightweight way to return to the mode list.
