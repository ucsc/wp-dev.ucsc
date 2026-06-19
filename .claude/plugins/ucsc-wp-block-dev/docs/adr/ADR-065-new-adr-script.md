---
title: "ADR-065: Introduce automated ADR creation script new_adr.sh"
status: Accepted
date: 2026-06-16
---

# ADR-065: Introduce automated ADR creation script new_adr.sh

## Status

Accepted

## Context

Creating Architectural Decision Records (ADRs) is a frequent task during the development and maintenance of the `ucsc-wp-block-dev` plugin.
The process previously required manually scanning `docs/adr/` and `docs/adr/index.md` to identify the next available sequential number, creating a new file with the correct filename convention, writing standard frontmatter, and appending an entry to `docs/adr/index.md`.
This manual process was tedious and prone to human error or race conditions (number-collision gotcha) when multiple tasks or agents were active.

## Decision

We will introduce a shell script at `skills/maintainer/scripts/new_adr.sh` that automates the creation of new ADR files:

1. The script accepts a slug and a title as arguments.
2. It normalizes the slug into a lowercase, hyphen-separated string suitable for filenames.
3. It scans the `docs/adr/` directory to automatically resolve the next sequential number.
4. It creates the new markdown file with the standard ADR frontmatter and markdown skeleton.
5. It appends the new ADR entry to the table in `docs/adr/index.md`.

## Consequences

- **Positive:** Reduces token use and eliminates exploratory file-reading and hand-editing steps when creating new ADRs.
- **Positive:** Standardizes filename formatting and skeleton structures across all new ADRs.
- **Positive:** Retires the ADR number-collision gotcha.
- **Negative:** None. Developers must simply use the script rather than creating files by hand.
