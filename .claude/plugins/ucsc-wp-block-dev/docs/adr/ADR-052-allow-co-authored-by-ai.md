---
title: "ADR-052: Allow Co-authored-by AI in commit messages"
status: Accepted
date: 2026-06-15
---

# ADR-052: Allow Co-authored-by AI in commit messages

## Context

When the AI assistant directly contributes to fixes, features, or test coverage, it is standard open-source practice to explicitly credit pairing partners. Previously, AI generation was silent in the commit history. 

## Decision

It is fully permitted and encouraged to include a standard `Co-authored-by: <Name of AI> <email>` trailer in the footers of Conventional Commit messages generated or executed by the AI assistant. 

## Consequences

- **Positive:** Accurately reflects pair-programming contributions in the `git` history.
- **Negative:** Takes up an extra line in the commit message footer.
