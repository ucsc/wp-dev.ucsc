---
title: "ADR-072: Standardized detailed skill display format for maintainers"
status: Accepted
date: 2026-06-16
---

# ADR-072: Standardized detailed skill display format for maintainers

## Status

Accepted

## Context

When auditing the skills in the `ucsc-wp-block-dev` plugin, maintainers need a quick, clear way to inspect the full invocation posture and frontmatter settings of any given skill. Running the grid-wide `skill-details` operation prints a wide summary table, but to deeply inspect a single skill's configuration (such as custom tools, execution context, or overridden platform defaults), a standardized, detailed per-skill display format is required.

Furthermore, it is critical to explicitly document the underlying settings (such as `user-invocable` and `disable-model-invocation`) and their platform defaults so that maintainers can easily trace how frontmatter translates into actual runtime visibility and access.

## Decision

Establish a standardized detailed skill display card format. This format must be utilized by scripts or tools (like `skill-details.py`) when printing detailed logs for a single skill.

### 1. Standardized Display Template

A skill's detailed configuration card must follow this exact textual structure:

```text
================================================================================
SKILL: <skill-name> [<Configuration Posture: Custom / Default>]
================================================================================
[Frontmatter Settings]
  user-invocable:             <value> (Default: true)
  disable-model-invocation:   <value> (Default: false)
  allowed-tools:              <value> (Default: None)
  disallowed-tools:           <value> (Default: None)
  context:                    <value> (Default: None)
  agent:                      <value> (Default: None)

[Derived Posture]
  User Invocable (Slash Menu): <YES/NO>
  Model Auto-Triggerable:      <YES/NO>
  Discovery Context (Model):   <Visible/Hidden>

[Metadata]
  Description: <skill-description>
  Supporting Files: <comma-separated list of referenced support files under references/>
================================================================================
```

### 2. Underneath Settings & Effects

| Setting | Type | Default | Description & Effect |
|---|---|---|---|
| `user-invocable` | Boolean | `true` | When `false`, hides the skill from the user `/` slash command menu. The model can still auto-invoke it via description matching. |
| `disable-model-invocation` | Boolean | `false` | When `true`, prevents the model from auto-triggering the skill. The user can still invoke it via manual slash commands. |
| `allowed-tools` | List | `None` | Restricts the tools the skill is allowed to use during execution. |
| `disallowed-tools` | List | `None` | Explicitly bans specific tools from being called by the skill. |
| `context` | String | `None` | Defines the execution context behavior (e.g. `fork` to run in an isolated environment). |
| `agent` | String | `None` | Specifies an agent configuration or subagent backing the skill execution. |

### 3. Display Logic Resolution

* **Configuration Posture:** Labeled as `[Custom]` if any configuration parameter differs from its platform default; otherwise, labeled as `[Default]`.
* **User Invocable (Slash Menu):** Maps directly to `user-invocable`.
* **Model Auto-Triggerable:** Resolved as `YES` if `disable-model-invocation` is `false`; otherwise `NO`.
* **Discovery Context (Model):** Resolved as `Visible` if `disable-model-invocation` is `false`; otherwise `Hidden`.

## Consequences

- **Positive:** Provides a clear, unambiguous, and uniform presentation format for debugging skill parameters.
- **Positive:** Helps maintainers audit security postures (like `allowed-tools` or `agent` restrictions) at a glance.
- **Negative:** None.
