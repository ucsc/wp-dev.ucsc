---
name: setup
description: Show a short first-time overview of the WordPress block development plugin and how to begin, without performing broad repository discovery.
disable-model-invocation: true
argument-hint: "[target | request | Jira key/URL]"
arguments: [input]
---

# Setup

Give a concise capability summary:

- **Build** Gutenberg blocks and editor or frontend features.
- **Fix** PHP, JavaScript, REST, LDAP, PeopleSoft, cache, build, and browser issues.
- **Test** blocks with PHP checks, Jest, Docker, and browser smoke tests.
- **Review** diffs, branches, files, and block implementations.
- **Run** the WordPress Docker environment and block build.
- **Understand** block architecture, integrations, and local environment behavior.
- **Maintain** the ucsc-wp-block-dev plugin and its guidance.

Every mode accepts a target, a natural-language request, and an optional Jira key/URL under ADR-011. Do not run broad discovery from setup.

End by inviting the user to describe the work, invoke a direct mode, or use `/ucsc-wp-block-dev:start` for the app-aware menu.
