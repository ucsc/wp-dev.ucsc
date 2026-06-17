# Calendar Feed Target

Read this reference when the selected target is `calendar-feed`.

## Identity

- **Plugin**: `ucsc-blocks`
- **Dev block name**: `ucsc/calendar-feed`
- **Rendered block name**: `ucsc/calendar-feed`
- **Block directory**: `src/blocks/calendar-feed/`

All paths below are relative to
`public/wp-content/plugins/ucsc-blocks/`.

## Key File Locations

- Block metadata: `src/blocks/calendar-feed/block.json`
- Server-side functions: `src/blocks/calendar-feed/calendar-feed.php`
- Editor UI (React): `src/blocks/calendar-feed/edit.js`
- Frontend render: `src/blocks/calendar-feed/render.php`
- Frontend JS (stub): `src/blocks/calendar-feed/view.js`
- ICS parser (JS): `src/blocks/calendar-feed/parser.js`
- Editor styles: `src/blocks/calendar-feed/editor.scss`
- Shared styles: `src/blocks/calendar-feed/style.scss`
- Block registration: `src/blocks/calendar-feed/index.js`
- Jest tests: `src/blocks/calendar-feed/parser.test.js`
- PHPUnit tests: `tests/php/CalendarFeedParserTest.php`
- ICS fixture: `tests/fixtures/sample-calendar.ics`
- User setup guide: `docs/calendar-feed/setup.md`

## Attributes

| Attribute | Type | Default | Notes |
| --- | --- | --- | --- |
| `feedUrl` | string | `""` | Public HTTPS `.ics` URL; validated server-side |
| `itemCount` | number | `5` | Clamped to 1–20 in all entry points |
| `layoutStyle` | string | `"list"` | `"list"` or `"grid"` |

## Server-Side Architecture

### ICS fetch and cache (`calendar-feed.php`)

`ucsc_calendar_feed_fetch_events( $feed_url, $count )` is the main entry point
called from `render.php`:

1. Clamps `$count` to 1–20.
2. Reads from WordPress transient keyed by `ucsc_cf_` + md5(`$feed_url`).
3. On cache miss: validates URL, fetches via `wp_remote_get()`, parses with
   `ucsc_calendar_feed_parse()`, filters past events, sorts ascending, stores
   up to 20 events, caches for 30 minutes.
4. Returns `array_slice( $cached, 0, $count )` — count is applied on retrieval
   so changing `itemCount` does not invalidate the cache.

Key constants/limits: `UCSC_CALENDAR_FEED_MAX_BODY_SIZE` = 2 MB, cache TTL = 30 min.

### ICS parser (`calendar-feed.php`)

`ucsc_calendar_feed_parse( $ics_content )` extracts VEVENT blocks:

- Unfolds RFC 5545 §3.1 continuation lines (CRLF + whitespace).
- Extracts: `SUMMARY`, `DTSTART`, `DTEND`, `LOCATION`, `DESCRIPTION`, `UID`, `URL`.
- TZID parameters on `DTSTART`/`DTEND` are stripped; the timezone in the value
  string is parsed by `ucsc_calendar_feed_parse_datetime()`.
- Unescapes ICS text: `\n`, `\N`, `\,`, `\;`, `\\`.

`ucsc_calendar_feed_parse_datetime( $dt )` handles three formats:
- `YYYYMMDD` — all-day; sets time to 00:00:00.
- `YYYYMMDDTHHMMSSz` — UTC; parses with `DateTimeZone('UTC')`.
- `YYYYMMDDTHHMMSS` — floating; parses with `wp_timezone()`.
- Returns `0` for unrecognised formats (strict, no `strtotime` fallback).

### SSRF protection

`ucsc_calendar_feed_validate_feed_url( $url )` enforces:

