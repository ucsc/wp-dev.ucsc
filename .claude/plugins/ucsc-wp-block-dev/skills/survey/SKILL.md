---
name: survey
description: Run and interpret the WordPress block survey to audit UCSC custom block usage across all CampusPress sites. Use when asked to survey blocks, audit block usage, find which sites use a specific block, or generate block reports.
---

# Block Survey

Audit UCSC custom Gutenberg block usage across the CampusPress WordPress
multisite network using `wp_block_survey.sh`.

## What the Survey Does

The survey script scans every site in a CampusPress CSV export via the WordPress
REST API, checking each published post and page for UCSC custom block usage. It
detects blocks through two mechanisms:

1. `<!-- wp:blockname -->` HTML comments in `content.rendered` (static blocks)
2. Rendered-HTML fingerprint matching for dynamic blocks (all UCSC blocks are
   dynamic — see `references/domain/references/detection.md`)

## Outputs

The survey produces:

- **Detail CSV** (`block_survey_detail_YYYY-MM-DD.csv`): one row per
  block-use-per-post — site, post ID, type, title, permalink, block name
- **Summary CSV** (`block_survey_summary_YYYY-MM-DD.csv`): one row per
  site+block — site, block name, count
- **Per-block site lists** (`block_sites_YYYY-MM-DD/<block>.txt`): one file per
  UCSC block, listing unique sites that use it
- **Console summary**: global block usage table with site count and total uses

## Running the Survey

The script lives in the WP_tools working directory (`/Users/henryh/_code/_WP_tools`).

**Do not run the script directly** — provide the command for the user to run.

```bash
cd /Users/henryh/_code/_WP_tools
SITE_LIST_FILE=<campuspress-csv-export> ./wp_block_survey.sh
```

### Environment Variables

| Variable | Required | Default | Description |
| --- | --- | --- | --- |
| `SITE_LIST_FILE` | yes | — | Path to CampusPress CSV export or plain host list |
| `WP_USER` | yes | — | WordPress application password username (from `.env`) |
| `WP_APP_PASS` | yes | — | WordPress application password (from `.env`) |
| `SITE_LIMIT` | no | `0` (all) | Process only the first N sites |
| `API_REQUEST_DELAY_SEC` | no | `0.3` | Delay between API requests |
| `SCAN_POST_TYPES` | no | `posts pages` | Space-separated post types to scan |
| `INCLUDE_ARCHIVED_SPAM` | no | `0` | Set to `1` to include archived/deleted/spam sites |

### Limiting for Testing

```bash
SITE_LIMIT=10 SITE_LIST_FILE=export.csv ./wp_block_survey.sh
```

## Generating Block-Specific Reports

After a survey run, use the detail CSV to extract per-block reports with full
page URLs. Awk cannot reliably parse CSV with quoted fields containing commas —
use Python:

```bash
./venv/bin/python3 -c "
import csv, sys
with open(sys.argv[1]) as f:
    for row in csv.DictReader(f):
        if row['block_name'] == sys.argv[2]:
            print(row['permalink'])
" block_survey_detail_YYYY-MM-DD.csv "ucsc/accordion"
```

For a site-count + page-URL report for a specific block:

```bash
./venv/bin/python3 -c "
import csv, sys, collections
block = sys.argv[2]
sites = collections.Counter()
pages = []
with open(sys.argv[1]) as f:
    for row in csv.DictReader(f):
        if row['block_name'] == block:
            sites[row['site_url']] += 1
            pages.append(row['permalink'])
print(f'{len(sites)} sites, {len(pages)} pages with {block}')
for site, count in sites.most_common():
    print(f'  {site}: {count}')
" block_survey_detail_YYYY-MM-DD.csv "ucsc/accordion"
```

## Interpreting Results

### False Positives

The first ~25 rows of older survey runs may show false positives from a prior
bug where awk used `$6` (positional) instead of `$NF` (last field) to extract
block names. Re-running the survey with the current script eliminates these.

### Dynamic Block Detection

All UCSC custom blocks are dynamic and strip `<!-- wp: -->` comments. Detection
relies on rendered-HTML fingerprints defined in `DYNAMIC_BLOCK_PATTERNS` in the
survey script. The canonical fingerprint registry is in
`skills/develop/references/domain/references/detection.md`.

If a block is not being detected, check whether its rendered HTML fingerprint
has changed (e.g., after a block update that changes element IDs or CSS classes).

### Theme Asset Enqueues

Some blocks' CSS/JS is enqueued site-wide by the theme. Asset presence in the
page `<head>` does NOT mean the block is on that page. Only `content.rendered`
from the REST API is authoritative.
