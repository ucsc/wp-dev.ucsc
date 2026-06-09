# Portable Skill-Plugin Patterns

Conventions and architecture proven in **`ucsc-wp-block-dev`** (a Claude Code
plugin for WordPress/Gutenberg block work), written up for porting into
**`ucsc-laravel-vue-dev`** and any future UCSC plugin. The WordPress specifics
(blocks, Docker, wp-cli) are incidental — the *governance and authoring patterns*
below are domain-agnostic. Each pattern notes how to adapt it for a Laravel + Vue
stack.

> How to use this doc: skim the **Pattern catalog**, adopt the **Core four**
> first (they pay for themselves immediately), then layer the rest as the plugin
> grows. The **Test contracts** section is what keeps all of it from rotting.

---

## What we improved in the last few days (Jun 18–24)

The recent batch of decisions (ADR-081 → ADR-103) and this week's refactors are
the concrete payoff of the patterns below:

- **Progressive-disclosure refactor.** Trimmed the three heaviest skills by moving
  detail into `references/`: `maintainer` 2,868 → ~2,460 words, `hub` 1,846 →
  ~1,440, `run` 1,752 → ~1,250 — with zero behavior change and all test contracts
  still green. The lean body loads on every invocation; the detail loads only when
  the relevant operation runs.
- **ADR naming + traceability convention (ADR-086).** Standardized
  `ADR-NNN-<skill>-<mode>-<detail>.md` filenames and the `implements:` marker that
  ties each skill/script back to the ADRs it realizes, enforced by a checker.
- **ADR consolidation (ADR-086).** Prefer *one ADR per skill/theme* over a stream
  of tiny files; a `retire-adr.sh` helper scripts the deterministic retire/merge
  steps.
- **Orchestrating wrapper scripts (ADR-099).** One script runs a whole battery
  (self-test → reference check → CLI validate) and prints a single PASS/FAIL,
  minimizing tool round-trips and tokens.
- **Lightweight hub (ADR-088/089).** The inventory skill lists capabilities and
  relies on *native* description-based discovery instead of hand-rolled routing.
- **Single-agent default + opt-in heavy checks (ADR-064/075/076).** Token-heavy
  sub-agents never run automatically; usage is logged for retrospective review.
- **Session target contract (ADR-093).** The work target is resolved once and
  reused across every skill in the session.
- **Run/validate/verify stack dependency (ADR-103).** Test skills detect a downed
  runtime and route to the `run` skill instead of failing opaquely.

---

## Core four (adopt these first)

### 1. Progressive disclosure — lean `SKILL.md`, detail in `references/`

A `SKILL.md` body loads into context **every time the skill triggers**, so keep
it lean (target **1,500–2,000 words**, hard cap ~5k). Move anything not needed on
*every* invocation into `references/<topic>.md`, linked from the body with a
one-paragraph stub.

- **Keep in the body:** purpose, the "intake" step, the primary happy-path
  command(s), and a short index of bundled scripts.
- **Move to references:** setup/first-run procedures, diagnostics, gotchas,
  recovery/failure paths, long checklists, deep rationale.
- **Stub pattern:** replace a moved section with 3–5 sentences + a link, e.g.
  `Full workflow:` [references/publish.md](skills/maintainer/references/publish.md).

*Laravel/Vue adaptation:* the same split applies — e.g. a `develop` skill's body
holds the vertical-slice workflow; `references/fields-config.md`,
`references/blade-conventions.md`, `references/migrations.md` hold the detail.

### 2. Every support file is referenced from `SKILL.md` (enforced)

Rule (ADR-032): every file under a skill directory must be named in that skill's
top-level `SKILL.md` (by relative path or basename). This keeps `references/`,
`scripts/`, and `assets/` *discoverable* — nothing becomes orphaned context.

A scanner (`check-skill-references.sh`) prints one line per skill and a PASS/FAIL,
exiting non-zero on any unreferenced file. It runs in the test suite, so a gap
fails CI. When you move a section out, keep a **compact script index** in the body
so wrappers/helpers stay named even though their prose moved.

### 3. ADR-driven governance with `implements:` traceability markers

Decisions live as **Architecture Decision Records** in `docs/adr/`, indexed in
`docs/adr/index.md`. Each skill and script declares the ADRs it realizes via a
marker (full slug, harvested by number):

```
# in SKILL.md (a body line):
implements: ADR-003-LOW-TOKEN, ADR-086-CONVENTIONS

# in a .py/.sh script (a comment line):
# implements: ADR-095-SOURCE-BASE
```

