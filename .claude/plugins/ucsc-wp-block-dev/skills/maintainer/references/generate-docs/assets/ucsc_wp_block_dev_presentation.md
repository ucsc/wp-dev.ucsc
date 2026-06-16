<!-- Generated: 2026-06-15 from skills/maintainer/assets/ucsc_wp_block_dev_presentation.md -->

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

# **UCSC WordPress Block Development Toolkit**
### *A Unified Claude Code & Codex Plugin for Gutenberg Block Engineering*

**Presented by:** UCSC ITS<br />
**Date:** June 2026<br />
**Generated:** 2026-06-15<br />
**Target Product:** `ucsc-gutenberg-blocks`<br />
**Local Environment:** `wp-dev.ucsc`

---

## **How to Get Started**

> **Full reference:** See the plugin [README](../../../../../README.md) for complete install, uninstall, reload, and launch-from-source instructions (ADR-013).

* **Installation (Project Scope):**
  ```bash
  claude plugin install ucsc-wp-block-dev@ucsc-wordpress --scope project
  ```
* **Uninstallation:**
  ```bash
  claude plugin uninstall ucsc-wp-block-dev --scope project
  ```
* **Reloading Plugins:** Run `/reload-plugins` inside Claude Code to apply updates and reload skills. Use `/reload-plugins --force` if MCP tools changed.
* **Launch from Source:** `claude --plugin-dir .claude/plugins/ucsc-wp-block-dev`
* **Workspace Context:**
  * You can run `claude` from **any directory inside the project tree** (including subdirectories).
  * Claude Code automatically traverses parent directories to locate the `.claude/` configuration folder and load the project-scoped plugin.
  * Running `claude` outside the repository tree will not load the plugin.

---

## **Local Environment Setup (`wp-dev.ucsc`)**

* **Hosts Mapping:** Edit `/etc/hosts` to point `127.0.0.1` to `wp-dev.ucsc`.
* **Themes & Plugins setup:** Run `./setup.sh` to clone product repos.
* **Dependencies & Init (Docker):**
  * `docker compose -f docker-compose-install.yml run theme_composer_install`
  * `docker compose -f docker-compose-install.yml run theme_npm_install`
  * `docker compose -f docker-compose-install.yml run plugin_npm_install`
  * `docker compose -f docker-compose-install.yml run wordpress_install`
* **Local Dashboard:** `https://wp-dev.ucsc/wp-admin` (Login: `admin` / `password`).

---

## **Project Context & Scope**

* **Eliminating Multi-Stack Noise:**
  * Previously, Gutenberg block development skills were hosted in the multi-stack `sw-dev` plugin (Laravel/Vue/WordPress).
  * Block skills were decoupled into a standalone plugin to eliminate irrelevant Laravel/Vue noise.
* **Single Source of Truth:**
  * The new plugin `ucsc-wp-block-dev` owns all guidance and skills for Gutenberg block development at UCSC ITS.
* **Canonical Plugin ID:**
  * Managed as `ucsc-wp-block-dev` across directory structures, manifests, marketplace registrations, and skill adapters.

---

## **Target Architecture & Stack**

* **Codebase Target:** 
  * `public/wp-content/plugins/ucsc-gutenberg-blocks/` (WordPress plugin version 1.1.29).
* **The Stack:**
  * **Build System:** `@wordpress/scripts` (Webpack-based compilation & asset management).
  * **PHP Classes:** Located under `classes/` (one class per block or external integration).
  * **Templates:** Located under `templates/` (separates PHP markup rendering from core logic).
  * **Block JS:** Located under `src/blocks/` (edit/save/registration).
* **Runtime Sandbox:** 
  * Run and tested via the Docker-based local environment `wp-dev.ucsc`.

---

## **Core Philosophy: Low Token Use**

