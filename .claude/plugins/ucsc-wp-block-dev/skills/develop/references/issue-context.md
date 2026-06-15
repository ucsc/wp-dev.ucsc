# Issue Context

Read this reference when a feature or fix includes a Jira key, Jira URL,
Confluence URL, pasted ticket details, or a user request that needs to be
normalized into an implementation brief.

## Resolve Input

Resolve the target block or app, natural-language issue summary, and optional
Jira key/URL regardless of order. Ask one concise question only when none of
those inputs identifies work to summarize.

Accept the Jira reference as either:

- A bare issue key matching `[A-Z]+-\d+`, such as `WPM-97`.
- A full Atlassian URL such as
  `https://ucsc-its.atlassian.net/browse/WPM-97`.

For a URL, extract the key from the trailing `/browse/<KEY>` segment and use
that canonical key. Treat a token that is neither a valid key nor a parseable
Jira URL as part of the natural-language request.

Use available Jira tooling when present. Otherwise accept pasted ticket details
or the user's description. Jira is preferred for feature and fix work but never
required.

When a Jira key/URL or Confluence URL is in use and Atlassian MCP tools are unavailable, mention once that the user can set up Atlassian MCP for direct access. Keep the reminder brief and non-blocking, continue with available context, and do not repeat it later in the task. Never install, configure, authenticate, or reload Atlassian MCP without explicit user approval.

## Implementation Brief

Return a compact brief containing:

- Target
- Source
- Issue type
- Goal
- Expected and actual behavior
- Acceptance criteria
- Constraints
- Likely PHP, JavaScript, REST, integration, or Docker surface
- Open questions

Explicit current user instructions take precedence when Jira details conflict.
