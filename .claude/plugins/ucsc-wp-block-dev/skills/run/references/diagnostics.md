# Run: runtime introspection and block diagnosis

implements: ADR-095-RUN-WP-EVAL

These wrappers are used only when inspecting live runtime state or diagnosing a
misbehaving block — not on every run. The `run/SKILL.md` "Runtime introspection &
diagnostics" section is the compact index; this file is the detail.

## Why not an inline heredoc

To inspect WordPress runtime state (registered blocks, options, transients) with
PHP, **do not** pipe an inline heredoc into `wp eval-file` — a command like
`printf '... $n[] = $name; ...' | docker compose exec -T wpcli wp eval-file -`
embeds PHP on the command line and trips zsh array/arith expansion permission
prompts. Instead run a bundled PHP file through a wrapper that pipes it over
STDIN (ADR-095).

## list-blocks.sh

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/run/list-blocks.sh"
```

[`list-blocks.sh`](../list-blocks.sh) resolves the repo root via `source-base.sh`
and pipes [`helpers/list-blocks.php`](../helpers/list-blocks.php) into
`wp eval-file -` over STDIN — listing every UCSC block (both `ucsc/*` and
`ucscblocks/*`) in the live registry across all activated plugins, with no PHP
embedded in a shell string.

## wp-eval.sh — generic substrate

For other runtime queries, prefer the generic substrate
[`wp-eval.sh`](../wp-eval.sh) — it locates the root and pipes any
`helpers/<name>.php` to `wp eval-file -`, forwarding `KEY=VAL` args as container
env (`getenv()`), so a new query is just a reviewed PHP file plus a thin `*.sh`
wrapper, never an inline eval.

## block-doctor.sh — diagnose a fallback render

When a dynamic block shows a placeholder or "No X available" and the cause is
unclear, [`block-doctor.sh`](../block-doctor.sh) (PHP in
[`helpers/block-doctor.php`](../helpers/block-doctor.php)) explains it in one
call: it renders the block server-side as the anonymous user and flags whether
the output looks like a fallback, then audits the anonymous permission posture of
every REST route in a namespace. A dynamic block that fetches via its own
`rest_do_request()` endpoints falls back silently when those routes deny
anonymous access during a logged-out frontend render, and this surfaces exactly
which route is the culprit:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/run/block-doctor.sh" ucscblocks/classschedule
```
