#!/usr/bin/env node
// showcase-to-gif.mjs — convert a GSAP showcase.html reel into a deterministic GIF.
//
// How it works: load the page headless, PAUSE gsap.globalTimeline, then seek it to
// each frame's absolute time (gsap.globalTimeline.time(t)) and screenshot. Because
// every tween (incl. the infinite ambient loops) lives on the global timeline, this
// reproduces the exact reel frame-for-frame, then ffmpeg palettegen assembles a GIF.
//
// Usage:
//   node motion-skills/tools/showcase-to-gif.mjs <input.html> <output.gif> [--fps 12] [--width 720] [--max 10] [--vw 1280] [--vh 720]
// Run from the dir that has node_modules (the top-level "Motion Skills" folder).

import { chromium } from 'playwright';
import { execFileSync } from 'node:child_process';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';

const a = process.argv.slice(2);
const pos = a.filter(x => !x.startsWith('--'));
const flag = (n, d) => { const i = a.indexOf('--' + n); return i >= 0 ? Number(a[i + 1]) : d; };
const input = pos[0];
const output = pos[1];
if (!input || !output) { console.error('usage: showcase-to-gif.mjs <input.html> <output.gif> [--fps --width --max --vw --vh]'); process.exit(1); }

const fps = flag('fps', 12), width = flag('width', 720), max = flag('max', 10);
const vw = flag('vw', 1280), vh = flag('vh', 720);
const abs = path.resolve(input);
const tmp = mkdtempSync(path.join(tmpdir(), 'sc-'));

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: vw, height: vh }, deviceScaleFactor: 1 });
await page.goto('file://' + abs, { waitUntil: 'networkidle' });
await page.waitForFunction(() => !!window.gsap, { timeout: 15000 });
await page.evaluate(() => document.fonts && document.fonts.ready).catch(() => {});

// Pause the global timeline; find the story sub-timeline's duration (finite child).
const dur = await page.evaluate((max) => {
  const gt = window.gsap.globalTimeline;
  gt.pause();
  let d = 0;
  for (const c of gt.getChildren(false, true, true)) {
    if (typeof c.getChildren === 'function') d = Math.max(d, c.totalDuration());
  }
  if (!d || !isFinite(d)) d = 8;
  return Math.min(d, max);
}, max);

const frames = Math.max(1, Math.round(dur * fps));
process.stdout.write(`  ${path.basename(path.dirname(abs))}: ${dur.toFixed(1)}s → ${frames} frames @ ${fps}fps … `);
for (let i = 0; i < frames; i++) {
  const t = i / fps;
  await page.evaluate((t) => { window.gsap.globalTimeline.time(t); }, t);
  await page.screenshot({ path: path.join(tmp, `f${String(i).padStart(4, '0')}.png`) });
}
await browser.close();

execFileSync('ffmpeg', [
  '-y', '-framerate', String(fps), '-i', path.join(tmp, 'f%04d.png'),
  '-vf', `scale=${width}:-1:flags=lanczos,split[s0][s1];[s0]palettegen=stats_mode=full[p];[s1][p]paletteuse=dither=sierra2_4a`,
  '-loop', '0', output,
], { stdio: 'ignore' });
rmSync(tmp, { recursive: true, force: true });
console.log(`done → ${output}`);