1. Valid URL (`FILTER_VALIDATE_URL`).
2. HTTPS scheme only.
3. Non-empty, non-localhost host.
4. DNS-resolved IP must pass `FILTER_FLAG_NO_PRIV_RANGE | FILTER_FLAG_NO_RES_RANGE`.

This is the reference SSRF implementation for the ucsc-blocks plugin (see `AGENTS.md`).

### AJAX endpoints

Both endpoints require nonce (`ucsc_calendar_feed_nonce`) and `edit_posts` capability.

| Action | Handler | Purpose |
| --- | --- | --- |
| `ucsc_calendar_feed_preview` | `ucsc_calendar_feed_preview()` | Returns parsed events as JSON for editor live preview |
| `ucsc_calendar_feed_clear_cache` | `ucsc_calendar_feed_clear_cache()` | Deletes transient for the given feed URL |

Nonce and AJAX URL are injected into `window.ucscCalendarFeedData` via
`ucsc_calendar_feed_enqueue_block_editor_assets()`.

## Editor UI (`edit.js`)

- Inspector Controls panel: **Calendar Settings** — Feed URL (`TextControl`),
  Number of Events (`RangeControl` 1–20), Layout Style (`SelectControl`).
- Cache Clear button in both the toolbar (`ToolbarButton`) and the sidebar panel.
- Live preview: debounced 1 s after `feedUrl` changes; fetches via AJAX
  (`ucsc_calendar_feed_preview`); item count is applied client-side by slicing
  `previewData` so count changes require no network call.
- Empty state: placeholder with setup instructions when `feedUrl` is blank.
- Error/warning states use `<Notice>` components.

## Frontend Render (`render.php`)

Outputs `<div wp-block-wrapper>` with class `layout-{layoutStyle}`. Events are
an `<ol class="ucsc-cf-events-list">` with `<li class="ucsc-cf-event-item">`
items. CSS class prefix: `ucsc-cf-*`.

Location field: if the value is a valid HTTP/HTTPS URL, rendered as an `<a>`
link showing only the hostname; otherwise rendered as plain text.

Descriptions use `wp_kses()` with a limited allowlist: `a`, `b`, `i`, `li`,
`ol`, `u`, `ul` (see `ucsc_calendar_feed_allowed_description_html()`).

## Rendered-HTML Detection (survey)

Dynamic block — rendered output does not contain `<!-- wp: -->` comments.
Detect via CSS class on the wrapper: `wp-block-ucsc-calendar-feed`.

## Tests

- **Jest** (`parser.test.js`): covers `icsParse()`, `icsParseDateTime()`,
  `isLocationUrl()`, `getHostFromUrl()` against a 43-event `.ics` fixture.
  Run: `npm test` from the plugin root.
- **PHPUnit** (`tests/php/CalendarFeedParserTest.php`): covers
  `ucsc_calendar_feed_parse()` and `ucsc_calendar_feed_parse_datetime()` against
  the same fixture. Run: `./vendor/bin/phpunit` from the plugin root.

## Non-Obvious Gotchas

- **All-day DTEND is exclusive.** In the ICS spec, `DTEND` for all-day events is
  the day *after* the last day. `render.php` and `calendar-feed.php` subtract
  one day before displaying the end date range.
- **Cache keyed by URL only.** Changing `itemCount` does not trigger a
  re-fetch; the stored pool holds up to 20 events and is sliced at read time.
- **TZID parameters are stripped.** The parser splits on the first `:`, so
  `DTSTART;TZID=America/Los_Angeles:20260301T090000` yields `20260301T090000`
  (floating), not a timezone-aware parse. Improvement opportunity if TZID
  handling is ever needed.
- **DNS resolution required at write time.** `ucsc_calendar_feed_validate_feed_url()`
  calls `gethostbyname()`, which makes a DNS lookup during the AJAX preview and
  at render time. If DNS is slow this adds latency.
- **`view.js` is a stub.** No frontend interactivity is needed; the file exists
  only because `block.json` references it.
