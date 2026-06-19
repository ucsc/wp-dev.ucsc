---
title: "ADR-047: Warn before editing on non-feature branches"
status: Accepted
date: 2026-06-16
---

# ADR-047: Warn before editing on non-feature branches

## Status

Accepted

## Context

Code changes should normally happen on a short-lived feature branch rather than
on shared integration branches. Editing on `main`, `master`, or `develop`
increases the chance that local work is difficult to isolate, review, or revert.

## Decision

Before making changes in a workflow that edits code, inspect the current Git
branch. If the branch is `main`, `master`, or `develop`, warn the user before
editing.

The warning should be concise and non-blocking unless the user asked for branch
creation. It should say that changes should normally happen on a feature branch
named:

`dev/developer_name/ISSUE-1234_short_desc`

If there is no Jira issue, ask for or infer the best issue token before
suggesting a branch name. Do not create or switch branches unless the user
explicitly asks for that Git operation.

## Consequences

- Users get a timely warning before edits happen on shared branches.
- Feature branch naming stays consistent across fix, feature, and review
  follow-up work.
- Branch creation remains manual by default and follows explicit user intent.
