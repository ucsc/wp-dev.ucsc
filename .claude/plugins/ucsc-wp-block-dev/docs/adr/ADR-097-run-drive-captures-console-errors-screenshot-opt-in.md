---
title: "ADR-097: Drive captures DOM and console errors; screenshot is opt-in"
status: Accepted
date: 2026-06-24
---

# ADR-097: Drive captures DOM and console errors; screenshot is opt-in

## Context

`run`'s `driver.sh drive` step rendered a frontend URL in headless Chrome and produced two artifacts: a PNG screenshot and a post-JS DOM dump. Confirming a block actually worked therefore meant *reading the screenshot*, which costs image tokens on every drive and is an imprecise signal.

Two gaps:

- A screenshot is the least efficient check. The post-JS DOM dump is already grep-able and proves hydrated markup (`view.js` ran and matched its wrapper selector) far more cheaply.
- Page console output and uncaught JS exceptions were not captured at all. A `view.js` that throws often leaves the server-rendered markup looking fine in the DOM dump, so the failure was only visible — if at all — by eyeballing the screenshot.

Headless Chrome already emits page `console.*` messages and uncaught exceptions to stderr when launched with `--enable-logging=stderr`, in a grep-able form (`[...:CONSOLE(n)]` and `[...:ERROR:CONSOLE(n)]`). This needs no Node/puppeteer dependency, consistent with the plugin's preference against bundling heavy tooling (see ADR-016).

## Decision

`drive` makes the post-JS DOM dump and a console-error capture its primary, token-frugal signals, and demotes the screenshot to opt-in.

- Launch headless Chrome with `--enable-logging=stderr --v=1` and capture that invocation's stderr to `<log>.console`.
- Keep dumping the post-JS DOM to `<log>.dom` for hydrated-markup assertions.
- After driving, count error-level console entries (`ERROR:CONSOLE`). Report a FAIL with the first few offending lines when any are present; otherwise PASS, noting the total console message count and the log path.
- Do **not** write a screenshot by default. Write one only when `UCSC_SHOT=<path>` is set, as a visual fallback for when the DOM/console signals are ambiguous.
- Reading a screenshot costs image tokens, so reserve it for that fallback rather than every run.

## Consequences

- A throwing or erroring `view.js` is caught directly from the console capture instead of relying on a human-read screenshot.
- The default drive path emits only grep-able text (DOM + console), reducing token cost.
- Callers that previously depended on a screenshot path being written by default must set `UCSC_SHOT` explicitly.
- The console log inherits Chrome's verbose stderr; it is written to a dedicated `<log>.console` file and only ever grepped, so the verbosity does not reach the user.
