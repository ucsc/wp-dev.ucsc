---
name: wp7-pattern-lock
description: Diagnose and remediate WordPress 7.0 pattern content-locking on CampusPress sites — pages whose blocks carry metadata.patternName stamps become content-only (structure uneditable, List View flattened). Trigger examples; "pages built from a pattern can't be edited", "left navigation pattern broken", "columns not selectable in the editor after the WP upgrade".
version: 0.1.0
argument-hint: "[site-url] [pages]"
---

# WP 7.0 Pattern-Lock — Diagnose & Remediate

<!-- doc-slide: Diagnoses and repairs WordPress 7.0 pattern content-locking — scans sites for patternName-stamped pages, proves the lock in the editor, and strips the stamps with backups and revisions. -->

WordPress 7.0 treats any block whose markup carries
`"metadata":{"patternName":...}` (stamped automatically at pattern-insert
time since ~WP 6.4) as a locked pattern instance: container blocks report
`getBlockEditingMode() = disabled`, content blocks `contentOnly`, List View
flattens. Origin: ServiceNow incident `82fbca3a3382cb14281077f92e5c7bb2`
(SHR, July 2026). Full incident context (status, blast radius, open steps)
lives with the data in `~/_WP_tools/wp7-pattern-lock/STATUS.md` — read it
when continuing the incident work.

## Intake

Required before using tools:

1. **Site URL** (canonical `*.wordpress.ucsc.edu` form for wp-admin/REST).
2. **Credentials** — `WP_USER`/`WP_APP_PASS` from the environment or from a
   `.env` file in the current directory (override the file path with
   `UWP_ENV_FILE`). Requires an application password with edit rights on
   the target site.
3. **Write authorization** — content-modifying steps require explicit
   site-owner permission. Scans and dry-runs are read-only and always safe.

All REST calls must send a curl User-Agent (CampusPress WAF drops
python-urllib's default).

## Workflow

1. **Scan one site:** `python3 scripts/pattern-scan.py <site-url>` — counts
   stamped pages, tallies patterns, lists affected pages.
2. **Sweep the network:** `python3 scripts/network-sweep.py
   <report-rows.csv> [output-dir]` — reads "Canonical Url" from a
   comprehensive-report CSV, writes summary + per-page detail CSVs
   (default output `~/_WP_tools/wp7-pattern-lock/`, never the repo).
3. **Verify a lock (evidence):** `node scripts/check-lock.mjs
   "<edit-url>" [shot.png]` — Playwright, read-only editor-state dump of
   per-block editing modes (requires an SSO-logged-in persistent Chrome
   profile: set `PATTERNLOCK_PROFILE`, default `./profile`; log in once
   through the opened window on first run).
4. **Fix (writes — needs authorization):** `python3
   scripts/fix-patternlock.py <site-url> --pages <ids>|--all [--apply]` —
   dry-run by default; `--apply` removes only the `patternName` key,
   backs up originals outside the repo (`PATTERNLOCK_BACKUP_DIR`), and
   each REST update leaves a WP revision for rollback.
5. **Completion evidence:** re-run `check-lock.mjs` (all blocks
   `mode=default`) and re-run `pattern-scan.py` (0 stamped pages).

## Validation

- Dry-run on stamped pages reports exact stamp counts and "JSON valid".
- Proven end-to-end 2026-07-16 on a sandbox subsite draft page, and
  2026-07-17 on a live-site draft: locked before, `default` after,
  frontend markup unchanged.
- Caveat: stamp removal fixes existing pages only; new pattern inserts
  re-stamp. The durable fix is a network-level opt-out (CampusPress).
