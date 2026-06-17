# Skill Visibility

Use this reference when deciding who may invoke a Claude Code plugin skill.

## Frontmatter settings

### Default: user and Claude can invoke

```yaml
---
name: fix
description: Diagnose and repair application defects.
---
```

Defaults:

```yaml
user-invocable: true
disable-model-invocation: false
```

Use this for normal workflows such as `fix`, `review`, `test`, and `build`.

### User only

```yaml
---
name: deploy
description: Deploy the application.
disable-model-invocation: true
---
```

This:

* keeps the skill available as a user command
* prevents Claude from invoking it automatically
* removes its description from Claude’s normal discovery context

Use for deployment, release, push, production changes, messaging, or destructive actions.

### Claude only

```yaml
---
name: stack-context
description: Repository architecture and framework conventions.
user-invocable: false
---
```

This:

* hides the skill from the user command menu
* still allows Claude to discover and invoke it

Use for architecture, framework conventions, repository knowledge, and other supporting context.

## Decision table

| Desired behavior | Setting                          |
| ---------------- | -------------------------------- |
| User and Claude  | Use defaults                     |
| User only        | `disable-model-invocation: true` |
| Claude only      | `user-invocable: false`          |
| Neither          | Set both restrictions            |

Important:

```yaml
user-invocable: false
```

controls menu visibility only. It does not block Claude’s Skill tool access.

To block Claude invocation, use:

```yaml
disable-model-invocation: true
```

## Plugin skill commands

Plugin skills are always namespaced:

```text
/<plugin-name>:<skill-name>
```

Example:

```text
/sw-dev:fix
```

The namespace comes from the plugin’s `name` in `plugin.json`.

## Skill loading

Claude normally receives a skill’s name and description for discovery.

The complete `SKILL.md` is loaded only when the skill is invoked. Write descriptions that clearly explain both:

* what the skill does
* when Claude should use it

## `skillOverrides`

Claude Code supports these local visibility states for ordinary skills:

```text
on
name-only
user-invocable-only
off
```

However, `skillOverrides` does not apply to plugin skills.

Manage plugin skills through:

* skill frontmatter
* `/plugin`
* plugin enable and disable commands

## Maintainer rule

Classify each plugin skill as one of three types:

* **Workflow:** user and Claude invocable
* **Knowledge:** Claude invocable only
* **Guarded operation:** user invocable only

Do not rely on `skillOverrides` to manage skills packaged inside a plugin.
