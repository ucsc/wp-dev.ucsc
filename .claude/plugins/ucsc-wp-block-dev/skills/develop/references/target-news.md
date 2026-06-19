# News Target

Read this reference when the selected target is `news`.

## Identity

- **Plugin**: `ucsc-custom-functionality` (separate team from ucsc-gutenberg-blocks)
- **Dev block name**: unknown
- **Rendered block name**: `ucsc-custom-functionality/news-block`

## Rendered-HTML Detection

Dynamic block — strips `<!-- wp: -->` comments from `content.rendered`.
Detect via either fingerprint:

- `wp-block-ucsc-custom-functionality-news-block` (CSS class on wrapper)
- `ucsc-news-block__cards-wrapper` (CSS class on inner cards container)

## Detection Caveat

The news block's CSS (`style-index-news-block-css`) and JS (`index-js`) are
enqueued site-wide by the theme on some sites, even on pages that do not contain
the block. Theme-level asset presence is NOT a reliable signal — only
`content.rendered` from the REST API is authoritative.
