# ADR-015: Slide deck always includes a generated date

**Status:** Accepted
**Date:** 2026-06-10

## Context

The slide deck title slide showed a broad "Date: June 2026" but no indication of when the content was last generated or updated. When the deck is published to Google Docs, readers cannot tell whether they are looking at current information or a stale snapshot.

## Decision

The slide deck title slide must include a `Generated:` field with the date (YYYY-MM-DD) the content was last updated. This date must be refreshed each time the slides are edited and before each publish to Google Docs.

The `Generated:` date is separate from the `Date:` field, which indicates the presentation's original date or time period. The generated date tracks freshness of the published artifact.

## Consequences

- Readers can assess how current the slide content is at a glance.
- The publish workflow should include updating the generated date as a step.
- Stale publications are identifiable without checking git history.
