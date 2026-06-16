# Create Tests

Read this reference when the selected test operation is `create`.

## Purpose

Create focused PHP, Jest, or end-to-end coverage for a target Gutenberg block,
feature, fix, or acceptance criterion.

## Workflow

1. Confirm the test type is `php`, `jest`, or `e2e`.
2. Read the nearest existing test pattern before adding coverage.
3. Add the smallest test that proves the behavior or regression.
4. Run the new or changed test.
5. Broaden validation only when risk or shared behavior requires it.

## Type Guidance

| Type | Use for |
| --- | --- |
| `php` | Render callbacks, sanitization, REST routes, transient behavior |
| `jest` | Block registration, attributes, editor controls, client behavior |
| `e2e` | WordPress editor insertion, frontend rendering, Docker/browser integration |

Build checks may support any type but are not a fourth test type.

## PHP Test Patterns (dependency-free)

Always run PHP tests via Docker — never assume a local `php` binary (ADR-050):

```bash
docker run --rm -v "$PWD:/plugin" -w /plugin php:8.1-cli php tests/php/YourTest.php
```

Follow the `ClassScheduleTest.php` / `CampusDirectoryTest.php` pattern:

1. **Stub core functions** — define `add_action`, `add_filter`, `get_query_var`, `is_singular`, etc. as no-ops or simple globals before including any plugin class.
2. **Capture hooks** — in the `add_filter` stub, capture callbacks into globals (e.g. `$the_content_callback`) so tests can invoke them directly.
3. **Mock `ABSPATH`** — define `ABSPATH` pointing to a temp dir and write minimal stub files (`class-wp-filesystem-base.php`, `class-wp-filesystem-direct.php`) if any class `require_once`s WP admin files.
4. **Stub LDAP constants** — the `ldap` extension is absent in `php:8.1-cli`. If the class under test uses `LDAP_OPT_*` constants, define them at the top of the test file:
   ```php
   if (!defined('LDAP_OPT_TIMELIMIT')) define('LDAP_OPT_TIMELIMIT', 0);
   if (!defined('LDAP_OPT_PROTOCOL_VERSION')) define('LDAP_OPT_PROTOCOL_VERSION', 0);
   if (!defined('LDAP_OPT_REFERRALS')) define('LDAP_OPT_REFERRALS', 0);
   if (!defined('LDAP_OPT_NETWORK_TIMEOUT')) define('LDAP_OPT_NETWORK_TIMEOUT', 0);
   if (!defined('LDAP_OPT_SIZELIMIT')) define('LDAP_OPT_SIZELIMIT', 0);
   ```
5. **Stub LDAP functions** — similarly mock `ldap_connect`, `ldap_bind`, `ldap_search`, etc. returning safe no-op values.
6. **Reset state between tests** — use a `reset_test_state()` helper that sets all globals back to defaults before each scenario.

### `the_content` filter guard conditions to always test

When a class hooks into `the_content` filter with guard conditions, test every bail-out path first:
- Missing query var → returns `$content` unchanged
- `is_admin()` true → returns `$content` unchanged
- `is_singular()` false → returns `$content` unchanged
- `is_main_query()` false → returns `$content` unchanged
- Loop post ID ≠ queried object ID → returns `$content` unchanged
- Happy path → concatenates profile/component output **to** `$content` (not replacing it)

## Check-In Text

When coverage is added or meaningfully changed, finish with ready-to-paste
check-in text:

1. A Jira title: short imperative summary of the test work.
2. A Conventional Commit description with a `test(scope): subject` header and a
   body naming the test type, behaviors covered, and runtime caveats.

Use `fix` or `feat` only when block behavior also changed. Reference a Jira key
in the footer when known.

