# Development Targets

Use this index whenever `develop`, `feature`, or `fix` needs block-specific
context. Resolve the user's target by canonical slug or alias, then read only
the selected target reference.

## ucsc-gutenberg-blocks plugin

Maintained by the UCSC Web team. Dev namespace: `ucscblocks/*`. Production
rendered namespace: `ucsc/*`.

| Target | Aliases | Block name (dev) | Block name (rendered) | Reference |
| --- | --- | --- | --- | --- |
| `class-schedule` | class schedule, schedule, wcsi | `ucscblocks/classschedule` | `ucsc/class-schedule` | [`target-class-schedule.md`](target-class-schedule.md) |
| `course-catalog` | course catalog, catalog | `ucscblocks/coursecatalog` | `ucsc/course-catalog` | [`target-course-catalog.md`](target-course-catalog.md) |
| `campus-directory` | campus directory, directory, people | `ucscblocks/campusdirectory` | `ucsc/campus-directory` | [`target-campus-directory.md`](target-campus-directory.md) |
| `accordion` | accordion, faq | `ucscblocks/accordion` | `ucsc/accordion` | [`target-accordion.md`](target-accordion.md) |
| `events` | events, event | unknown | `ucsc/events` | [`target-events.md`](target-events.md) |
| `content-sharer` | content sharer, sharer | unknown | `ucsc/content-sharer` | [`target-content-sharer.md`](target-content-sharer.md) |
| `feedback` | feedback | unknown | `ucsc/feedback` | [`target-feedback.md`](target-feedback.md) |

## ucsc-blocks plugin

Maintained by the UCSC Web team. Block namespace: `ucsc/*`. Source: `public/wp-content/plugins/ucsc-blocks/`. Multi-block, single-plugin architecture using `@wordpress/scripts`.

| Target | Aliases | Block name | Reference |
| --- | --- | --- | --- |
| `calendar-feed` | calendar feed, ics, ical, ics feed | `ucsc/calendar-feed` | [`target-calendar-feed.md`](target-calendar-feed.md) |
| `ucsc-events` | ucsc events, events block | `ucsc/events` | [`target-ucsc-events.md`](target-ucsc-events.md) |

## ucsc-custom-functionality plugin

Maintained by a separate UCSC team. Dev namespace: unknown. Production rendered
namespace: `ucsc-custom-functionality/*`.

| Target | Aliases | Block name (dev) | Block name (rendered) | Reference |
| --- | --- | --- | --- | --- |
| `news` | news, news block | unknown | `ucsc-custom-functionality/news-block` | [`target-news.md`](target-news.md) |

## Two-team naming conventions

The two plugins use different block namespaces. This matters for detection,
survey scripts, and per-block site lists. See
[`domain-detection.md`](domain-detection.md) for
rendered-HTML fingerprint patterns and the detection reference.

If the user names a target that is not listed, treat the name as a proposed new
target. Confirm its canonical slug and scope before implementation, then add a
reference when the target has reusable domain guidance.

