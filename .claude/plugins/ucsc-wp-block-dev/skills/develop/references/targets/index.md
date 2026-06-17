# Development Targets

Use this index whenever `develop`, `feature`, or `fix` needs block-specific
context. Resolve the user's target by canonical slug or alias, then read only
the selected target reference.

## ucsc-gutenberg-blocks plugin

Maintained by the UCSC Web team. Dev namespace: `ucscblocks/*`. Production
rendered namespace: `ucsc/*`.

| Target | Aliases | Block name (dev) | Block name (rendered) | Reference |
| --- | --- | --- | --- | --- |
| `class-schedule` | class schedule, schedule, wcsi | `ucscblocks/classschedule` | `ucsc/class-schedule` | [`class-schedule.md`](class-schedule.md) |
| `course-catalog` | course catalog, catalog | `ucscblocks/coursecatalog` | `ucsc/course-catalog` | [`course-catalog.md`](course-catalog.md) |
| `campus-directory` | campus directory, directory, people | `ucscblocks/campusdirectory` | `ucsc/campus-directory` | [`campus-directory.md`](campus-directory.md) |
| `accordion` | accordion, faq | `ucscblocks/accordion` | `ucsc/accordion` | [`accordion.md`](accordion.md) |
| `events` | events, event | unknown | `ucsc/events` | [`events.md`](events.md) |
| `content-sharer` | content sharer, sharer | unknown | `ucsc/content-sharer` | [`content-sharer.md`](content-sharer.md) |
| `feedback` | feedback | unknown | `ucsc/feedback` | [`feedback.md`](feedback.md) |

## ucsc-blocks plugin

Maintained by the UCSC Web team. Block namespace: `ucsc/*`. Source: `public/wp-content/plugins/ucsc-blocks/`. Multi-block, single-plugin architecture using `@wordpress/scripts`.

| Target | Aliases | Block name | Reference |
| --- | --- | --- | --- |
| `calendar-feed` | calendar feed, ics, ical, ics feed | `ucsc/calendar-feed` | [`calendar-feed.md`](calendar-feed.md) |
| `ucsc-events` | ucsc events, events block | `ucsc/events` | [`ucsc-events.md`](ucsc-events.md) |

## ucsc-custom-functionality plugin

Maintained by a separate UCSC team. Dev namespace: unknown. Production rendered
namespace: `ucsc-custom-functionality/*`.

| Target | Aliases | Block name (dev) | Block name (rendered) | Reference |
| --- | --- | --- | --- | --- |
| `news` | news, news block | unknown | `ucsc-custom-functionality/news-block` | [`news.md`](news.md) |

## Two-team naming conventions

The two plugins use different block namespaces. This matters for detection,
survey scripts, and per-block site lists. See
[`../domain/references/detection.md`](../domain/references/detection.md) for
rendered-HTML fingerprint patterns and the detection reference.

If the user names a target that is not listed, treat the name as a proposed new
target. Confirm its canonical slug and scope before implementation, then add a
reference when the target has reusable domain guidance.

