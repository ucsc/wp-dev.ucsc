INSTALL — ucsc-wp-block-dev (developer quick-start)

This plugin provides Claude Code skills for building, running, validating, and
verifying UCSC Gutenberg block development. It is environment-agnostic and can
operate against multiple development runtimes (wp-dev.ucsc, wp-env, Local, BYO).

Quick setup per environment

1) wp-dev.ucsc (home-rolled Docker Compose)
   - Copy `.env.example.txt` to `.env` and edit host mappings if needed.
   - Start base stack: `docker compose up -d`
   - Bootstrap once: run the jobs in `docker-compose-install.yml` (theme/plugin/npm installs)
   - Use the driver: `bash .claude/plugins/ucsc-wp-block-dev/skills/run/driver.sh wp-dev-ucsc all`

2) wp-env (when using @wordpress/env)
   - Ensure `wp-env` is configured in package.json or wp-env.json.
   - Start with `npx wp-env start` (follow wp-env docs).
   - Use BYO driver until the `wp-env` driver is implemented: `bash .../driver.sh byo drive URL`

3) Local (LocalWP)
   - Ensure Local.app has your site configured and running.
   - Use BYO driver to validate and drive the site: `bash .../driver.sh byo drive https://your-local-site/`

4) BYO / remote / managed (WP Engine, etc.)
   - Bring your WordPress site up according to your environment's docs.
   - Use the generic BYO driver: `bash .claude/plugins/ucsc-wp-block-dev/skills/run/driver.sh byo drive <URL>`

Notes

- To add native support for a new environment, implement a driver in
  `skills/run/drivers/` and add a probe to
  `skills/run/lib/detect-environment.sh` with unit tests.
- The validate scripts detect the environment and will either run tests in
  Docker (when available) or present BYO commands.
