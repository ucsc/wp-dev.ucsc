---
name: course-catalog
description: Guides development, debugging, and maintenance of the Course Catalog block. Handles PeopleSoft XML integration, transient caching, and client-side sorting.
argument-hint: "[target | request | Jira key/URL]"
arguments: [input]
---

# Course Catalog Block

Guides development, debugging, and maintenance of the Course Catalog block.

**Usage:** `/ucsc-wp-block-dev:course-catalog [action]`

## Universal Command Intake

Apply ADR-011: treat Course Catalog as the default target, then resolve the natural-language request and optional Jira key/URL from the full input. Ask one concise question only when the requested outcome cannot be inferred.

## Key File Locations
All paths relative to `public/wp-content/plugins/ucsc-gutenberg-blocks/`:
- **PHP Controller**: `classes/CourseCatalog.php`
- **JS Block Editor Registration**: `src/blocks/CourseCatalog.js`
- **Frontend Assets**: `src/components/CourseCatalog/tablesorter.js`, `tablesorter.css`

## PeopleSoft/AIS Integration
- Queries AIS PeopleSoft HttpListeningConnector at `https://my.prd.ais.aws.ucsc.edu:443/PSIGW/HttpListeningConnector`.
- Delivers an XML payload containing `<acad_org>` (for departments) or `<subject>` filters.
- Requires custom headers:
  - `Host`: `my.prd.ais.aws.ucsc.edu`
  - `OperationName`: `SCX_SERVICE_CTLG.v1`
  - `From`: `SCX_CTLG_TARGET`
  - `To`: `PSFT_CSPRD`

## Caching Strategy
- The XML body retrieved from AIS is stored in a WordPress transient for one week to optimize performance:
  ```php
  set_transient('course-catalog-' . $lowerTitle . '-' . $subjectOrDept, $body, WEEK_IN_SECONDS);
  ```

## Table Sorting & Collapsible Rows
- Relies on `tablesorter.js` for client-side sorting.
- Course divisions (`Lower Division`, `Upper Division`, `Graduate`) map to integer values (1, 2, 3) inside a hidden span tag to enable logical sorting instead of alphabetical.
- Course descriptions are output in a `<tr class="hide">` element. Clicking the main course row toggles the visibility.
