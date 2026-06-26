# Maintainer mode menu

implements: ADR-020-MAINTAINER-MENU, ADR-086-MAINTAINER-CONVENTIONS

When maintainer is invoked without a mode, present this menu and wait for the
user to choose.

```text
maintainer  [mode] [submode|target]  — maintain this plugin package
├─ backlog                                           — build the personal and unimplemented-ADR backlog
├─ adr        [action] [ADR|decision]                — author, retire, inspect, and reconcile ADRs
├─ skill      [action] [name|candidate]              — maintain plugin skills, references, scripts, and inventory
│  ├─ details         [name]       — inspect live frontmatter and invocation settings
│  ├─ review          [name|all]   — run the opt-in qualitative skill reviewer
│  ├─ review-contrib  <candidate>  — review a proposed or incubating skill
│  ├─ promote         <candidate>  — promote an accepted candidate
│  └─ sync                         — reconcile skill inventories across docs and tests
├─ training   [goal]                                 — study upstream patterns and apply relevant lessons
├─ retro      [lesson|skill]                         — capture reusable session lessons
├─ self-test                                         — run pytest contracts and deterministic plugin checks
├─ validate   [tier1|tier2]                          — run structural validation; Tier 2 is opt-in
├─ docs       [update|check|publish [guide|slides]]  — regenerate portable guide+slides Markdown (publish is the optional final step)
│  ├─ update                   — regenerate the guide+slides artifacts from their sources (synonym for bare docs)
│  ├─ check                    — report whether generated docs are stale vs. their sources (git hash)
│  └─ publish  [guide|slides]  — publish both by default; name one to publish only that output
└─ all                                               — run the deterministic maintainer health checks
```

Compatibility modes remain accepted: `generate-docs` (= `docs`), `publish`
(= `docs publish`), `review-skills`, `review-contrib`, `promote-contrib`,
`check-references`, `check-adr-implements`, `sync-inventory`, and
`skill-details`.

When `skill` is selected, use the nested submodes shown in the tree.
