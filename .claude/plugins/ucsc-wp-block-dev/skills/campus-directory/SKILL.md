---
name: campus-directory
description: Guides development, debugging, and maintenance of the Campus Directory block in the ucsc-gutenberg-blocks plugin. Handles LDAP connections, profile rewrite rules, and automated feeds.
argument-hint: "[target | request | Jira key/URL]"
arguments: [input]
---

# Campus Directory Block

Guides development, debugging, and maintenance of the Campus Directory block.

**Usage:** `/ucsc-wp-block-dev:campus-directory [action]`

## Universal Command Intake

Apply ADR-011: treat Campus Directory as the default target, then resolve the natural-language request and optional Jira key/URL from the full input. Ask one concise question only when the requested outcome cannot be inferred.

## Key File Locations
All paths relative to `public/wp-content/plugins/ucsc-gutenberg-blocks/`:
- **PHP Controller**: `classes/CampusDirectory.php`
- **LDAP API Client**: `classes/CampusDirectoryAPI.php`
- **Frontend Template**: `templates/CampusDirectoryTemplate.php`
- **Detail Profile Template**: `templates/DirectoryProfileTemplate.php`
- **Styles**: `src/components/CampusDirectory/campusdirectory.css`, `directoryprofile.css`, `editor.css`
- **JS Block Editor Registration**: `src/blocks/CampusDirectory.js`

## LDAP Bind & Dev Environments
- When local docker environment is active (`DOCKER_DEV=docker_dev`), Campus Directory uses anonymous LDAP bind.
- In production/live environments, it queries using the `ldap_api_key`, `ldap_cn`, and `ldap_url` network options.
- The configuration requirements are checked in the editor using the GET endpoint `/wp-json/ucscgutenbergblocks/v1/campusdirectoryrequirements`.

## Detail Page Rewrite Rules
- Detail pages mapped at `/directory/<cruzid>/` are loaded using query variable `directoryprofilecruzid`.
- The `template_include` action filters requests and includes `templates/DirectoryProfileTemplate.php`.

## Publishing Lock Logic
- Inside `src/blocks/CampusDirectory.js`, the block locks post saving using:
  ```js
  dispatch('core/editor').lockPostSaving('campusDirectoryInvalidState');
  ```
- This occurs when `automatedFeeds` is true, but both `department` and `division` are unset (`'---'`). Re-selecting a valid filter calls `unlockPostSaving`.
