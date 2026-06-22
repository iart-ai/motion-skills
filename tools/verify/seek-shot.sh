#!/usr/bin/env bash
# seek-shot.sh — LIGHT tier (standalone HTML): freeze the animation at given times and screenshot each.
#
# Drives the skill's own `?t=N` seek harness (the page does `tl.pause(); tl.seek(t)` on load), so
# every shot lands on a deterministic still — the web parallel of pinning a video frame.
#
# Usage:
#   scripts/seek-shot.sh anim.html 0 1.5 3      # screenshot at t=0,1.5,3 seconds
#   scripts/seek-shot.sh anim.html              # defaults to 0, 1.5, 3
# Output: frame-<t>.png in the current directory.
# Needs: npx (Playwright auto-fetches Chromium on first run: `npx playwright install chromium`).
set -euo pipefail
html="${1:?usage: seek-shot.sh <file.html> [t1 t2 ...]}"; shift || true
times=("$@"); [ "${#times[@]}" -eq 0 ] && times=(0 1.5 3)
abs="$(cd "$(dirname "$html")" && pwd)/$(basename "$html")"
for t in "${times[@]}"; do
  out="frame-${t}.png"
  npx -y playwright screenshot --wait-for-timeout=600 "file://${abs}?t=${t}" "$out" >/dev/null 2>&1
  echo "  ✓ t=${t}s → $out"
done
echo "  → tile them: scripts/contact-sheet.sh sheet.png frame-*.png"
