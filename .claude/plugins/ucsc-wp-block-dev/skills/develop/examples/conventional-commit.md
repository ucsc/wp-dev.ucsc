# Conventional Commit Examples — ucsc-gutenberg-blocks

Copy-adapt these patterns when generating commit messages for block work.

## Feature commits

```
feat(course-catalog): add department filter to sidebar panel

Adds a RadioControl to the editor sidebar that lets authors filter catalog
entries by department before inserting the block.

Refs: WPM-112
```

```
feat(class-schedule): cache PeopleSoft response with 15-min transient

Wraps the REST proxy in a wp_transient so repeated page loads do not hit
the upstream API on every request.
```

## Fix commits

```
fix(campus-directory): prevent LDAP timeout from crashing page render

Guard the LDAP query with a try/catch and return an empty result set on
connection failure instead of propagating the exception.

Refs: PROJECT-123
```

```
fix(accordion): restore focus to trigger after panel closes

Screen readers lost focus when the panel collapsed. The trigger now receives
programmatic focus on close via panel.previousElementSibling.focus().
```

## Test commits

```
test(content-sharer): add Jest coverage for permission gate

Covers the REST permission callback returning false when the user cannot
edit posts, and true when they can.
```

```
test(class-schedule): add standalone PHP test for routing rewrite rules
```

## Chore / maintenance commits

```
chore(course-catalog): bump cache TTL constant name for clarity

Renames CACHE_DURATION to TRANSIENT_TTL_SECONDS; no behavior change.
```

```
docs(class-schedule): add inline comment explaining rewrite flush guard
```

## Footer reference forms

```
Refs: WPM-112          # Jira ticket reference
Refs: #42              # GitHub issue reference
Co-authored-by: Claude Sonnet 4.6 <noreply@anthropic.com>
```

## Rules

- `type(scope): subject` — subject is imperative, lowercase, no period
- Scope is the block slug in kebab-case (`course-catalog`, `campus-directory`)
- Jira key in footer, not subject line (ADR-023)
- Body explains *why*, not what — the diff shows what
