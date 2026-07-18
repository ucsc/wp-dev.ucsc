#!/usr/bin/env node
// Read-only editor-state dump: prints every block's name, editing mode
// (wp.data getBlockEditingMode), and any metadata.patternName stamp.
//
// Usage: node check-lock.mjs "<wp-admin edit URL>" [screenshot.png]
//
// Requires playwright (npm install playwright) and a persistent Chrome
// profile that is already logged in to wp-admin — set PATTERNLOCK_PROFILE
// to the profile directory (default: ./profile). First run: launch once,
// log in through SSO in the opened window, then re-run.
import { chromium } from 'playwright';

const PROFILE = process.env.PATTERNLOCK_PROFILE ?? 'profile';
const url = process.argv[2];
const shot = process.argv[3];
if (!url) {
  console.error('usage: node check-lock.mjs "<edit-url>" [screenshot.png]');
  process.exit(2);
}

const ctx = await chromium.launchPersistentContext(PROFILE, {
  headless: false,
  viewport: null,
  args: ['--window-size=1500,1000'],
});
const page = ctx.pages()[0] ?? (await ctx.newPage());
await page.goto(url, { waitUntil: 'domcontentloaded' });
const deadline = Date.now() + 120000;
let ready = false;
while (Date.now() < deadline && !ready) {
  try {
    ready = await page.evaluate(() => !!(window.wp?.data?.select('core/block-editor')?.getBlocks().length));
  } catch (e) {}
  if (!ready) await page.waitForTimeout(2000);
}
if (!ready) {
  console.log('NOT READY:', page.url());
  await ctx.close();
  process.exit(1);
}
await page.waitForTimeout(2000);
const report = await page.evaluate(() => {
  const sel = window.wp.data.select('core/block-editor');
  const walk = (blocks, depth) => blocks.flatMap((b) => [
    `${'  '.repeat(depth)}${b.name}  mode=${(() => { try { return sel.getBlockEditingMode(b.clientId); } catch (e) { return 'n/a'; } })()}${b.attributes?.metadata?.patternName ? `  pattern=${b.attributes.metadata.patternName}` : ''}`,
    ...walk(b.innerBlocks ?? [], depth + 1),
  ]);
  return walk(sel.getBlocks(), 0).join('\n');
});
console.log(report);
if (shot) { await page.screenshot({ path: shot }); console.log('screenshot:', shot); }
await ctx.close();
