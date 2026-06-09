# Archived Retrospective — Gutenberg-blocks maintainer hardening (2026-06-18)

> Archived example of a captured retrospective. Relocated 2026-06-23 from
> `ucsc-gutenberg-blocks/skills/maintainer/references/` (it had landed inside the
> WordPress plugin by mistake). The original file was titled "ADR-086" but is a
> retrospective writeup, not an ADR — renamed to avoid colliding with the real
> `docs/adr/ADR-086-maintainer-conventions.md`.

Status: Accepted (historical record)
Date: 2026-06-18

## Context

During the maintainer-focused hardening of the ucsc-gutenberg-blocks plugin and
accompanying Claude Code plugin, a set of security, CI, and workflow changes were
applied (CI workflow, template escaping, REST endpoint hardening, allowed-tools
whitelists, the block-target and maintainer-target ADRs).

## Decision

Record a short retrospective documenting what worked, what didn't, and
recommended follow-ups for maintainers and reviewers.

## What went well

- Tests and driver scripts run locally and validated plugin behavior.
- Moved sensitive skill tooling to explicit allowed-tools whitelists, reducing
  accidental destructive command exposure.
- Added guarded Claude smoke tests (CLAUDE_AVAILABLE) to avoid CI token leaks.
- Implemented targeted template escaping and tightened REST permission callbacks.

## What could be improved

- Secret scanning: current grep-based scan is a stopgap; migrate to
  semgrep/trufflehog or GitHub secret scanning rules.
- CI placement: move workflows to repo-level .github/workflows for broader coverage.
- Add automated PHP template lint (WPCS) and tests asserting output escaping.
- Expand REST permission model to allow scoped API keys for trusted clients.

## Follow-ups / Next steps

1. Replace grep secret-scan with semgrep or trufflehog in CI and enable blocking
   PR checks.
2. Add PHP unit tests that assert escaping of template outputs and scan for
   unescaped echoes.
3. Move CI workflow to repo root and open a PR with a commit message referencing
   the relevant maintainer conventions ADRs.
4. Document secure storage and rotation procedures for LDAP/API credentials;
   ensure token.json remains git-ignored and add a CI check that prevents
   accidental commits of token.json.

Retrospective owner: maintainer
