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
**Generated:** 2026-06-10<br />
**Target Product:** `ucsc-gutenberg-blocks`<br />
**Local Environment:** `wp-dev.ucsc`

---

## **How to Get Started**

> **Full reference:** See the plugin [README](.claude/plugins/ucsc-wp-block-dev/README.md) for complete install, uninstall, reload, and launch-from-source instructions (ADR-013).

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
  * Managed as `ucsc-wp-block-dev` across directory structures, manifests, marketplace registrations, and slash commands.

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

The plugin features **14 skills** — user-invocable commands, block-specific guides, and auto-loaded context:

**User-invocable commands:**

| Skill | Call Trigger | Purpose |
| :--- | :--- | :--- |
| **`start`** | `/ucsc-wp-block-dev:start` | Entry point — identifies the app and routes to the right mode. |
| **`setup`** | `/ucsc-wp-block-dev:setup` | First-time capability overview. |
| **`develop`** | `/ucsc-wp-block-dev:develop` | Guided block creation from scaffold to registration. |
| **`fix`** | `/ucsc-wp-block-dev:fix` | Debugs JS, PHP, REST API, or transient caching bugs. |
| **`test`** | `/ucsc-wp-block-dev:test` | Add or run PHP, Jest, Docker, and browser tests. |
| **`review`** | `/ucsc-wp-block-dev:review` | Review a diff, branch, file, or Jira-scoped change. |
| **`run`** | `/ucsc-wp-block-dev:run` | Handles Docker lifecycle, builds assets, and runs tests. |
| **`menu`** | `/ucsc-wp-block-dev:menu` | Show the mode table mid-session without re-running app detection. |
| **`maintainer`** | `/ucsc-wp-block-dev:maintainer` | Validates plugin structure, runs tests, reviews skill quality. |

**Block-specific guides:**

| Skill | Call Trigger | Purpose |
| :--- | :--- | :--- |
| **`campus-directory`** | `/ucsc-wp-block-dev:campus-directory` | Guides the LDAP-backed Campus Directory block. |
| **`class-schedule`** | `/ucsc-wp-block-dev:class-schedule` | Guides WCSI app embedding and testing server toggles. |
| **`course-catalog`** | `/ucsc-wp-block-dev:course-catalog` | Guides AIS PeopleSoft XML integration and caching. |

**Auto-loaded / internal:**

| Skill | Visibility | Purpose |
| :--- | :--- | :--- |
| **`blocks`** | Auto-loaded context | Domain reference loaded when editing files in the WP plugin. |
| **`issue-context`** | Internal | Resolves Jira or user-supplied issue context into an implementation brief. |

---

## **Skill: Develop (`/ucsc-wp-block-dev:develop`)**

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

## **Skill: Fix (`/ucsc-wp-block-dev:fix`)**

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

## **Skill: Run (`/ucsc-wp-block-dev:run`)**

Commands driving block compilation, container health, and unit tests:

* **Build Lifecycle:**
  * Build for production: `npm run build` (creates `build/index.js` + `build/index.asset.php`).
  * Rebuild continuously during development: `npm start` (watch mode).
* **Docker Operations:**
  * Start development stack: `docker compose up -d` (accessible on port `8080`).
  * Activate plugin: `docker compose exec wpcli wp plugin activate ucsc-gutenberg-blocks`.
* **Testing Execution:**
  * Execute Jest testing harness inside container:
    `docker compose run --rm -w /var/www/html/wp-content/plugins/ucsc-gutenberg-blocks plugin_npm_start npm test`

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

## **Blocks Reference & Maintainer Skills**

* **`blocks` (Auto-loaded Domain Knowledge):**
  * Silent assistant injected by Claude Code when touching files under the target directory.
  * Details layout mapping (classes, templates, assets) and runtime integrations:
    * *Class Schedule:* Registers REST endpoints at `ucscgutenbergblocks/v1`.
    * *Course Catalog:* Connects to PeopleSoft XML endpoint (caches via transients).
    * *Campus Directory:* Accesses LDAP using network options.
* **`maintainer` (Plugin Self-Upkeep):**
  * Launches Anthropic’s `plugin-dev:plugin-validator` and `plugin-dev:skill-reviewer` agents.
  * Invokes `plugin-dev:skill-development` for guidance when writing or refactoring skills.
  * Triggers pytest suite (verifying manifest, frontmatter constraints, and index consistency).
  * See the plugin [README](.claude/plugins/ucsc-wp-block-dev/README.md) for plugin-dev tool install and usage (ADR-013).
* **Architecture Decision Records (ADRs):**
  * Live in `docs/adr/` with an index at `docs/adr/index.md`.
  * Each ADR captures a design decision, its context, and consequences.
  * Current ADRs cover plugin scope, token efficiency, validation workflow, frontmatter conventions, command intake patterns, and more.
  * Create new ADRs via the maintainer skill or by adding files directly to `docs/adr/`.

---

## **Block-Specific Skills (Part 1)**

### **Campus Directory (`/ucsc-wp-block-dev:campus-directory`)**
* **Target Files:** `classes/CampusDirectory.php`, `classes/CampusDirectoryAPI.php`, `templates/*Directory*`, `src/blocks/CampusDirectory.js`.
* **Features:** LDAP queries, `/directory/<cruzid>/` rewrite rules, and local anonymous binds.
* **Publish Lock:** JavaScript locking to block post saving if automated feeds are active but filters are empty.

### **Class Schedule (`/ucsc-wp-block-dev:class-schedule`)**
* **Target Files:** `classes/ClassSchedule.php`, `src/blocks/ClassSchedule.js`.
* **Features:** Embeds WCSI scheduling app JS/CSS bundles.
* **Staging Toggle:** Displays staging checkbox dynamically for local development.

---

## **Block-Specific Skills (Part 2)**

### **Course Catalog (`/ucsc-wp-block-dev:course-catalog`)**
* **Target Files:** `classes/CourseCatalog.php`, `src/blocks/CourseCatalog.js`, tablesorter assets.
* **AIS/PeopleSoft Integration:** Queries AIS HttpListeningConnector using XML payloads and custom target headers.
* **Performance Cache:** XML body is cached using WordPress transients for **one week** (`WEEK_IN_SECONDS`).
* **Table UI:** Supports client-side sorting via `tablesorter.js` with hidden integer spans for division sorting, and collapsible description rows.

---

## **Slide Publishing Workflow**

Automated pipeline to compile and deploy these presentation slides to Google Docs:

* **Source:** `ucsc_wp_block_dev_presentation.md` (Marp Markdown, this file) in the project root.
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
* **Generated date:** Update the `Generated:` field on the title slide before each publish (ADR-015).

---

## **The Codex Wrapper (`.agents/codex.sh`)**

Integrates the Claude Code plugin with the OpenAI Codex agent environment:

* **Why it is needed:** Claude Code and Codex consume plugins differently. The wrapper automates packaging the same source files for both systems.
* **What `codex.sh` performs:**
  1. **Syncs Skills:** Copies all skills from `.claude/plugins/ucsc-wp-block-dev/skills/` to `.agents/plugins/ucsc-wp-block-dev/skills/` via `rsync`.
  2. **Translates Manifests:** Reads Claude's `plugin.json` and writes a Codex-compatible version containing fields like `capabilities`, `displayName`, and `defaultPrompt`.
  3. **Local Registration:** Adds the local marketplace defined in `.agents/plugins/marketplace.json` and installs the plugin in Codex:
     * `codex plugin marketplace add`
     * `codex plugin add ucsc-wp-block-dev@ucsc-wordpress-local`
