# Class Schedule Target

Read this reference when the selected target is `class-schedule`.

## Key File Locations

All paths are relative to
`public/wp-content/plugins/ucsc-gutenberg-blocks/`:

- PHP controller: `classes/ClassSchedule.php`
- Editor registration: `src/blocks/ClassSchedule.js`

## Integration

The block embeds the WCSI scheduling application and loads `manifest.js`,
`vendor.js`, and `app.js`.

```php
$baseURL = $useNewServer
    ? 'https://webapps.stg.web.aws.ucsc.edu/wcsi'
    : 'https://webapps.ucsc.edu/wcsi';
```

It renders either a `department` or `subject` attribute in `<div id="classSchedule">`
according to `subjectOrDept`.

## Rendered-HTML Detection

Dynamic block — strips `<!-- wp: -->` comments from `content.rendered`.
Detect via: `id="classSchedule"` in the rendered HTML.

Previous versions used `id="wcsi"` — that ID is no longer current.

## Testing Toggle

`src/blocks/ClassSchedule.js` recognizes
an organization-specific development hostname and the local-only `wp-dev.ucsc` hostname as development
environments. There it exposes the `Use New Server for Testing` control backed
by `useNewServer`.