* **Efficiency & Reliability Constraints:**
  * **Lean Skills:** `SKILL.md` files are kept short and imperative. Detailed domain mapping is progressively disclosed in `references/`.
  * **Minimal Context Spans:** Prefers targeted commands and scanner scripts over instructions that read entire files.
  * **Inline Direct Actions:** Executes workflows inline via direct tool calls. Subagents are only spawned when absolutely necessary (e.g., Anthropic's validator).
  * **No Redundancy:** Replaces exploratory searches and repeated file reads with structured step-by-step logic.

---

## **The Plugin Skills Landscape**

The plugin features **11 portable skills** plus progressively disclosed shared
references:

**Workflow skills:**

| Skill | Trigger | Purpose |
| :--- | :--- | :--- |
| **`map`** | Unclear workflow or target | Entry point — identifies the app and routes to the right skill. |
| **`feature`** | New behavior | Preferred feature workflow. |
| **`develop`** | Existing development workflow | Compatibility workflow during migration. |
| **`fix`** | Bug or regression | Debugs JS, PHP, REST API, or transient caching bugs. |
| **`test`** | Test creation or execution | Creates or runs PHP, Jest, or end-to-end tests. |
| **`review`** | Review request | Reviews a diff, branch, file, or Jira-scoped change. |
| **`run`** | Build or launch request | Records and executes the Docker setup, build, launch, and app-driving recipe. |
| **`verify`** | Acceptance verification | Proves a change in the running WordPress editor or frontend. |

**Hidden reference material:**

| Reference | Visibility | Purpose |
| :--- | :--- | :--- |
| **`develop/references/domain/blocks.md`** | Progressive disclosure | Domain reference loaded by workflow skills when working on the WP plugin. |
| **`maintainer/references/generate-docs/generate-docs.md`** | Progressive disclosure | Documentation regeneration reference owned by the maintainer workflow. |

**Hidden manual skill:** type `maintainer` directly for plugin maintenance,
validation, contribution review, reference checks, and slide publishing.

`develop/references/issue-context.md` is shared by `develop`, `feature`, and
`fix` when Jira, Confluence, or pasted issue context is present.

Block-specific target guidance lives under `develop/references/targets/`.
`develop` requires a target and loads only the selected reference.

---

## **Skill Map**

`map` identifies the active WordPress app and routes targets, natural-language requests, and optional Jira context into the portable skill set (ADR-039):

| Skill | Outcome |
| :--- | :--- |
| **Develop** | Add or change Gutenberg block behavior. |
| **Fix** | Diagnose and repair a block problem. |
| **Test** | Create or run PHP, Jest, or end-to-end tests. |
| **Review** | Review a diff, branch, file, block, or Jira change. |
| **Run** | Build, launch, and drive `wp-dev.ucsc`. |
| **Verify** | Confirm behavior in the running editor or frontend. |
| **Documentation** | Regenerate portable Markdown guide and slide-deck artifacts. |
| **Maintainer** | Validate, test, review, and publish this plugin. |

---

## **Skill: Develop**

Provides a guided developer experience for introducing new Gutenberg blocks:

1. **Clarify Scope:** Confirm block name, render model (dynamic/static), data dependencies, and required block attributes.
2. **PHP Block Class:** Create `classes/<BlockName>.php`. Set constructor to hook block registration into `init` (never register directly in constructor).
3. **Render Template:** Create `templates/<block-name>.php` to contain HTML markup.
4. **Editor UI:** Write `src/blocks/BlockName.js` using `wp.blocks.registerBlockType` and export the init function.
5. **Registration:** Import and run block in `src/index.js` and instantiate PHP class in `index.php`.

---

## **Gutenberg References & Best Practices**

* **Reference Manuals:**
  * **Block Editor Handbook:** `developer.wordpress.org/block-editor/` (official API specifications, controls, attributes).
  * **Block Development Examples:** `github.com/WordPress/block-development-examples` (official repository containing clean design patterns, panels, and component templates).
* **Core Practices:**
  * **API Caching:** CP standards require caching API/external XML lookups.
  * **UI Components:** Reuse standard `@wordpress/components` (PanelBody, TextControl, ToggleControl, SelectControl) to match the native editor styling.
  * **Templating:** Decouple HTML markup from core class PHP code by loading external files under `templates/`.

---

## **Skill: Fix**

Systematic flowchart for diagnosing and resolving faults in the block codebase:

* **Reproduce First:** Leverage unit tests, compiler logs, browser console exceptions, and container logs (`docker compose exec wpcli wp --debug`).
* **Pinpoint the Layer:**
  * *Inserter bugs* $\rightarrow$ JS registration.
  * *Rendering failures* $\rightarrow$ PHP render callbacks.
  * *Missing data* $\rightarrow$ REST routes or LDAP binds.
* **Transient & Cache Caveats:** Flush cache when data changes aren't reflected:
  `docker compose exec wpcli wp transient delete --all`
* **Local LDAP:** Binds anonymously when `DOCKER_DEV=docker_dev` environment flag is active.

---

## **Skill: Run**

Recorded commands driving clean setup, block compilation, container health, and the live app:

* **Fast path (`driver.sh`):** `skills/run/driver.sh all` runs inspect → build → launch → smoke in one token-frugal call with a compact PASS/FAIL summary; verbose output goes to a logfile (ADR-003). Subcommands: `inspect | build | launch | smoke | all | down`.
* **Build Lifecycle:**
  * Build for production: `npm run build` (creates `build/index.js` + `build/index.asset.php`).
  * Rebuild continuously during development: `npm start` (watch mode).
* **Docker Operations:**
  * Start development stack: `docker compose up -d`.
  * Activate plugin: `docker compose exec wpcli wp plugin activate ucsc-gutenberg-blocks`.
* **Testing Execution:**
  * Execute Jest testing harness inside container: `docker compose run --rm -w /var/www/html/wp-content/plugins/ucsc-gutenberg-blocks plugin_npm_start npm test`
* **Live App:** Open `https://wp-dev.ucsc/wp-admin/`, log in, and drive the requested editor or frontend interaction.

---

## **Skill: Verify**

Builds and launches from the recorded `run` recipe, then verifies acceptance criteria against the live WordPress application:

* **Deterministic gate (`driver.sh`):** `skills/verify/driver.sh <block-slug>` confirms the change is built, active, and server-side registered (optional `--url` / `--needle` render check) — a gate, not proof.
* Uses the editor or frontend rather than substituting Jest, PHP tests, lint, or type checks.
* Exercises the requested block interaction and inspects runtime console or network behavior when relevant.
* Reports each criterion as pass or fail, including the route used and any environmental limitation.

---

## **VS Code Debugging with Xdebug**

* **Xdebug Port:** Container is configured to expose Xdebug port `9003`.
* **Path Mapping:** Map container folder `/var/www/html/wp-content/plugins/ucsc-gutenberg-blocks` directly to `${workspaceRoot}` in `launch.json`.
* **VS Code Launch Configuration:**
  ```
  {
    "name": "Listen for Xdebug",
    "type": "php",
    "request": "launch",
    "port": 9003,
    "pathMappings": {
      "/var/www/html/wp-content/plugins/ucsc-gutenberg-blocks": "${workspaceRoot}"
    },
    "hostname": "wp-dev.ucsc"
  }
  ```

---

## **Domain Reference & Maintainer Skills**

* **`develop/references/domain/blocks.md` (Hidden Domain Knowledge):**
  * Progressive reference loaded by workflow skills when touching files under the target directory.
  * Details layout mapping (classes, templates, assets) and runtime integrations:
    * *Class Schedule:* Registers REST endpoints at `ucscgutenbergblocks/v1`.
    * *Course Catalog:* Connects to PeopleSoft XML endpoint (caches via transients).
    * *Campus Directory:* Accesses LDAP using network options.
* **`maintainer` (Hidden Plugin Self-Upkeep):**
  * Manually reachable by typing `maintainer`, but omitted from the public workflow list.
  * Launches Anthropic’s `plugin-dev:plugin-validator` and `plugin-dev:skill-reviewer` agents.
  * Invokes `plugin-dev:skill-development` for guidance when writing or refactoring skills.
  * Runs `check-references` to enforce that every skill support file is linked from its `SKILL.md` (ADR-032).
  * Triggers pytest suite (verifying manifest, frontmatter constraints, and index consistency).
  * See the plugin [README](../../../../../README.md) for plugin-dev tool install and usage (ADR-013).
* **`maintainer/references/generate-docs/generate-docs.md` (Portable Markdown Artifacts):**
  * Regenerates the main guide and slide deck as Markdown under `skills/maintainer/references/generate-docs/assets/`.
  * Keeps publishing separate; use `maintainer publish-slides` only for Google Docs upload.
* **Architecture Decision Records (ADRs):**
  * Live in `docs/adr/` with an index at `docs/adr/index.md`.
  * Each ADR captures a design decision, its context, and consequences.
  * Current ADRs cover plugin scope, token efficiency, validation, command intake, slide governance, dependency policy, and cross-agent packaging.
  * Update the ADR index whenever a decision is added or superseded.
* **Recent deck and distribution decisions:**
  * **ADR-013:** README is the canonical first-time user reference.
  * **ADR-014:** The deck documents every top-level skill and command.
  * **ADR-015:** Refresh the `Generated:` date before publishing.
  * **ADR-016:** Do not bundle Python environments or dependencies in the plugin.
  * **ADR-017:** `.agents` links to `.claude` skill source instead of maintaining copies.
  * **ADR-018:** The deck is a maintainer-owned asset with one canonical source path.
  * **ADR-032:** Every skill support file must be referenced from its `SKILL.md`.
  * **ADR-033:** Work-list state is stored under `CLAUDE_CONFIG_DIR`, not in the repo.
  * **ADR-044:** Domain guidance lives under `develop/references/domain/`.
  * **ADR-045:** Documentation generation lives under `maintainer/references/generate-docs/`.
  * **ADR-046:** Maintainer is a hidden manual skill.
  * **ADR-047:** Warn before editing on `main`, `master`, or `develop`.

---

## **Block-Specific References (Part 1)**

### **Campus Directory**
* **Target Files:** `classes/CampusDirectory.php`, `classes/CampusDirectoryAPI.php`, `templates/*Directory*`, `src/blocks/CampusDirectory.js`.
* **Features:** LDAP queries, `/directory/<cruzid>/` rewrite rules, and local anonymous binds.
* **Publish Lock:** JavaScript locking to block post saving if automated feeds are active but filters are empty.

### **Class Schedule**
* **Target Files:** `classes/ClassSchedule.php`, `src/blocks/ClassSchedule.js`.
* **Features:** Embeds WCSI scheduling app JS/CSS bundles.
* **Staging Toggle:** Displays staging checkbox dynamically for local development.

---

## **Block-Specific References (Part 2)**

### **Course Catalog**
* **Target Files:** `classes/CourseCatalog.php`, `src/blocks/CourseCatalog.js`, tablesorter assets.
* **AIS/PeopleSoft Integration:** Queries AIS HttpListeningConnector using XML payloads and custom target headers.
* **Performance Cache:** XML body is cached using WordPress transients for **one week** (`WEEK_IN_SECONDS`).
* **Table UI:** Supports client-side sorting via `tablesorter.js` with hidden integer spans for division sorting, and collapsible description rows.

---

## **Slide Publishing Workflow**

Automated pipeline to compile and deploy these presentation slides to Google Docs:

* **Source:** `.claude/plugins/ucsc-wp-block-dev/skills/maintainer/assets/ucsc_wp_block_dev_presentation.md` (Marp Markdown, this file).
* **Script:** `.claude/scripts/publish_to_gdoc.py` — converts Marp Markdown to styled HTML and uploads to Google Drive.
* **How it works:**
  1. Strips Marp frontmatter (theme, style, pagination config).
  2. Converts slide breaks (`---`) to `<hr>` separators.
  3. Renders Markdown to HTML via the `markdown` Python library (with `extra` and `tables` extensions).
  4. Wraps the HTML in a styled template (Arial font, blue headings, bordered tables).
  5. Uploads to Google Drive using the Drive API's `files().update` to overwrite the existing Google Doc.
  6. Google Drive automatically converts the uploaded HTML into native Google Docs format.
* **Authentication (three methods, tried in order):**
  1. `gcloud auth application-default login` with Drive scope (easiest).
  2. GCP Service Account JSON key (`service_account.json` next to the script).
  3. Desktop OAuth client flow (`credentials.json` / `token.json` next to the script).
* **Dependencies:** Auto-installed into a `.venv` next to the script: `markdown`, `google-api-python-client`, `google-auth-httplib2`, `google-auth-oauthlib`.
* **Publish command:**
  ```bash
  python3 .claude/scripts/publish_to_gdoc.py --doc "https://docs.google.com/document/d/18Ozi1BJ60eH2_-mX5rpA08YsLtFwUAHC0nMErhsCxwo/edit"
  ```
  This is also the implementation behind the maintainer `publish-slides`
  operation.
* **One-call refresh + publish:** `skills/maintainer/scripts/refresh_and_publish_slides.sh` bumps the `Generated:` date to today, runs the deck-contract tests, then publishes — automating the manual steps below (ADR-003/014/015).
* **Generated date:** Update the `Generated:` field on the title slide before each publish (ADR-015).

---

## **Future Roadmap**

Roadmap themes are drawn from accepted and study-oriented ADRs so planning stays tied to recorded decisions:

* **Measure fix-mode token reduction** — establish benchmarks, compare evidence funnels, and preserve correctness gates while reducing loaded instruction size (ADR-026).
* **Evaluate GitHub and Atlassian MCP startup cost** — compare fallback-only, on-demand, and always-on strategies for PR/Jira workflows (ADR-027/ADR-034).
* **Keep MCP activation just-in-time** — continue avoiding default GitHub/Atlassian MCP startup unless task value outweighs session cost (ADR-028).
* **Refine feature-branch safety** — make branch warnings and `dev/developer_name/ISSUE-1234_short_desc` guidance easy to follow without automating Git by default (ADR-047).
* **Grow references before skills** — prefer progressive references for domain, target, test, and documentation knowledge until a genuinely user-facing workflow emerges (ADR-040/041/042/044/045).

---

## **The Codex Wrapper (`.agents/codex.sh`)**

Integrates the Claude Code plugin with the OpenAI Codex agent environment:

* **Why it is needed:** Claude Code and Codex consume plugins differently. The wrapper automates packaging the same source files for both systems.
* **What `codex.sh` performs:**
  1. **Links Skills:** Creates `.agents/plugins/ucsc-wp-block-dev/skills` as a symlink to the canonical `.claude` skill source (ADR-017).
  2. **Validates Manifests:** Confirms Claude and Codex plugin names and base versions match.
  3. **Local Registration:** With `--install`, adds the local marketplace and installs the plugin in Codex:
     * `codex plugin marketplace add`
     * `codex plugin add ucsc-wp-block-dev@ucsc-wordpress-local`