A checker (`check-adr-implements.py`) runs two gates:
- **Reverse (hard):** every ADR named in a marker must resolve to an existing,
  *active* ADR (Accepted/Proposed, not Superseded/Deprecated/Rejected).
- **Forward (coverage):** every active ADR should be implemented by at least one
  skill or script; `--strict` fails on gaps.

Conventions (ADR-086): filename `ADR-NNN-<skill>-<mode>-<detail>.md`; **default to
extending an existing skill's ADR** rather than spawning tiny new ones; retire via
a helper that moves the file to `retired/`, flips status, and drops the index row
(numbers are never reused).

*Laravel/Vue adaptation:* identical. Seed `docs/adr/` with the framework decisions
already implicit in the stack (fieldsConfig consistency, route authorization,
common-framework blast radius, Blade/Vue conventions) so they become enforceable.

### 4. Low-token-first execution

The cheapest correct path wins (ADR-003):
- Prefer **deterministic scripts and CLI checks** over reading many files by hand.
- **Single-agent by default** (ADR-075); spawn sub-agents only for genuine
  parallelism.
- **Agent-backed checks are opt-in** (ADR-064) — never auto-run a token-heavy
  reviewer; offer it after the cheap checks pass.
- **Log token-heavy operations** (ADR-076) for retrospective review.

---

## Pattern catalog

### Skill separation of concerns (ADR-030)
One skill, one job: `develop` (write code), `validate` (automated tests),
`verify` (live behavior evidence), `run` (launch & drive the app), `review`
(diff review). Skills cross-reference but never absorb each other.
*Laravel/Vue:* the same five verbs map cleanly (develop / validate (PHPUnit +
Jest) / verify / run / review).

### Lightweight hub, native routing (ADR-060/061/088/089)
A `hub` skill is an **inventory**, not a router. It prints a static table of
skills + argument hints and lets Claude route natively from each skill's
`description`. It must not scan the filesystem or spawn agents to build itself.
Keep it small — if your hub passes ~1,500 words, it has stopped being an entry
point.

### Launcher + menu (ADR-020, ADR-086)
A bare skill invocation (no mode) **shows a menu and waits** — it never
auto-launches a destructive or token-heavy operation. A small `launcher.md`
resolves the first argument to a mode and dispatches; with no argument it loads a
`skill-menu-mode.md` table. Lead the menu with the durable, safe modes.

### Universal Command Intake (every workflow skill)
Each workflow skill opens by resolving three things from the full input + session
context: the **target**, the **natural-language request**, and an optional
**issue key/URL** (Jira/GitHub). Then: *"ask one concise question only when
missing or conflicting information prevents useful work."* This phrasing is a
test-enforced contract — keep it verbatim across skills.

### Session target contract (ADR-093)
Resolve the work target **once** (explicit arg → persisted session value → cwd
inference → prompt) and persist it so every later skill reuses it without
re-asking. A tiny `session-target.sh set/get` script holds the state.
*Laravel/Vue:* the "target" is the module/feature/route under work.

### Retrospective sub-skill (ADR-059/077/083)
A nested `retrospective/` sub-skill captures session lessons back into the
closest skill, reference, script, test, or ADR — turning one-off discoveries into
durable improvements. Its closing checklist always asks for a **script
candidate**, a **skill-improvement candidate**, and a **token-reduction
candidate**. Run it at session end, not as a task summary.

### Contributed-skill incubation (ADR-038)
New skills flow through tiers kept **outside** live `skills/`: a proposal under
`contrib/proposals/` → review → `contrib/incubator/` → promotion into `skills/`
only after name/trigger/description/support-file checks and tests pass. This keeps
half-baked skills from polluting discovery.

### Inventory sync (ADR-067/080)
The `skills/` directory is the **single source of truth**. A `sync-inventory.sh`
reconciles every place the inventory is duplicated — README, `AGENTS.md` routing
table, hub table, slide deck, and test fixtures — and a `--check` mode fails CI on
drift. Touch the skill set in one place, regenerate the rest.

### Orchestrating wrapper scripts (ADR-099)
Bundle a multi-step routine into one script that runs each step, prints a
per-step PASS/FAIL, and exits non-zero on any failure — instead of issuing the
steps as separate tool calls. Fewer round-trips, fewer tokens, deterministic
output. Example: `run-all-plugin-tests.sh` = self-test + reference check + CLI
validate.

