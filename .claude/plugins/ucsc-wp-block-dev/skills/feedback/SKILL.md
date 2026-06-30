---
name: feedback
description: This skill should be used when the user asks to "submit feedback", "send feedback", "give feedback about a skill", "report a bug in the plugin", "report a problem with run/validate/verify", "file a suggestion for ucsc-wp-block-dev", or invokes `:feedback`. It is the plugin analog of Claude Code's /bug — it collects a note plus session context and delivers it to a configured destination. Not for the WordPress ucscblocks/feedback block (that is product code; use develop).
version: 0.1.0
argument-hint: "[bug|idea|question] [note]"
---

# Feedback — report a bug or suggestion about the plugin

<!-- doc-slide: The plugin's own `/bug`: captures a note plus session context and routes it to the configured destination. -->

## Implements

implements: ADR-100-FEEDBACK-SUBMIT

The plugin analog of Claude Code's `/bug`: collect a short note about the
`ucsc-wp-block-dev` skills plus a little session context, and deliver it to a
configured destination. This is feedback **about the plugin's own skills**, not
the WordPress `ucscblocks/feedback` block — for that block's code use `develop`.

## When to use

Use `feedback` when the user wants to report a bug, rough edge, or idea about a
plugin skill (`run`, `validate`, `verify`, `develop`, etc.) — not to change block
code and not to run tests. It performs no routing and never edits the codebase;
its only effect is delivering or saving a feedback note.

## Collect the note

Obtain a short free-text note. Confirm or infer three optional fields without
interrogating the user:

- **category** — `bug`, `idea`, `question`, or `other` (default `other`).
- **skill** — the skill the feedback concerns, when clear from context.
- **target** — the block target in play, when one is set this session.

Ask one concise question only when the note itself is missing.

## Deliver

Run the bundled script — it builds the payload, always saves a local copy first,
then delivers through the first configured channel (ADR-100):

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/feedback/scripts/submit-feedback.sh" \
  -m "<note>" [-c bug|idea|question|other] [-s <skill>] [-t <target>]
```

Add `--dry-run` to build and show the payload without sending. Relay the
script's outcome: delivered (endpoint HTTP 2xx or emailed), or saved locally with
the path when no channel is configured.

- [`scripts/submit-feedback.sh`](scripts/submit-feedback.sh) — collect, package, and deliver the feedback note (ADR-100).

## Configure the destination

Delivery is environment-driven; nothing is hardcoded. Channels are tried in
order (endpoint → email → local-only):

| Variable | Purpose |
|---|---|
| `UCSC_FEEDBACK_ENDPOINT` | REST URL accepting `POST application/json` |
| `UCSC_FEEDBACK_TOKEN` | optional bearer token for the endpoint |
| `UCSC_FEEDBACK_EMAIL` | destination address used when no endpoint is set |
| `UCSC_FEEDBACK_FROM` | optional `From` address for the email channel |
| `UCSC_WP_BLOCK_DEV_CACHE` | cache dir for saved copies (default `~/.cache/ucsc-wp-block-dev`) |

To persist configuration across sessions, add these variables to the gitignored
project-root `.env`. The script loads that file automatically; set
`UCSC_WP_BLOCK_DEV_ENV_FILE` to use another private env file. Never hardcode a
real endpoint, address, or token in the skill.

## Privacy

Only these fields are sent: the note, category, named skill/target, plugin
version, timestamp, and OS string. **No local paths, branch names, file contents,
diffs, or conversation transcripts are included.** State this if the user asks
what leaves the machine.
