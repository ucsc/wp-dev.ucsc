# Campus Directory Target

Read this reference when the selected target is `campus-directory`.

## Key File Locations

All paths are relative to
`public/wp-content/plugins/ucsc-gutenberg-blocks/`:

- PHP controller: `classes/CampusDirectory.php`
- LDAP API client: `classes/CampusDirectoryAPI.php`
- Frontend template: `templates/CampusDirectoryTemplate.php`
- Detail profile template: `templates/DirectoryProfileTemplate.php`
- Styles: `src/components/CampusDirectory/campusdirectory.css`,
  `directoryprofile.css`, `editor.css`
- Editor registration: `src/blocks/CampusDirectory.js`

## LDAP And Environments

- Local Docker uses anonymous LDAP bind when `DOCKER_DEV=docker_dev`.
- Production uses the `ldap_api_key`, `ldap_cn`, and `ldap_url` network
  options.
- The editor checks requirements through
  `/wp-json/ucscgutenbergblocks/v1/campusdirectoryrequirements`.

## Detail Pages

Detail pages at `/directory/<cruzid>/` use the
`directoryprofilecruzid` query variable. The `template_include` filter loads
`templates/DirectoryProfileTemplate.php`.

## Publishing Lock

`src/blocks/CampusDirectory.js` locks post saving with
`campusDirectoryInvalidState` when automated feeds are enabled without a
department or division. Selecting a valid filter unlocks post saving.

