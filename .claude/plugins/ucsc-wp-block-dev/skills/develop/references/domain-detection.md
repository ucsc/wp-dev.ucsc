# Block Detection Reference

How UCSC custom blocks appear in WordPress REST API output and how to detect
them reliably.

## Static vs Dynamic Blocks

WordPress Gutenberg blocks come in two forms:

- **Static blocks** store their markup in post content and leave
  `<!-- wp:namespace/block-name -->` HTML comments in the rendered output.
  These are trivially detectable by grepping `content.rendered` for the comment
  pattern.

- **Dynamic blocks** execute a PHP `render_callback` at page-load time. The
  `<!-- wp: -->` comments are stripped from `content.rendered`. The only way to
  detect these blocks in rendered output is by matching known HTML fingerprints
  (CSS classes, element IDs) that the render callback produces.

All UCSC custom blocks are dynamic. Detection requires fingerprint matching.

## CampusPress API Limitation

CampusPress strips `context=edit` from the WordPress REST API (returns HTTP
400). Only `content.rendered` is available — `content.raw` (which would
preserve block comments) is inaccessible. This makes fingerprint-based
detection the only viable approach for remote scanning.

## Two Naming Conventions

Two separate teams maintain UCSC blocks in different plugins with different
namespaces:

### ucsc-gutenberg-blocks plugin

- **Dev namespace**: `ucscblocks/*` (used in `register_block_type` and editor JS)
- **Rendered namespace**: `ucsc/*` (block name in `<!-- wp: -->` comments, if present)
- Examples: `ucscblocks/classschedule` → `ucsc/class-schedule`

### ucsc-custom-functionality plugin

- **Dev namespace**: unknown
- **Rendered namespace**: `ucsc-custom-functionality/*`
- Example: `ucsc-custom-functionality/news-block`

Survey scripts and per-block site lists must filter for both `ucsc/` and
`ucsc-custom-functionality/` prefixes.

## Fingerprint Registry

Each entry maps a rendered-HTML pattern to the canonical block name. Multiple
fingerprints per block increase detection confidence.

| Rendered-HTML fingerprint | Block name | Notes |
| --- | --- | --- |
| `id="classSchedule"` | `ucsc/class-schedule` | Was `id="wcsi"` in older versions |
| `wp-block-ucscblocks-coursecatalog` | `ucsc/course-catalog` | CSS class |
| `id="courseCatalog"` | `ucsc/course-catalog` | Element ID |
| `ucsc-block-directory` | `ucsc/campus-directory` | CSS class |
| `wp-block-ucsc-events` | `ucsc/events` | CSS class |
| `ucsc-block-accordion` | `ucsc/accordion` | Class on `<details>` elements |
| `ucsc-accordion-wrapper` | `ucsc/accordion` | Class on wrapper `<div>` |
| `content-sharer` | `ucsc/content-sharer` | Substring match |
| `ucsc-feedback` | `ucsc/feedback` | CSS class/ID |
| `wp-block-ucsc-custom-functionality-news-block` | `ucsc-custom-functionality/news-block` | CSS class on wrapper |
| `ucsc-news-block__cards-wrapper` | `ucsc-custom-functionality/news-block` | CSS class on inner container |

This table is the source of truth for the `DYNAMIC_BLOCK_PATTERNS` array in
`wp_block_survey.sh` (located in the WP_tools working directory).

## Detection Caveats

### Theme-level asset enqueues are not block presence

Some themes enqueue block CSS/JS site-wide regardless of whether the block
appears on a given page. For example, the news block's
`style-index-news-block-css` and `index-js` load on every page of some sites.
Asset presence in the page head is NOT evidence that the block is in the page
content.

Only `content.rendered` from the REST API (via `/wp-json/wp/v2/posts` or
`/wp-json/wp/v2/pages`) is a reliable signal.

### Fingerprint maintenance

When a block's rendered HTML changes (e.g., `id="wcsi"` → `id="classSchedule"`),
the fingerprint table and `wp_block_survey.sh` must both be updated. After
fixing a block, check whether its detection fingerprint is still valid.
