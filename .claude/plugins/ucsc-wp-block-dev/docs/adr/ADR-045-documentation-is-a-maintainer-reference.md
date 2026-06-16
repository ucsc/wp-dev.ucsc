---
title: "ADR-045: Generate docs is a maintainer reference"
status: Accepted
date: 2026-06-15
---

# ADR-045: Generate docs is a maintainer reference

## Status

Accepted

## Context

Markdown documentation regeneration is maintainer work: it prepares plugin
guide and slide-deck artifacts for Google Docs or Confluence, but it is not an
independent product-development workflow. Keeping it as a top-level skill made
the exported skill list noisier and split documentation maintenance away from
the maintainer workflow that already owns validation and publishing.

## Decision

Move documentation generation guidance to:

`skills/maintainer/references/generate-docs/generate-docs.md`

Move its script and generated assets under:

`skills/maintainer/references/generate-docs/`

The `maintainer` skill owns and indexes the reference. Documentation
regeneration is available as the `maintainer generate-docs` operation. The
operation runs:

```bash
bash .claude/plugins/ucsc-wp-block-dev/skills/maintainer/references/generate-docs/scripts/regenerate.sh
```

The script writes generated Markdown artifacts under
`skills/maintainer/references/generate-docs/assets/` and does not publish or
upload anything.

## Consequences

- The public skill inventory decreases by one skill.
- Documentation generation remains available through progressive disclosure.
- The maintainer workflow owns both documentation regeneration and slide
  publishing.
- ADR-032 continues to ensure the owning skill links every support file.
