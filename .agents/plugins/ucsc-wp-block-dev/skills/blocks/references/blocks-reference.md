# Core Blocks Architectural Reference

This reference covers the design, dependencies, attributes, caching, and editor-side behaviors of the three core custom Gutenberg blocks in the `ucsc-gutenberg-blocks` plugin.

---

## 1. Campus Directory Block

The Campus Directory block renders staff, faculty, and graduate student directory listings by querying the campus LDAP server.

### File Layout
- **PHP Controller**: `classes/CampusDirectory.php`
- **LDAP API Client**: `classes/CampusDirectoryAPI.php`
- **Legacy Shortcode**: `classes/CampusDirectoryShortcode.php`
- **JS Block Registration & Editor**: `src/blocks/CampusDirectory.js`
- **Frontend Template**: `templates/CampusDirectoryTemplate.php`
- **Detail Profile Template**: `templates/DirectoryProfileTemplate.php`
- **Stylesheets**: `src/components/CampusDirectory/campusdirectory.css`, `directoryprofile.css`, `editor.css`

### Rewrite Rules & Detail Pages
- The block supports dynamic detail profile pages at `/directory/<cruzid>/`.
- The CruzID parameter is registered as a query variable (`directoryprofilecruzid`) on `init`.
- The `template_include` action intercepts request routing and replaces the default template with `DirectoryProfileTemplate.php` if `directoryprofilecruzid` is present.

### REST Endpoints
- **GET** `/wp-json/ucscgutenbergblocks/v1/campusdirectoryrequirements`
  - Returns whether LDAP settings are configured (checks `ldap_api_key` in site/network options) and if the environment is multisite.
  - Used in the editor block preview to show configuration warnings.

### Editor Logic & Lock Publishing
- **Publish Locking**: Inside `CampusDirectory.js`, a `useEffect` hook monitors the combination of `automatedFeeds` (boolean), `department`, and `division`.
- If `automatedFeeds` is active but both `department` and `division` are unset (`'---'`), it displays a warning notice and locks post publishing:
  ```js
  dispatch('core/editor').lockPostSaving('campusDirectoryInvalidState');
  ```
- Re-selecting a valid department or division unlocks post saving.

### Attributes
- `pageLayout` (string) - Directory layout style.
- `automatedFeeds` (boolean) - Automatically pull people from a department/division.
- `cruzidList` (string) - Comma-separated list of CruzIDs to pull.
- `strFacultyTypes` / `strStaffTypes` / `strGradTypes` (stringified JSON) - Selected sub-types to filter.
- `manualAdd` (boolean) - Manually add extra people to directory list.
- `addCruzids` / `excludeCruzids` (string) - Comma-separated CruzIDs to append or remove.
- `displayDeptartmentAffiliates` (boolean) - Include affiliated members.
- `linkToProfile` / `linkOutToCampusDirectory` (boolean) - Controls whether directory links lead to internal profile page or external directory site.
- `strInformationTypes` / `strInformationTypesTable` (stringified JSON) - Fields to display (e.g. name, phone, email, office).
- `department` / `division` / `deptOrDiv` (string) - Query filters for LDAP queries.

### Caching & LDAP Settings
- Campus Directory queries bind anonymously when `DOCKER_DEV=docker_dev` is defined in the environment.
- In production, it authenticates using `ldap_api_key`, `ldap_cn`, and `ldap_url` network options.
- The results are cached using transient storage to prevent expensive LDAP queries on every pageload.

---

## 2. Class Schedule Block

The Class Schedule block embeds UCSC's Class Schedule application (WCSI) inside an iframe/container.

### File Layout
- **PHP Controller**: `classes/ClassSchedule.php`
- **JS Block Registration & Editor**: `src/blocks/ClassSchedule.js`

### Backend Render Logic
- Renders an embed code consisting of a stylesheet link and three JavaScript assets (`manifest.js`, `vendor.js`, `app.js`) loaded from a remote host:
  ```php
  $baseURL = $useNewServer ? 'https://webapps.stg.web.aws.ucsc.edu/wcsi' : 'https://webapps.ucsc.edu/wcsi';
  ```
- Evaluates `subjectOrDept` attribute to output either `department="[name]"` or `subject="[name]"` in the container `<div id="wcsi">` target.

### Staging/Testing Toggle
- Under `ClassSchedule.js`, the block checks if it is running in a local or development environment:
  ```js
  const isDevEnvironment = () => {
    return window.location.href.includes('https://wordpress-dev.ucsc.edu/')
           || window.location.href.includes('wp-dev.ucsc');
  }
  ```
- If true, a `Use New Server for Testing` checkbox becomes visible in the block settings, setting the `useNewServer` attribute.
- This instructs the backend render callback to load assets from staging rather than production, allowing smoke-testing.

### Attributes
- `subjectOrDept` (string) - Specifies whether sorting is by "dept" or "subject".
- `department` (string) - Department name filter.
- `subject` (string) - Subject category filter.
- `useNewServer` (boolean) - Flag to load the schedule application from the AWS staging environment instead of production.

---

## 3. Course Catalog Block

The Course Catalog block displays a sortable table of campus courses fetched from the AIS PeopleSoft endpoint.

### File Layout
- **PHP Controller**: `classes/CourseCatalog.php`
- **JS Block Registration & Editor**: `src/blocks/CourseCatalog.js`
- **Frontend Assets**: `src/components/CourseCatalog/tablesorter.js`, `tablesorter.css`

### PeopleSoft Integration (AIS)
- Queries UCSC's Academic Information System (AIS) PeopleSoft listener:
  `https://my.prd.ais.aws.ucsc.edu:443/PSIGW/HttpListeningConnector`
- Sends an XML payload specifying the target department (`<acad_org>`) or subject (`<subject>`):
  ```xml
  <!--?xml version="1.0"?-->
  <catalog>
      <subject>[subject]</subject>
  </catalog>
  ```
- Must include the AIS-specific routing headers:
  - `Host`: `my.prd.ais.aws.ucsc.edu`
  - `OperationName`: `SCX_SERVICE_CTLG.v1`
  - `From`: `SCX_CTLG_TARGET`
  - `To`: `PSFT_CSPRD`

### Caching
- **Weekly Cache**: Due to the heavy nature of AIS SOAP/XML endpoints, results are cached in a transient for one week (`WEEK_IN_SECONDS`):
  `course-catalog-<lowerTitle>-<subjectOrDept>`

### Sorting & Expandable/Collapsible Layout
- The frontend registers `tablesorterjs` (`tablesorter.js` + `tablesorter.css`) which enables client-side table sorting.
- Custom logic converts division names (`Lower Division`, `Upper Division`, `Graduate`) into numeric weights (1, 2, 3) embedded in hidden `<span>` tags to allow logical rather than alphabetical column sorting.
- Course descriptions are rendered in a hidden row (`<tr class="hide">`) beneath each course. Clicking a course row toggles its visibility. Global "Expand all" and "Collapse all" hooks toggle classes dynamically.

### Attributes
- `subjectOrDept` (string) - Set to either "dept" or "subject".
- `department` (string) - Academic organization code (e.g. `LALS`).
- `subject` (string) - Subject code filter (e.g. `LALS`).
