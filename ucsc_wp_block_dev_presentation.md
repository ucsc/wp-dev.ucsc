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
**Target Product:** `ucsc-gutenberg-blocks`<br />
**Local Environment:** `wp-dev.ucsc`

---

## **How to Get Started**

* **Installation (Project Scope):**
  ```bash
  claude plugin marketplace add ./.claude --scope project
  claude plugin install ucsc-wp-block-dev@ucsc-wordpress --scope project
  ```
* **Uninstallation:**
  ```bash
  claude plugin uninstall ucsc-wp-block-dev --scope project
  ```
* **Reloading Plugins:** Run `/reload-plugins` inside Claude Code to apply updates and reload skills.
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

The plugin features **8 skills** (5 tool commands, 3 custom block guides, and 1 auto-loaded context):

| Skill | Call Trigger | Purpose |
| :--- | :--- | :--- |
| **`develop`** | `/ucsc-wp-block-dev:develop` | Guided block creation from scaffold to registration. |
| **`fix`** | `/ucsc-wp-block-dev:fix` | Debugs JS, PHP, REST API, or transient caching bugs. |
| **`run`** | `/ucsc-wp-block-dev:run` | Handles Docker lifecycle, builds assets, and runs tests. |
| **`blocks`** | *Auto-loaded context* | Loaded automatically when editing files in the WP plugin. |
| **`maintainer`**| `/ucsc-wp-block-dev:maintainer`| Validates plugin manifest structure and runs tests. |
| **`campus-directory`**| `/ucsc-wp-block-dev:campus-directory`| Guides the LDAP-backed Campus Directory block. |
| **`class-schedule`**| `/ucsc-wp-block-dev:class-schedule`| Guides WCSI app embedding and testing server toggles. |
| **`course-catalog`**| `/ucsc-wp-block-dev:course-catalog`| Guides AIS PeopleSoft XML integration and caching. |

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
  * Launches Anthropic’s `plugin-dev:plugin-validator` validator agent.
  * Triggers pytest suite (verifying manifest, frontmatter constraints, and index consistency).

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

Automated pipeline to compile and deploy these presentation slides:

* **Source Material:** Project root [ucsc_wp_block_dev_presentation.md](file:///Users/henryh/_code/_campuspress/wp-dev.ucsc/ucsc_wp_block_dev_presentation.md).
* **Local Compilation:** Custom script [.claude/scripts/publish_to_gdoc.py](file:///Users/henryh/_code/_campuspress/wp-dev.ucsc/.claude/scripts/publish_to_gdoc.py) converts Marp Markdown to standard styled HTML.
* **Authentication:** Headless verification using a GCP Service Account key ([service_account.json](file:///Users/henryh/_code/_campuspress/wp-dev.ucsc/.claude/scripts/service_account.json)) with Google Drive and Docs APIs enabled.
* **Deployment CLI:** Overwrites the live Google Doc via Google Drive API's `files().update` operation:
  ```bash
  python3 .claude/scripts/publish_to_gdoc.py --doc "https://docs.google.com/document/d/18Ozi1BJ60eH2_-mX5rpA08YsLtFwUAHC0nMErhsCxwo/edit"
  ```

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
