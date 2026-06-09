---
name: class-schedule
description: Guides development, debugging, and maintenance of the Class Schedule block. Renders the WCSI scheduling application and manages dev-environment server toggles.
argument-hint: "[target | request | Jira key/URL]"
arguments: [input]
---

# Class Schedule Block

Guides development, debugging, and maintenance of the Class Schedule block.

**Usage:** `/ucsc-wp-block-dev:class-schedule [action]`

## Universal Command Intake

Apply ADR-011: treat Class Schedule as the default target, then resolve the natural-language request and optional Jira key/URL from the full input. Ask one concise question only when the requested outcome cannot be inferred.

## Key File Locations
All paths relative to `public/wp-content/plugins/ucsc-gutenberg-blocks/`:
- **PHP Controller**: `classes/ClassSchedule.php`
- **JS Block Editor Registration**: `src/blocks/ClassSchedule.js`

## Integration & Embed Logic
- The block outputs a stylesheet link and three scripts (`manifest.js`, `vendor.js`, `app.js`) pointing to the WCSI app:
  ```php
  $baseURL = $useNewServer ? 'https://webapps.stg.web.aws.ucsc.edu/wcsi' : 'https://webapps.ucsc.edu/wcsi';
  ```
- Renders either `department="[name]"` or `subject="[name]"` in `<div id="wcsi">` depending on the `subjectOrDept` attribute.

## Staging & Testing Toggle
- The block determines the environment inside `src/blocks/ClassSchedule.js`:
  ```js
  const isDevEnvironment = () => {
    return window.location.href.includes('https://wordpress-dev.ucsc.edu/')
           || window.location.href.includes('wp-dev.ucsc');
  }
  ```
- In development environments, it exposes a `Use New Server for Testing` checkbox mapping to the `useNewServer` attribute.
