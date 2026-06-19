# UCSC Events Target

Read this reference when the selected target is `ucsc-events`.

## Identity

- **Plugin**: `ucsc-blocks`
- **Dev block name**: `ucsc/events`
- **Rendered block name**: `ucsc/events`
- **Block directory**: `src/blocks/ucsc-events/`

All paths below are relative to
`public/wp-content/plugins/ucsc-blocks/`.

## Key File Locations

- Block metadata: `src/blocks/ucsc-events/block.json`
- Server-side functions: `src/blocks/ucsc-events/ucsc-events.php`
- Editor UI (React): `src/blocks/ucsc-events/edit.js`
- Frontend render: `src/blocks/ucsc-events/render.php`
- Frontend JS: `src/blocks/ucsc-events/view.js`
- Editor styles: `src/blocks/ucsc-events/editor.scss`
- Shared styles: `src/blocks/ucsc-events/style.scss`
- Block registration: `src/blocks/ucsc-events/index.js`

## Attributes

| Attribute | Type | Default | Notes |
| --- | --- | --- | --- |
| `apiUrl` | string | `""` | Tribe Events REST endpoint URL |
| `itemCount` | number | `5` | Number of events to display |
| `layoutStyle` | string | `"list"` | `"list"` or `"grid"` |
| `hideRepeating` | boolean | `false` | Hides repeating/recurring events when true |

## Server-Side Architecture

### API fetch and cache (`ucsc-events.php`)

`ucsc_events_fetch_data( $api_url )` is the main entry point (wrapped in
`function_exists()` guard):

1. Reads transient keyed by `ucsc_events_` + md5(`$api_url`).
2. On cache miss: appends `per_page=50&starts_after=yesterday` query args and
   fetches via `wp_remote_get()`.
3. Decodes JSON and extracts `$fetched['events']` array.
4. Maps each event to: `title`, `organizer`, `date`, `venue`, `featured_image`,
   `link`, `slug`.
5. Caches processed events for **1 hour** (longer than calendar-feed's 30 min).

The API always fetches the maximum (50 events). Callers slice to `itemCount`.

### API endpoint

Default: `https://events.ucsc.edu/wp-json/tribe/v1/events`

This is the [The Events Calendar](https://theeventscalendar.com/) (Tribe Events)
REST API v1. Response shape: `{ "events": [ { "title", "start_date",
"organizer": { "organizer" }, "venue": { "venue" }, "image": { "url",
"sizes": { "medium": { "url" } } }, "url", "slug" } ] }`.

Featured image resolution order:
1. `item['image']['url']`
2. `item['image']['sizes']['medium']['url']`
3. Empty string (no image)

### AJAX endpoint

| Action | Handler | Purpose |
| --- | --- | --- |
| `ucsc_events_clear_cache` | `ucsc_events_clear_cache()` | Deletes transient for given API URL |

Requires nonce (`ucsc_events_nonce`) and `edit_posts` capability.

### Frontend nonce injection

Unlike `calendar-feed`, the events block needs frontend interactivity (`view.js`),
so the nonce is also injected into the frontend:
`window.ucscEventsNonce` and `window.ajaxurl` via `wp_add_inline_script()` on
`wp_enqueue_scripts`, guarded by `has_block('ucsc/events')`.

## Editor UI (`edit.js`)

Settings in the Inspector Controls panel include API URL, item count, layout
style, and hide-repeating toggle. The editor fetches a live preview via the
AJAX endpoint on URL change.

## Rendered-HTML Detection (survey)

Dynamic block — rendered output does not contain `<!-- wp: -->` comments.
Detect via CSS class on the wrapper: `wp-block-ucsc-events`.

## Non-Obvious Gotchas

- **`function_exists()` guard on `ucsc_events_fetch_data`.** The function is
  wrapped in `if ( ! function_exists(...) )`. This is unusual and suggests the
  function may also be defined elsewhere; confirm before adding overloads.
- **Cache TTL is 1 hour**, not 30 minutes like `calendar-feed`. Consider this
  when debugging stale data — cache invalidation takes longer.
- **`starts_after=yesterday`** is appended to the API URL, not `today`. Events
  that started yesterday but haven't ended yet will be included.
- **No SSRF protection.** Unlike `calendar-feed`, `ucsc_events_fetch_data()` only
  calls `filter_var( $api_url, FILTER_VALIDATE_URL )` — no scheme enforcement,
  no private-IP rejection. If the API URL is ever user-editable in a
  privileged-user context this should be hardened to match the calendar-feed
  reference implementation.
- **No body-size limit.** The fetch does not enforce a max response size. For a
  known internal API this is low risk, but worth noting if the block is ever
  pointed at arbitrary endpoints.
- **Sanitization happens before caching** for text fields. `featured_image` and
  `link` URLs are stored raw from the API response; escape at render time.
