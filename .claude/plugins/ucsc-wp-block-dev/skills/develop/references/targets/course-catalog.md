# Course Catalog Target

Read this reference when the selected target is `course-catalog`.

## Key File Locations

All paths are relative to
`public/wp-content/plugins/ucsc-gutenberg-blocks/`:

- PHP controller: `classes/CourseCatalog.php`
- Editor registration: `src/blocks/CourseCatalog.js`
- Frontend assets: `src/components/CourseCatalog/tablesorter.js`,
  `tablesorter.css`

## PeopleSoft Integration

The block queries the AIS PeopleSoft `HttpListeningConnector` and sends an XML
payload containing an `acad_org` or `subject` filter.

Required headers include:

- `Host: my.prd.ais.aws.ucsc.edu`
- `OperationName: SCX_SERVICE_CTLG.v1`
- `From: SCX_CTLG_TARGET`
- `To: PSFT_CSPRD`

## Caching

Responses are cached for one week:

```php
set_transient(
    'course-catalog-' . $lowerTitle . '-' . $subjectOrDept,
    $body,
    WEEK_IN_SECONDS
);
```

## Frontend Behavior

`tablesorter.js` provides client-side sorting. Course divisions map to numeric
values for logical order, and clicking a course row toggles its hidden
description row.

