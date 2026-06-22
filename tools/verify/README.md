# `scripts/` — verify-loop toolkit

Deterministic helpers the agent **calls** instead of hand-rolling, to close every skill's
*deliver-and-verify* loop: freeze a moment, see start/mid/end at a glance, and assert the
encoded file's real spec. Small, dependency-light, tier-matched.

| Script | Tier | What it does |
|---|---|---|
| `seek-shot.sh` | **Light** (standalone HTML) | Drives the page's `?t=N` seek harness and screenshots each frozen moment. |
| `contact-sheet.sh` | any | Tiles the frames side-by-side into one image (start \| mid \| end) for one-glance review. |
| `probe-mp4.sh` | **Heavy** (Remotion / Manim) | Reads + asserts the MP4's real resolution / codec / fps / duration. |

## Usage by tier

**Light — standalone HTML** (`?t=N` harness): freeze, shoot, tile.
```bash
scripts/seek-shot.sh anim.html 0 1.5 3        # → frame-0.png frame-1.5.png frame-3.png
scripts/contact-sheet.sh sheet.png frame-*.png
# inspect sheet.png: matches the brief? clipped text / off-canvas / FOUC?
```

**Heavy — Remotion**: render stills with the *real* shipped props, tile, then assert the MP4.
```bash
npx remotion still Short out/f-hook.png --frame=10 --props='{...}'
npx remotion still Short out/f-mid.png  --frame=N  --props='{...}'
npx remotion still Short out/f-end.png  --frame=L  --props='{...}'
scripts/contact-sheet.sh sheet.png out/f-hook.png out/f-mid.png out/f-end.png
npx remotion render Short out/short.mp4 --props='{...}'
scripts/probe-mp4.sh out/short.mp4 1080x1920 30      # vertical short contract
```

**Heavy — Manim**: save the last frame (`-s`) / a range (`-n a,b`), tile, assert.
```bash
manim -s -ql scene.py MyScene                        # media/images/.../MyScene.png
scripts/probe-mp4.sh media/videos/scene/480p15/MyScene.mp4
```

## Requirements
- `seek-shot.sh` → `npx` + Playwright Chromium (`npx playwright install chromium` once).
- `contact-sheet.sh` / `probe-mp4.sh` → `ffmpeg` / `ffprobe`.

All three are POSIX `bash`; run them from the project where your deliverable lives.
