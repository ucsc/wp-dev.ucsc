<!-- Generated: 2026-06-25 from skills/maintainer/assets/ucsc-wp-block-dev-presentation.md -->
<!-- source-hash: 604e2e6f18ca103c822484af4d253e02d0aed14eb13e73b497800311d7f7a050 -->

---
marp: true
theme: gaia
_class: lead
paginate: true
backgroundColor: #0f172a
color: #f8fafc
style: |
  section {
    font-family: 'Outfit', 'Inter', sans-serif;
    padding: 40px;
    font-size: 1.6rem;
  }
  h1 {
    color: #38bdf8;
  }
  h2 {
    color: #e2e8f0;
    border-bottom: 2px solid #38bdf8;
  }
  footer {
    font-size: 0.8rem;
    color: #64748b;
  }
  code {
    background-color: #1e293b;
    color: #f1f5f9;
  }
  a {
    color: #38bdf8;
  }
---

<!--
This is the canonical Marp slide deck (ADR-018). It is a Markdown file where each
`---` starts a new slide ("page"). Hand-authored framing slides live here; the two
AUTO regions below are regenerated from the live skills and ADRs by
`skills/maintainer/scripts/build-slides.py` (ADR-106). Do not hand-edit inside the
AUTO markers — your edits will be overwritten on the next `docs` run.
-->

# **`SLIDES`**

# **UCSC WordPress Block Development Toolkit**
### *A guided tour of the `ucsc-wp-block-dev` Claude Code plugin*

**Slides** · **Presented by:** UCSC ITS<br />
**Generated:** 2026-06-25<br />
**Target Product:** `ucsc-gutenberg-blocks` · **Local Environment:** `wp-dev.ucsc`

> Built for Claude Code; the same skills also run via natural-language invocation
> from Codex, GitHub Copilot, and Gemini CLI (via the bundled `AGENTS.md`).
> For install and day-to-day use, see the companion **Guide**, not these slides.

---

## **What This Plugin Is**

* **A skills-only plugin.** No agents, hooks, or MCP servers ship in it — only
  skills. Behavior is expressed as skills plus the references they progressively
  disclose.
* **Backed by deterministic scripts.** The heavy lifting runs in committed
  scripts — `run/driver.sh`, `sync-inventory.sh`, `check-*.py`,
  `build-slides.py` — so skills stay short and token-frugal (ADR-003).
* **Self-learning and continuously improving.** The hidden **`retrospective`**
  mode (reached via `maintainer retro`) captures each session's lessons back into
  the closest skill, reference, script, test, or ADR (ADR-083).
* **Governed by ADRs.** Every behavior traces to an Architecture Decision Record
  through `implements:` markers, checked by a test (ADR-086).

---

## **Design Patterns (ADR-Driven)**

The plugin is built from a small set of repeating, test-enforced patterns:

* **Low token use (ADR-003)** — lean `SKILL.md`, scanners over file reads,
  single-pass wrapper scripts.
* **Single-agent default (ADR-075)** — inline tool calls; subagents only when a
  task genuinely needs parallelism.
* **`implements:` traceability (ADR-086)** — full-slug markers tie skills and
  scripts to the decisions they realize; `check-adr-implements.py` harvests them.
* **Marker-driven docs (ADR-106)** — the per-skill slides that follow are
  harvested from `doc-slide:` landmarks in each `SKILL.md`.
* **Inventory as source of truth (ADR-067, ADR-080)** — `skill-tree.json` drives
  the README, hub, deck, `AGENTS.md`, and tests via `sync-inventory.sh`.

---

<!-- BEGIN AUTO:skills -->

## **The Skills**

One slide per public skill, harvested from `skill-tree.json` and the `doc-slide:` landmark in each `SKILL.md` (ADR-106).

---

## Skill: `hub` &nbsp; `[block]`

Lists the plugin's skills and sets the session block target so later skills reuse it — it inventories, it does not route.

---

## Skill: `develop` &nbsp; `[feature|fix] [block] [request]`

Adds or modifies block code — `feature` plans and builds new behavior, `fix` reproduces and repairs a described defect.

**Modes:**

* `feature` — implement planned block behavior
* `fix` — diagnose and repair a block defect

---

## Skill: `feedback` &nbsp; `[bug|idea|question] [note]`

The plugin's own `/bug`: captures a note plus session context and routes it to the configured destination.

---

## Skill: `review` &nbsp; `[target] [focus]`

Reviews a diff, branch, PR, or file for bugs, security, accessibility, and missing tests before you ship.

---

## Skill: `run` &nbsp; `[block] [change|URL]`

Launches and drives the wp-dev.ucsc Docker stack through one token-frugal driver to see a change working.

---

## Skill: `validate` &nbsp; `[php|jest|e2e|all] [create|run] [target]`

Creates or runs the PHP, Jest, and e2e suites — `all` runs them sequentially in a single agent.

**Modes:**

* `php` — create or run PHP tests
* `jest` — create or run Jest tests
* `e2e` — create or run browser-driven tests
* `all` — run PHP, Jest, and E2E sequentially

---

## Skill: `verify` &nbsp; `[block] [criterion]`

Confirms one acceptance criterion in the live editor or frontend — a behavioral gate, never a stand-in for tests.

---

## Skill: `maintainer` &nbsp; `[mode] [submode|target]`

Maintains the plugin itself — ADRs, skills, self-tests, docs, and release readiness; it never touches block code.

**Modes:**

* `backlog` — build the personal and unimplemented-ADR backlog
* `adr` — author, retire, inspect, and reconcile ADRs
* `skill` — maintain plugin skills, references, scripts, and inventory
* `training` — study upstream patterns and apply relevant lessons
* `retro` — capture reusable session lessons
* `self-test` — run pytest contracts and deterministic plugin checks
* `validate` — run structural validation; Tier 2 is opt-in
* `docs` — regenerate portable guide+slides Markdown (publish is the optional final step)
* `all` — run the deterministic maintainer health checks

<!-- END AUTO:skills -->

---

<!-- BEGIN AUTO:roadmap -->

## **Roadmap — Proposed ADRs**

Future direction lives as **Proposed** ADRs; each graduates to Accepted when it is built. Harvested live from `docs/adr/index.md` (ADR-048, ADR-106).

* **ADR-105** — Support multiple WP local runtimes (wp-env, Local, WP Engine) beyond home-rolled wp-dev.ucsc

<!-- END AUTO:roadmap -->

---

## **Learn More**

* **Guide:** install, uninstall, reload, and launch-from-source instructions live
  in the plugin **Guide** (generated from `README.md`).
* **ADRs:** the full decision history is in `docs/adr/` with an index at
  `docs/adr/index.md`.
* **Maintain it:** run `/ucsc-wp-block-dev:maintainer` — `docs` regenerates these
  slides and the guide, `retro` captures new lessons, `all` runs the health
  checks.