### Two-tier validation (ADR-078/079, ADR-064)
**Tier 1** is the deterministic CLI check (`claude plugin validate --strict
<dir>`) plus the local pytest contracts — always run, cheap. **Tier 2** is the
opt-in Anthropic `plugin-dev` agent review (`plugin-validator`,
`skill-reviewer`) — token-heavy, offered only when deeper qualitative analysis is
wanted. Never fold Tier 2 into the default "health check."

### Generated docs from a source of truth (ADR-045/048)
Don't hand-maintain published docs/slides. **Generate** Markdown artifacts from
the README + ADR index (a `regenerate-docs.sh`), then publish explicitly. Keep the
generator dumb and the *sources* canonical; reconcile inventory/ADR summaries
against the live tree at publish time.

### Frontmatter discipline (ADR-070)
Use only the **official Claude Code skills frontmatter fields** (`name`,
`description`, `when_to_use`, `argument-hint`, `disable-model-invocation`,
`user-invocable`, `allowed-tools`, `model`, `context`, `agent`, …). A test
asserts no off-spec keys and that `description + when_to_use` fit the listing
truncation cap (~1,536 chars). Sensitive skills (those that build/run/mutate)
declare an `allowed-tools` whitelist.

### Shell & path safety (ADR-092, ADR-094, ADR-095)
- macOS zsh + bash 3.2: invoke scripts via `bash <script>`; avoid bash-4 syntax
  (`${var,,}`, `declare -A`, `&>>`, `|&`); **never** put inline `#` comments in
  commands handed to the user (interactive zsh chokes).
- Use harness path variables (`${CLAUDE_PLUGIN_ROOT}`) in script commands.
- Resolve a **source base** and call reusable inspection scripts instead of
  hardcoded paths or ad-hoc `find`.

### Git guardrails (ADR-051–057)
Conventional Commits; offer to commit and to open PRs but **never push**
unprompted; don't inspect parent git repos; GitHub-only PR operations. (In this
project, "never commit/push — the user does it" is a hard rule.)

---

## Test contracts — what keeps it honest

The plugin ships a **pytest suite that tests the plugin itself**, not the product.
This is the load-bearing piece: every pattern above is backed by a test, so drift
fails CI. Categories worth replicating:

| Test area | What it enforces |
|---|---|
| `test_plugin_structure` | skill inventory, required sections/strings per skill, sub-skill references, hub stays product-only |
| `test_skill_references` | every support file is referenced from its `SKILL.md` (ADR-032) |
| `test_adr_integrity` | `implements:` markers resolve to active ADRs; no stale ADR references |
| `test_plugin_validity` | `claude plugin validate` passes; expected skill count; no stray MCP/LSP |
| `test_script_cli_contracts` | bundled scripts implement `--help` with no side effects |
| `test_*` frontmatter | only official fields; description under the truncation cap |

Two gotchas learned the hard way:
1. **Test-pinned strings constrain refactors.** Tests assert exact substrings in
   `SKILL.md` (mode headings, intake phrasing, recipe keywords). When trimming,
   grep the tests first and preserve pinned strings — and watch for a required
   phrase getting **split across a line wrap** (substring match fails on the
   newline).
2. **Run the suite before and after.** Establish a green baseline; a couple of
   contracts have script side-effects (a `--help` that isn't side-effect-free can
   create a stray file and cascade into a coverage failure).

---

## Emerging idea: marker-driven documentation (not yet built)

Extend the `implements:` marker concept into **doc "landmarks/signals."** Today's
generated docs over-describe *how the doc should work* inside the `generate*.md`
files. Instead, place lightweight full-slug markers in skills and scripts at the
spots worth documenting — the same harvesting pattern as `implements:` — and let a
**script** collect them into the generated artifact. The generator stays dumb and
deterministic; the source code carries the signal of what's interesting to
document, right where it's true. Worth a small ADR + a harvester script when you
pick it up.

---

## Adoption checklist for `ucsc-laravel-vue-dev`

1. Stand up `docs/adr/` + `index.md`; write ADR-001 (plugin scope) and seed ADRs
   for the framework rules you already follow (fieldsConfig, route auth,
   common-framework blast radius, Blade/Vue conventions).
2. Add the **Core four**: progressive disclosure, the reference-check scanner,
   the `implements:` checker, and the low-token defaults.
3. Port the **pytest contracts** (structure, references, ADR integrity, frontmatter).
4. Make `hub` lean; give every workflow skill the **Universal Command Intake**
   block and the **session target** contract.
5. Add `launcher.md` + `skill-menu-mode.md` so bare invocations show a menu.
6. Add a `retrospective/` sub-skill and run it at session end.
7. Wrap multi-step routines in **orchestrating scripts** with PASS/FAIL output.
