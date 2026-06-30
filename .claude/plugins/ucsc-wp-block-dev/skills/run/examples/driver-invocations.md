# driver.sh Invocation Examples

The canonical wrapper for the Docker lifecycle. All commands run from the repo
root (`wp-dev.ucsc/`). Set `UCSC_PLUGIN` to pick the target plugin.

## Full lifecycle — inspect, build, launch, smoke, drive

```bash
UCSC_PLUGIN=ucsc-gutenberg-blocks \
  bash .claude/plugins/ucsc-wp-block-dev/skills/run/driver.sh all
```

## Inspect only (no build, no launch)

Reads container state, volumes, and network — useful before deciding to start.

```bash
bash .claude/plugins/ucsc-wp-block-dev/skills/run/driver.sh inspect
```

## Build only (in-container npm build)

```bash
UCSC_PLUGIN=ucsc-gutenberg-blocks \
  bash .claude/plugins/ucsc-wp-block-dev/skills/run/driver.sh build
```

## Launch (docker compose up)

```bash
bash .claude/plugins/ucsc-wp-block-dev/skills/run/driver.sh launch
```

## Smoke test (hit the home page, confirm 200)

```bash
bash .claude/plugins/ucsc-wp-block-dev/skills/run/driver.sh smoke
```

## Drive a specific URL (headless Chrome, capture DOM + console errors)

```bash
bash .claude/plugins/ucsc-wp-block-dev/skills/run/driver.sh drive \
  https://wp-dev.ucsc/wp-admin/post-new.php?post_type=page
```

## Drive with a screenshot

```bash
UCSC_SHOT=/tmp/block-editor.png \
  bash .claude/plugins/ucsc-wp-block-dev/skills/run/driver.sh drive \
  https://wp-dev.ucsc/wp-admin/post-new.php?post_type=page
```

## Bring the stack down

```bash
bash .claude/plugins/ucsc-wp-block-dev/skills/run/driver.sh down
```

## Phase reference

| Phase | What it does |
|---|---|
| `inspect` | Reports container state, port bindings, volume mounts |
| `build` | Runs `npm run build` in-container for the selected plugin |
| `launch` | `docker compose up -d` (base stack) |
| `smoke` | `curl -sk https://wp-dev.ucsc/` — expects HTTP 200 |
| `drive <URL>` | Headless Chrome: captures post-JS DOM and console errors |
| `down` | `docker compose down` |
| `all` | inspect → build → launch → smoke → drive wp-admin |

## Environment variables

| Variable | Default | Purpose |
|---|---|---|
| `UCSC_PLUGIN` | `ucsc-gutenberg-blocks` | Which plugin to build |
| `UCSC_SHOT` | (unset) | Path to write a PNG screenshot; omit to skip |
| `UCSC_DRIVE_URL` | wp-admin dashboard | Override the URL driven in `all` mode |
