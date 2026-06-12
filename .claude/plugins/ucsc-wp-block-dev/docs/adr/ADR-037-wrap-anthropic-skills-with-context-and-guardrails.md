---
title: "ADR-037: Wrap Anthropic skills with UCSC context and guardrails"
status: Accepted
date: 2026-06-12
---

# ADR-037: Wrap Anthropic skills with UCSC context and guardrails

## Context

Anthropic supplies general-purpose skills and commands for workflows such as code review, debugging fixes, and feature development. Reimplementing a mature general workflow inside `ucsc-wp-block-dev` creates duplication and prevents the plugin from benefiting from upstream improvements.

The plugin's distinctive value is UCSC-specific context and guardrails: the target block registry, WordPress and Docker conventions, Jira and pull-request normalization, approval gates, validation rules, token policy, and completion handoffs.

Delegating indiscriminately can still increase cost. Multi-agent expansion, repeated repository discovery, broad context transfer, and verbose execution may consume more tokens than direct work. Reuse must therefore follow ADR-003's low-token constraint.

## Decision

Where a suitable Anthropic skill is available, prefer composing it with `ucsc-wp-block-dev` context and guardrails instead of duplicating its general workflow.

Examples include Anthropic skills associated with code review, fix, and feature commands. The UCSC command remains the user-facing orchestrator and owns intake, routing, approvals, local policy, and final handoff. The Anthropic skill performs only the bounded general-purpose work assigned to it.

### Context packet

Before invoking an Anthropic skill, resolve and pass a compact task packet containing only relevant context:

- task type: fix, feature, review, or another supported operation;
- target repository, block, files, or change set;
- user request and approved requirements or solution;
- Jira or pull-request context when relevant;
- strongest available evidence and already completed investigation;
- UCSC-specific implementation constraints and applicable ADR guardrails;
- required validation and expected output shape.

Do not ask the delegated skill to rediscover context already resolved by the plugin. Do not send unrelated files, full histories, large logs, or the entire plugin instruction set.

### Low-token execution

Delegated execution uses the most conservative effective mode available:

- disable multi-agent or parallel-agent expansion by default;
- use one bounded skill invocation rather than a team of agents;
- request concise findings, plans, patches, or evidence;
- select slow, deliberate, or low-token execution modes when the host exposes such controls and they reduce speculative work or token burn;
- prevent recursive delegation unless the user explicitly requests it or a measured exception is necessary;
- keep work inline when delegation would cost more than the bounded task;
- do not invoke an Anthropic skill merely because a similarly named command exists.

The plugin may delegate a phase rather than the entire command. For example, it may collect UCSC context and approvals, delegate a bounded review or implementation step, then apply UCSC validation and handoff rules itself.

### Guardrail ownership

Delegation does not transfer responsibility for:

- the fix diagnosis and solution-approval gate;
- the feature requirements and proposed-solution approval gate;
- preserving pre-existing changes;
- UCSC security, escaping, accessibility, schema, and Docker conventions;
- risk-appropriate tests and validation;
- the post-change test and Conventional Commit message offers;
- reporting uncertainty, incomplete access, or validation gaps.

If the Anthropic skill conflicts with an accepted plugin ADR or explicit user instruction, the plugin guardrail or user instruction wins.

## Consequences

- General workflows can benefit from Anthropic-maintained capabilities without duplicating them in every UCSC skill.
- The plugin remains valuable as a focused context builder, policy layer, and workflow orchestrator.
- Delegation stays bounded and low-token rather than automatically spawning multiple agents.
- Commands must retain a direct inline fallback when the Anthropic skill is unavailable, unsuitable, or more expensive than completing the task locally.
- Upstream skill behavior and token cost should be reevaluated periodically; this decision does not require delegation when measurements show no benefit.
