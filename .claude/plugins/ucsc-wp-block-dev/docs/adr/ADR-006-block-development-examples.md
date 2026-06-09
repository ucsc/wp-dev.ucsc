---
title: "ADR-006: Referencing official WordPress Block Development Examples"
status: Accepted
date: 2026-06-09
---

# ADR-006: Referencing official WordPress Block Development Examples

## Status

Accepted

## Context

When developing and maintaining custom Gutenberg blocks in the `ucsc-gutenberg-blocks` plugin, we frequently require reliable, up-to-date code patterns for editor components, block states, REST integrations, and custom controls. The official WordPress Block Development Examples repository is the industry-standard repository maintained by the WordPress team, showcasing clean and modern block editor conventions.

## Decision

We will officially adopt and reference the WordPress Block Development Examples repository (`https://github.com/WordPress/block-development-examples`) as our primary source of reference patterns for block authoring. 

Additionally, we will:
1. Add this repository link to the general `blocks` skill reference documentation.
2. Instruct developers and the agent to search or consult these examples first before implementing custom React or JS abstractions in our editor controls.

## Consequences

- Block editor implementations will remain aligned with WordPress core best practices.
- Time spent debugging custom panel settings or data binding in JS is reduced by matching official recipes.
- The repository link is easily discoverable within the `blocks` skill for onboarded developers.
