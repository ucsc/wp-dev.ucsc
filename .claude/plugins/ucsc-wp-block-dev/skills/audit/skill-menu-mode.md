# Audit mode menu

implements: ADR-111-AUDIT-TOP-DOWN-REPO-AUDIT

When `audit` is invoked without a mode and the intended mode is not clear from
the request, present this menu (the hub subtree for `audit`, ADR-088) and wait
for the user to choose.

```text
audit  [full|tools] [scope or emphasis]  — top-down read-only audit of the whole repository
├─ full   [scope or emphasis]       — phased top-down audit with specialist subagents
└─ tools  [php|node|both] [target]  — run the local ucsc-php-review / ucsc-node-review runners
```

Bare `audit` with a scope or emphasis but no mode follows the `full` flow in
`SKILL.md`. The tree above is rendered from
`skills/hub/references/skill-tree.json` by `sync-inventory.sh`, so it always
matches the hub.
