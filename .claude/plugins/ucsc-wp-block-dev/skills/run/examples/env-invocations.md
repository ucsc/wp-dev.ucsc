# Example invocations — per-environment quick commands

These copy-ready examples show how to use the run and validate drivers across
supported environments.

## Auto-detect (recommended)

```bash
# Auto-detect environment and run the whole lifecycle: inspect → build → launch → smoke
bash .claude/plugins/ucsc-wp-block-dev/skills/run/driver.sh auto all

# Auto-detect and drive a URL (headless Chrome captures post-JS DOM + console)
bash .claude/plugins/ucsc-wp-block-dev/skills/run/driver.sh auto drive https://wp-dev.ucsc/
```

## Explicit: wp-dev-ucsc (home-rolled Docker Compose)

```bash
# Use the extracted driver directly
bash .claude/plugins/ucsc-wp-block-dev/skills/run/driver.sh wp-dev-ucsc all

# Inspect the environment (non-destructive)
bash .claude/plugins/ucsc-wp-block-dev/skills/run/driver.sh wp-dev-ucsc inspect
```

## Explicit: wp-env (when implemented)

```bash
# Placeholder: the wp-env driver is a stub until fully implemented
bash .claude/plugins/ucsc-wp-block-dev/skills/run/driver.sh wp-env all
```

## BYO (Bring Your Own) — generic guidance

```bash
# Validate a running WordPress site and then drive it
bash .claude/plugins/ucsc-wp-block-dev/skills/run/driver.sh byo drive https://your-site.test/

# If you manage WP via wp-env or Local, bring them up per their docs, then run
bash .claude/plugins/ucsc-wp-block-dev/skills/validate/validate-php.sh
bash .claude/plugins/ucsc-wp-block-dev/skills/validate/validate-jest.sh
bash .claude/plugins/ucsc-wp-block-dev/skills/validate/validate-e2e.sh
```

## Validate examples (repo-local)

If the repo ships `bin/validate*.sh`, prefer these:

```bash
cd public/wp-content/plugins/ucsc-gutenberg-blocks
bash bin/validate-php.sh
bash bin/validate-jest.sh
bash bin/validate-e2e.sh
```

If not, use the plugin-level validators which detect the environment and provide guidance:

```bash
bash .claude/plugins/ucsc-wp-block-dev/skills/validate/validate-php.sh
bash .claude/plugins/ucsc-wp-block-dev/skills/validate/validate-jest.sh
bash .claude/plugins/ucsc-wp-block-dev/skills/validate/validate-e2e.sh
```
