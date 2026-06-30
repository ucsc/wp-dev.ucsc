---
title: "ADR-053: Tag commits with ucsc-wp-block-dev skillset use"
status: Superseded
date: 2026-06-15
---

# ADR-053: Tag commits with ucsc-wp-block-dev skillset use

## Context

As the `ucsc-wp-block-dev` plugin becomes more heavily utilized to drive development, testing, and maintenance of the `wp-dev.ucsc` platform, it is helpful to track which commits were generated or significantly assisted by the plugin's skillset.

## Decision

All commits generated or committed by the AI assistant using the `ucsc-wp-block-dev` plugin must include a footer tag indicating the plugin's involvement. 

The standard format to be appended to the commit message footer is:
`Generated-by: ucsc-wp-block-dev`

This should be added alongside other standard footers like `Refs:` or `Co-authored-by:`.

## Consequences

- **Positive:** Provides clear provenance and analytics on how much of the repository's history is being driven or assisted by the custom Claude Code plugin.
- **Negative:** Takes up an extra line in the commit message footer.
