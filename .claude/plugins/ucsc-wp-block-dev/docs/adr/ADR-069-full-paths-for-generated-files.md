---
title: "ADR-069: Offer full path for code review results and context summaries"
status: Accepted
date: 2026-06-16
---

# ADR-069: Offer full path for code review results and context summaries

## Status

Accepted

## Context

When generating documents that summarize code reviews, context summaries (such as `pr_review_171.md`), or test logs, presenting only relative paths or file basenames makes it harder for the user to locate them in their local filesystem.
Providing the full, absolute path makes it clear and immediate where these files are stored. For simple lists of files modified during code changes, relative paths are preferred for brevity and readability.

## Decision

The agent will offer the full, absolute path for generated files that represent code review results or context summaries.

1. When pointing to newly generated review reports or context summaries, provide the absolute path.
2. Format these paths as clickable local file links using the `file://` scheme (e.g. `[pr_review_171.md](file:///absolute/path/to/pr_review_171.md)`) to allow the user to easily open them directly.
3. This does not apply to lists of modified source files.

## Consequences

- **Positive:** Enhances user experience by providing clear, unambiguous, and clickable pointers to all files.
- **Positive:** Reduces exploratory time spent searching for output files.
- **Negative:** None.
